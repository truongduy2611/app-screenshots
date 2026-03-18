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
        if let localPath = copyToAppSandbox(url: url) {
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
      guard let localPath = copyToAppSandbox(url: url) else {
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

  /// Copies a file from a security-scoped URL (e.g. File Provider Storage)
  /// into the app's temporary directory so Flutter can access it.
  private func copyToAppSandbox(url: URL) -> String? {
    // Start security-scoped access (required for File Provider / shared container files)
    let accessing = url.startAccessingSecurityScopedResource()
    NSLog("[AppDelegate-iOS] startAccessingSecurityScopedResource: \(accessing)")

    defer {
      if accessing {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let tempDir = FileManager.default.temporaryDirectory
    let destURL = tempDir.appendingPathComponent(url.lastPathComponent)

    do {
      // Remove existing copy if present
      if FileManager.default.fileExists(atPath: destURL.path) {
        try FileManager.default.removeItem(at: destURL)
      }
      try FileManager.default.copyItem(at: url, to: destURL)
      NSLog("[AppDelegate-iOS] Copied file to sandbox: \(destURL.path)")
      return destURL.path
    } catch {
      NSLog("[AppDelegate-iOS] Failed to copy file: \(error.localizedDescription)")
      return nil
    }
  }

  private func flushPendingFiles() {
    for path in pendingFilePaths {
      NSLog("[AppDelegate-iOS] Flushing pending file: \(path)")
      fileOpenChannel?.invokeMethod("fileOpened", arguments: path)
    }
    pendingFilePaths.removeAll()
  }
}
