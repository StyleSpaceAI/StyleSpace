import ProjectDescription

let dependencies = Dependencies(
  swiftPackageManager: [
    .package(url: "https://github.com/Saik0s/AppDevUtils.git", .branch("main")),
    .package(url: "https://github.com/erikdrobne/CameraButton", .upToNextMajor(from: "2.0.0")),
    .package(url: "https://github.com/krzysztofzablocki/Inject.git", .upToNextMajor(from: "1.2.3")),
    .package(url: "https://github.com/kean/Nuke.git", .upToNextMajor(from: "12.0.0")),
    .package(url: "https://github.com/jasudev/LottieUI.git", .branch("main")),
    .package(url: "https://github.com/aheze/Setting.git", .branch("main")),
    .package(url: "https://github.com/siteline/SwiftUI-Introspect", .upToNextMajor(from: "0.2.3")),
  ],
  platforms: [.iOS]
)
