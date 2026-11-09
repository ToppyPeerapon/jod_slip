import Flutter
import UIKit

/// Passes "open the app and do X" requests to Dart over the
/// `jod_slip/launch_action` channel. They arrive as `jodslip://<action>` links,
/// e.g. `jodslip://scan-library` from the home-screen widget.
///
/// Dart calls `ready` once it listens; that returns the action the app was
/// launched with (if any). Later actions are sent with `onAction`.
final class LaunchActionPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  static let scheme = "jodslip"

  private let channel: FlutterMethodChannel
  private var pendingAction: String?
  private var dartReady = false

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "jod_slip/launch_action", binaryMessenger: registrar.messenger())
    let instance = LaunchActionPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "ready":
      dartReady = true
      result(pendingAction)
      pendingAction = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // Cold launch from a link.
  @objc(scene:willConnectToSession:options:)
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let contexts = connectionOptions?.urlContexts else { return false }
    return handle(contexts)
  }

  // Link opened while the app is running or suspended.
  @objc(scene:openURLContexts:)
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    handle(URLContexts)
  }

  private func handle(_ contexts: Set<UIOpenURLContext>) -> Bool {
    guard let action = contexts.lazy.compactMap({ Self.action(from: $0.url) }).first else { return false }
    if dartReady {
      channel.invokeMethod("onAction", arguments: action)
    } else {
      pendingAction = action
    }
    return true
  }

  private static func action(from url: URL) -> String? {
    guard url.scheme == scheme, let host = url.host, !host.isEmpty else { return nil }
    return host
  }
}
