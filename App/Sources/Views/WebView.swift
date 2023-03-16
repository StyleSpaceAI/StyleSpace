import AppDevUtils
import Combine
import SwiftUI
import WebKit

// MARK: - WebViewData

class WebViewData: ObservableObject, Then {
  @Published var loading: Bool = false
  @Published var scrollPercent: Float = 0
  @Published var url: URL? = nil
  @Published var urlBar: String = "https://nasa.gov"
  @Published var parsedData: [[String: String]] = []

  var scrollOnLoad: Float? = nil
  var parseLens: () -> Void = {}
}

// MARK: - WebView

struct WebView: UIViewRepresentable {
  @ObservedObject var data: WebViewData

  func makeUIView(context: Context) -> WKWebView {
    context.coordinator.webView
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    guard context.coordinator.loadedUrl != data.url else { return }
    context.coordinator.loadedUrl = data.url

    if let url = data.url {
      DispatchQueue.main.async {
        let request = URLRequest(url: url)
        uiView.load(request)
      }
    }

    context.coordinator.data.url = data.url
  }

  func makeCoordinator() -> WebViewCoordinator {
    WebViewCoordinator(data: data)
  }
}

// MARK: - WebViewCoordinator

class WebViewCoordinator: NSObject, WKNavigationDelegate {
  @ObservedObject var data: WebViewData

  var webView: WKWebView = .init()
  var loadedUrl: URL? = nil

  init(data: WebViewData) {
    self.data = data

    super.init()

    setupScripts()
    webView.navigationDelegate = self

    data.parseLens = parseLens
  }

  func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
    DispatchQueue.main.async {
      if let scrollOnLoad = self.data.scrollOnLoad {
        self.scrollTo(scrollOnLoad)
        self.data.scrollOnLoad = nil
      }

      self.data.loading = false

      if let urlstr = webView.url?.absoluteString {
        self.data.urlBar = urlstr
      }
    }
  }

  func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
    DispatchQueue.main.async { self.data.loading = true }
  }

  func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
    showError(title: "Navigation Error", message: error.localizedDescription)
    DispatchQueue.main.async { self.data.loading = false }
  }

  func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
    showError(title: "Loading Error", message: error.localizedDescription)
    DispatchQueue.main.async { self.data.loading = false }
  }

  func scrollTo(_ percent: Float) {
    let js = "scrollToPercent(\(percent))"

    webView.evaluateJavaScript(js)
  }

  func parseLens() {
    let js = "getImageAndTitle()"

    webView.evaluateJavaScript(js) { result, error in
      if let error {
        log.error(error)
      }

      if let result = result as? [[String: String]] {
        DispatchQueue.main.async {
          self.data.parsedData = result.filter { dict in dict["image"]?.prefix(4) == "http" }
        }
      }
    }
  }

  func setupScripts() {
    let monitor = WKUserScript(source: ScrollMonitorScript.monitorScript,
                               injectionTime: .atDocumentEnd,
                               forMainFrameOnly: true)

    let scrollTo = WKUserScript(source: ScrollMonitorScript.scrollTo,
                                injectionTime: .atDocumentEnd,
                                forMainFrameOnly: true)

    let googleLensGet = WKUserScript(source: GoogleLensScript.getImgTitles,
                                     injectionTime: .atDocumentEnd,
                                     forMainFrameOnly: true)

    webView.configuration.userContentController.addUserScript(monitor)
    webView.configuration.userContentController.addUserScript(scrollTo)
    webView.configuration.userContentController.addUserScript(googleLensGet)

    let msgHandler = ScrollMonitorScript { percent in
      DispatchQueue.main.async {
        self.data.scrollPercent = percent
      }
    }

    webView.configuration.userContentController.add(msgHandler, contentWorld: .page, name: "notifyScroll")
  }

  func showError(title: String, message: String) {
    #if os(macOS)
      let alert = NSAlert()

      alert.messageText = title
      alert.informativeText = message
      alert.alertStyle = .warning

      alert.runModal()
    #else
      print("\(title): \(message)")
    #endif
  }
}

// MARK: - ScrollMonitorScript

class ScrollMonitorScript: NSObject, WKScriptMessageHandler {
  let callback: (Float) -> Void

  static var monitorScript: String {
    """
        let last_known_scroll_position = 0;
        let ticking = false;

        function getScrollPercent() {
            var docu = document.documentElement;

            let t = docu.scrollTop;
            let h = docu.scrollHeight;
            let ch = docu.clientHeight

            return (t / (h - ch)) * 100;
        }

        window.addEventListener('scroll', function(e) {
            window.webkit.messageHandlers.notifyScroll.postMessage(getScrollPercent());
        });
    """
  }

  static var scrollTo: String {
    """
       function scrollToPercent(pct) {
           var docu = document.documentElement;

           let h = docu.scrollHeight;
           let ch = docu.clientHeight

           let t = (pct * (h - ch)) / 100;

           window.scrollTo(0, t);
       }
    """
  }

  init(callback: @escaping (Float) -> Void) {
    self.callback = callback
  }

  func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
    if let percent = message.body as? NSNumber {
      callback(percent.floatValue)
    }
  }
}

// MARK: - GoogleLensScript

class GoogleLensScript: NSObject, WKScriptMessageHandler {
  let callback: ([[String: String]]) -> Void

  static var getImgTitles: String {
    """
    function getImageAndTitle() {
      const doc = document;
      const divs = doc.querySelectorAll("div[data-thumbnail-url]");

      const results = [];

      divs.forEach((div) => {
        const img = div.querySelector("img");
        const title = div.getAttribute("data-item-title");

        if (img && title) {
          results.push({ image: img.getAttribute("src"), title });
        }
      });

      return results;
    }
    """
  }

  init(callback: @escaping ([[String: String]]) -> Void) {
    self.callback = callback
  }

  func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
    if let result = message.body as? [[String: String]] {
      callback(result)
    } else {
      print("Error: \(message.body)")
    }
  }
}
