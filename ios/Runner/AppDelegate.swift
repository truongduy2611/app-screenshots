import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var fileOpenChannel: FlutterMethodChannel?
  /// Buffer file paths received before the Flutter engine is ready.
  private var pendingFilePaths: [String] = []
  /// Whether Flutter has signalled it is ready to receive file open events.
  private var flutterReady = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    // ── iCloud Backup method channel ──
    ICloudBackupHandler.shared.setup(binaryMessenger: controller.binaryMessenger)

    // ── AI method channel (Apple Foundation Models) ──
    AIChannel.register(with: controller)

    // ── App Icon method channel ──
    let iconChannel = FlutterMethodChannel(
      name: "app_icon",
      binaryMessenger: controller.binaryMessenger
    )
    iconChannel.setMethodCallHandler { (call, result) in
      guard call.method == "setIcon" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let iconName = call.arguments as? String ?? "default"
      let alternateIconName: String? = iconName == "alternative" ? "AlternativeIcon" : nil

      guard UIApplication.shared.supportsAlternateIcons else {
        result(FlutterError(code: "UNSUPPORTED", message: "Alternate icons not supported", details: nil))
        return
      }

      UIApplication.shared.setAlternateIconName(alternateIconName) { error in
        if let error = error {
          result(FlutterError(code: "ICON_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }

    // ── File open method channel ──
    fileOpenChannel = FlutterMethodChannel(
      name: "file_open",
      binaryMessenger: controller.binaryMessenger
    )

    // Listen for Flutter to signal readiness
    fileOpenChannel!.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "ready" {
        NSLog("[AppDelegate-iOS] Flutter signalled ready")
        self?.flutterReady = true
        self?.flushPendingFiles()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    NSLog("[AppDelegate-iOS] didFinishLaunchingWithOptions")

    // Check if app was launched by opening a file
    if let url = launchOptions?[.url] as? URL {
      NSLog("[AppDelegate-iOS] Launch URL detected: \(url.path)")
      if url.pathExtension == "appshots" {
        if let localPath = ICloudBackupHandler.shared.prepareOpenedDocument(url: url) {
          pendingFilePaths.append(localPath)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Called when a file is opened while the app is already running (warm start)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    NSLog("[AppDelegate-iOS] application:open:url called: \(url.path)")

    if url.pathExtension == "appshots" {
      guard let localPath = ICloudBackupHandler.shared.prepareOpenedDocument(url: url) else {
        NSLog("[AppDelegate-iOS] Failed to copy file to sandbox")
        return false
      }

      if flutterReady {
        NSLog("[AppDelegate-iOS] Sending fileOpened to Flutter: \(localPath)")
        fileOpenChannel?.invokeMethod("fileOpened", arguments: localPath)
      } else {
        NSLog("[AppDelegate-iOS] Flutter not ready, queuing: \(localPath)")
        pendingFilePaths.append(localPath)
      }
      return true
    }
    return super.application(app, open: url, options: options)
  }

  private func flushPendingFiles() {
    for path in pendingFilePaths {
      NSLog("[AppDelegate-iOS] Flushing pending file: \(path)")
      fileOpenChannel?.invokeMethod("fileOpened", arguments: path)
    }
    pendingFilePaths.removeAll()
  }
}
