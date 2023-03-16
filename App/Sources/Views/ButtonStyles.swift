import SwiftUI

// MARK: - PrimaryButtonStyle

struct PrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(.DS.colorWhite)
      .font(.DS.bodyS)
      .fontWeight(.bold)
      .lineSpacing(.grid(6))
      .padding(.horizontal, .grid(8))
      .padding(.vertical, .grid(3))
      .background(
        RoundedRectangle(cornerRadius: .grid(6))
          .fill(Color.DS.colorPrimary)
          .bigShadow()
          .scaleEffect(configuration.isPressed ? 0.95 : 1)
      )
      .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
  }
}

// MARK: - SecondaryButtonStyle

struct SecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(.DS.colorWhite)
      .font(.DS.bodyS)
      .fontWeight(.bold)
      .lineSpacing(.grid(6))
      .padding(.horizontal, .grid(8))
      .padding(.vertical, .grid(3))
      .cornerRadius(.grid(6))
      .overlay {
        RoundedRectangle(cornerRadius: .grid(6))
          .stroke(Color.DS.colorSecondary, lineWidth: 2)
          .bigShadow()
          .scaleEffect(configuration.isPressed ? 0.95 : 1)
      }
      .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
  }
}
