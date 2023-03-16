import SwiftUI

struct AnimatedGradientView: View {
  var startColor: Color
  var endColor: Color

  @State var startPoint = UnitPoint(x: 0, y: 0)
  @State var endPoint = UnitPoint(x: 0, y: 2)

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          gradient: Gradient(stops: [
            Gradient.Stop(color: startColor, location: 0),
            Gradient.Stop(color: endColor, location: 1),
          ]),
          startPoint: startPoint,
          endPoint: endPoint
        )
      ).onAppear {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
          self.startPoint = UnitPoint(x: 1, y: -1)
          self.endPoint = UnitPoint(x: 0, y: 1)
        }
      }
  }
}
