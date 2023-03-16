import AppDevUtils
import Nuke
import SwiftUI
import UIKit

struct ShareButton: View {
  var imageURL: URL

  @State private var isLoading = false

  var body: some View {
    ZStack {
      if isLoading {
        ProgressView()
      } else {
        Button {
          shareImage()
        } label: {
          Text("Share")
        }.buttonStyle(PrimaryButtonStyle())
      }
    }
  }

  func shareImage() {
    isLoading = true
    Task {
      do {
        let image = try await ImagePipeline.shared.image(for: imageURL)
        DispatchQueue.main.async {
          let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)

          UIApplication.shared.topViewController?.present(activityController, animated: true, completion: nil)
          UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
      } catch {
        log.error(error)
      }

      isLoading = false
    }
  }
}
