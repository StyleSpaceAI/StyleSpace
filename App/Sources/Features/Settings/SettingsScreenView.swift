import Setting
import SwiftUI

struct SettingsScreenView: View {
  var body: some View {
    SettingStack(embedInNavigationStack: false) {
      SettingPage(title: "Settings",
                  backgroundColor: Color.DS.background02) {
        SettingGroup {}
      }
    }
  }
}
