import Foundation
import ProjectDescription

let version = "1.6.3"

let projectSettings: SettingsDictionary = [
  "GCC_TREAT_WARNINGS_AS_ERRORS": "YES",
  "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
  "CODE_SIGN_STYLE": "Automatic",
  "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
  "MARKETING_VERSION": SettingValue(stringLiteral: version),
]

let debugSettings: SettingsDictionary = [
  "OTHER_SWIFT_FLAGS": "-D DEBUG $(inherited) -Xfrontend -warn-long-function-bodies=500 -Xfrontend -warn-long-expression-type-checking=500 -Xfrontend -debug-time-function-bodies -Xfrontend -enable-actor-data-race-checks",
  "OTHER_LDFLAGS": "-Xlinker -interposable $(inherited)",
]

let project = Project(
  name: "StyleSpace",
  options: .options(
    disableShowEnvironmentVarsInScriptPhases: true,
    textSettings: .textSettings(
      indentWidth: 2,
      tabWidth: 2
    )
  ),
  settings: .settings(
    base: projectSettings,
    debug: debugSettings,
    release: [:],
    defaultSettings: .recommended
  ),
  targets: [
    Target(
      name: "StyleSpace",
      platform: .iOS,
      product: .app,
      bundleId: "app.StyleSpace.ios.dev",
      deploymentTarget: .iOS(targetVersion: "16.0", devices: [.iphone]),
      infoPlist: .extendingDefault(with: [
        "CFBundleURLTypes": [
          [
            "CFBundleTypeRole": "Editor",
            "CFBundleURLName": "StyleSpace",
            "CFBundleURLSchemes": [
              "stylespace",
            ],
          ],
        ],
        "CFBundleDisplayName": "StyleSpace",
        "UIApplicationSceneManifest": [
          "UIApplicationSupportsMultipleScenes": false,
          "UISceneConfigurations": [
          ],
        ],
        "ITSAppUsesNonExemptEncryption": false,
        "UILaunchScreen": [
          "UIColorName": "LaunchScreenBackground",
        ],
        "NSCameraUsageDescription": "This app requires camera permissions so you can take photos of your interior space to get personalized restyling suggestions.",
        "NSAppTransportSecurity": [
          "NSAllowsArbitraryLoads": true,
        ],
        "UISupportedInterfaceOrientations": [
          "UIInterfaceOrientationPortrait",
        ],
        "UIUserInterfaceStyle": "Dark",
        "CFBundleShortVersionString": InfoPlist.Value.string(version),
      ]),
      sources: .paths([.relativeToManifest("App/Sources/**")]),
      resources: [
        "App/Resources/**",
      ],
      dependencies: [
        .external(name: "CameraButton"),
        .external(name: "AppDevUtils"),
        .external(name: "Inject"),
        .external(name: "Nuke"),
        .external(name: "NukeUI"),
        .external(name: "LottieUI"),
        .external(name: "Setting"),
        .external(name: "Introspect"),
      ]
    ),
  ],
  resourceSynthesizers: .default + [
    .files(extensions: ["json"]),
  ]
)
