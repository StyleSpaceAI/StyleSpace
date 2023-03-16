import Combine
import Foundation
import SwiftUI

struct LevelComponentView: View {
  var body: some View {
    ZStack {
      Text("Keep the camera straight")
        .foregroundColor(Color.DS.background01)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background {
          Color.DS.gradient08
            .cornerRadius(20)
            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.50), radius: 16, y: 8)
        }
        .font(.headline)
        .padding(.top, 40)
    }
  }
}
