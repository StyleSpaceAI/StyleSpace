import Combine
import SwiftUI

// MARK: - UserGuidanceOverlayView

/// A view that displays a single overlay component at a time.
/// Overlay components are provided via `GuidanceOverlayCoordinator` environment variable.
/// Priority is given to the first active component in the `components` list of coordinator.
struct UserGuidanceOverlayView<ComponentView>: View where ComponentView: View {
  @ViewBuilder var componentBuilder: (GuidanceOverlayCoordinator.Component) -> ComponentView
  @EnvironmentObject var componentCoordinator: GuidanceOverlayCoordinator

  init(@ViewBuilder componentBuilder: @escaping (GuidanceOverlayCoordinator.Component) -> ComponentView) {
    self.componentBuilder = componentBuilder
  }

  var body: some View {
    ZStack {
      if let activeComponent = componentCoordinator.activeComponent {
        componentBuilder(activeComponent)
          .transition(.move(edge: .top).combined(with: .opacity))
      } else {
        EmptyView()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .animation(.spring(), value: componentCoordinator.activeComponent)
    .background(.ultraThinMaterial.opacity(componentCoordinator.activeComponent != nil ? 0.5 : 0))
  }
}
