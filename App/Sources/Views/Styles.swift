import AppDevUtils
import SwiftUI

// MARK: - Color.DS

public extension Color {
  enum DS {
    public static let colorPrimary = Color(red: 0.1411764770746231, green: 0.41960784792900085, blue: 0.9921568632125854, opacity: 1)
    public static let colorSecondary = Color(red: 0.7624120712280273, green: 0.373189777135849, blue: 1, opacity: 1)
    public static let background01 = Color(hex: 0x1B1521)
    public static let background02 = Color(hex: 0x332440)
    public static let colorWhite = Color(red: 1, green: 1, blue: 1, opacity: 1)

    public static let backgroundBlur = Color(
      red: 0.09542995691299438,
      green: 0.10203252732753754,
      blue: 0.12514153122901917,
      opacity: 0.8500000238418579
    )
    public static let gradient02 = LinearGradient(
      gradient: Gradient(stops: [
        Gradient.Stop(color: Color(red: 0.7627579569816589, green: 0.5769626498222351, blue: 1, opacity: 1), location: 0),
        Gradient.Stop(color: Color(red: 0.8950124382972717, green: 0.1650690883398056, blue: 0.4233647286891937, opacity: 1), location: 1),
      ]),
      startPoint: UnitPoint(x: 0.6543412724314833, y: 0.17282936378425823),
      endPoint: UnitPoint(x: 1.1102230246251565e-16, y: 0.17282936378425834)
    )
    public static let gradient03 = LinearGradient(
      gradient: Gradient(stops: [
        Gradient.Stop(color: Color(red: 1, green: 0.9210526347160339, blue: 0.6363636255264282, opacity: 1), location: 0),
        Gradient.Stop(color: Color(red: 1, green: 0.5250475406646729, blue: 0.4117647111415863, opacity: 1), location: 1),
      ]),
      startPoint: UnitPoint(x: 1, y: -1.1102230246251565e-16),
      endPoint: UnitPoint(x: 0, y: 0)
    )
    public static let gradient04 = LinearGradient(
      gradient: Gradient(stops: [
        Gradient.Stop(color: Color(red: 0.6027407646179199, green: 0.85988450050354, blue: 0.4967111051082611, opacity: 1), location: 0),
        Gradient.Stop(color: Color(red: 0.43040257692337036, green: 0.6644588112831116, blue: 0.35936230421066284, opacity: 1), location: 1),
      ]),
      startPoint: UnitPoint(x: 0, y: 0),
      endPoint: UnitPoint(x: 0, y: 1)
    )
    public static let gradient06 = LinearGradient(
      gradient: Gradient(stops: [
        Gradient.Stop(color: Color(red: 1, green: 0.6869664788246155, blue: 0.6869664788246155, opacity: 1), location: 0),
        Gradient.Stop(color: Color(red: 1, green: 0.6904649138450623, blue: 0.48410823941230774, opacity: 1), location: 0.16719461977481842),
        Gradient.Stop(color: Color(red: 1, green: 0.7034937143325806, blue: 0.4799647629261017, opacity: 1), location: 0.18092040717601776),
        Gradient.Stop(color: Color(red: 1, green: 0.9249703884124756, blue: 0.7192073464393616, opacity: 1), location: 0.33389872312545776),
        Gradient.Stop(color: Color(red: 0.8386088609695435, green: 1, blue: 0.6678162813186646, opacity: 1), location: 0.5005138516426086),
        Gradient.Stop(color: Color(red: 0, green: 0.5686274766921997, blue: 1, opacity: 1), location: 0.6656686067581177),
        Gradient.Stop(color: Color(red: 0.3843137323856354, green: 0.21176470816135406, blue: 1, opacity: 1), location: 0.833200216293335),
        Gradient.Stop(color: Color(red: 0.7137255072593689, green: 0.125490203499794, blue: 0.8784313797950745, opacity: 1), location: 1),
      ]),
      startPoint: UnitPoint(x: -1.2677585689499817, y: -0.25643587230018916),
      endPoint: UnitPoint(x: -0.8194064991496444, y: 2.1481779347868857)
    )
    public static let gradient07 = LinearGradient(
      gradient: Gradient(stops: [
        Gradient.Stop(color: Color(red: 0.734649121761322, green: 1, blue: 0.9050179123878479, opacity: 1), location: 0),
        Gradient.Stop(color: Color(red: 0.5254902243614197, green: 1, blue: 0.7921568751335144, opacity: 1), location: 1),
      ]),
      startPoint: UnitPoint(x: 0, y: 0),
      endPoint: UnitPoint(x: 0, y: 1)
    )
    public static let gradient08 = LinearGradient(
      gradient: Gradient(stops: [
        Gradient.Stop(color: Color(red: 1, green: 0.6963470578193665, blue: 0.5555555820465088, opacity: 1), location: 0),
        Gradient.Stop(color: Color(red: 1, green: 0.47843137383461, blue: 0.3333333432674408, opacity: 1), location: 1),
      ]),
      startPoint: UnitPoint(x: 0, y: 0),
      endPoint: UnitPoint(x: 0, y: 1)
    )
    public static let gradient09 = LinearGradient(
      gradient: Gradient(stops: [
        Gradient.Stop(color: Color(red: 0.20870047807693481, green: 0.2212233543395996, blue: 0.26340875029563904, opacity: 1), location: 0),
        Gradient.Stop(color: Color(red: 0.09542995691299438, green: 0.10203252732753754, blue: 0.12514153122901917, opacity: 1), location: 1),
      ]),
      startPoint: UnitPoint(x: 0, y: 1),
      endPoint: UnitPoint(x: 1, y: 1)
    )
    public static let gradient09flip = LinearGradient(
      gradient: Gradient(stops: [
        Gradient.Stop(color: Color(red: 0.20870047807693481, green: 0.2212233543395996, blue: 0.26340875029563904, opacity: 1), location: 0),
        Gradient.Stop(color: Color(red: 0.09542995691299438, green: 0.10203252732753754, blue: 0.12514153122901917, opacity: 1), location: 1),
      ]),
      startPoint: UnitPoint(x: 0, y: 0),
      endPoint: UnitPoint(x: 1, y: 1)
    )
    static let gradient09flipAnimated = AnimatedGradientView(
      startColor: Color(red: 0.20870047807693481, green: 0.2212233543395996, blue: 0.26340875029563904, opacity: 1),
      endColor: Color(red: 0.09542995691299438, green: 0.10203252732753754, blue: 0.12514153122901917, opacity: 1)
    )
    static let gradient10Animated = AnimatedGradientView(
      startColor: Color.DS.background01,
      endColor: Color.DS.background02.darken(by: 0.05)
    )
    public static let colorful01 = Color(red: 0.627205491065979, green: 0.41739439964294434, blue: 0.9748924374580383, opacity: 1)
    public static let colorful02 = Color(red: 0.9834553003311157, green: 0.640339195728302, blue: 1, opacity: 1)
    public static let colorful03 = Color(red: 0.5576791167259216, green: 0.588876485824585, blue: 1, opacity: 1)
    public static let colorful04 = Color(red: 0.5809353590011597, green: 0.9402173757553101, blue: 0.9402173757553101, opacity: 1)
    public static let colorful05 = Color(red: 0.647570788860321, green: 0.9622678756713867, blue: 0.6117405295372009, opacity: 1)
    public static let colorful06 = Color(red: 1, green: 0.8673199415206909, blue: 0.44603657722473145, opacity: 1)
    public static let colorful07 = Color(red: 1, green: 0.5872589349746704, blue: 0.5552591681480408, opacity: 1)
    public static let stateActive = Color(red: 1, green: 1, blue: 1, opacity: 1)
    public static let stateDeactive = Color(red: 0.3668689429759979, green: 0.38438892364501953, blue: 0.4457087814807892, opacity: 1)
    public static let stateLightModeActive = Color(red: 0.125490203499794, green: 0.027450980618596077, blue: 0.2705882489681244, opacity: 1)
    public static let stateDeactiveDarker = Color(red: 0.2269030064344406, green: 0.23782995343208313, blue: 0.27607423067092896, opacity: 1)
  }
}

extension View {
  func screenAnimatedBackground() -> some View {
    background {
      Color.DS.gradient10Animated.ignoresSafeArea()
    }
  }
}

// MARK: - Effect

public enum Effect {
  public enum DS {
    public struct normalShadow: ViewModifier {
      public func body(content: Content) -> some View {
        content
          .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 12, x: 0, y: 8)
      }

      public init() {}
    }

    public struct bigShadow: ViewModifier {
      public func body(content: Content) -> some View {
        content
          .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.50), radius: 16, y: 8)
      }

      public init() {}
    }
  }
}

public extension View {
  func normalShadow() -> some View { modifier(Effect.DS.normalShadow()) }

  func bigShadow() -> some View { modifier(Effect.DS.bigShadow()) }
}
