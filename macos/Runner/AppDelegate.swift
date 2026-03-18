import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var fileOpenChannel: FlutterMethodChannel?
  /// Buffer file paths received before Flutter is ready.
  private var pendingFilePaths: [String] = []
  /// Whether Flutter has signalled it is ready to receive file open events.
  private var flutterReady = false

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    NSLog("[AppDelegate] applicationDidFinishLaunching called")

    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      // ── iCloud Backup method channel ──
      ICloudBackupHandler.shared.setup(binaryMessenger: controller.engine.binaryMessenger)

      // ── AI method channel (Apple Foundation Models) ──
      AIChannel.register(with: controller)

      // ── File open method channel ──
      fileOpenChannel = FlutterMethodChannel(
        name: "file_open",
        binaryMessenger: controller.engine.binaryMessenger
      )
      NSLog("[AppDelegate] file_open channel created")

      // Listen for Flutter to signal readiness
      fileOpenChannel!.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "ready" {
          NSLog("[AppDelegate] Flutter signalled ready")
          self?.flutterReady = true
          self?.flushPendingFiles()
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    } else {
      NSLog("[AppDelegate] ERROR: Could not get FlutterViewController")
    }
  }

  // Called when user double-clicks / opens a .appshots file
  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    NSLog("[AppDelegate] openFile called with: \(filename)")

    if filename.hasSuffix(".appshots") {
      if flutterReady, let channel = fileOpenChannel {
        NSLog("[AppDelegate] Sending fileOpened to Flutter: \(filename)")
        channel.invokeMethod("fileOpened", arguments: filename)
      } else {
        NSLog("[AppDelegate] Not ready, queuing: \(filename)")
        pendingFilePaths.append(filename)
      }
      return true
    }
    return super.application(sender, openFile: filename)
  }

  // Called when user opens files via URL scheme or drag-and-drop
  override func application(_ application: NSApplication, open urls: [URL]) {
    NSLog("[AppDelegate] open urls called with: \(urls)")
    for url in urls {
      if url.isFileURL && url.pathExtension == "appshots" {
        let path = url.path
        if flutterReady, let channel = fileOpenChannel {
          NSLog("[AppDelegate] Sending fileOpened (URL) to Flutter: \(path)")
          channel.invokeMethod("fileOpened", arguments: path)
        } else {
          NSLog("[AppDelegate] Not ready (URL), queuing: \(path)")
          pendingFilePaths.append(path)
        }
      }
    }
  }

  private func flushPendingFiles() {
    for path in pendingFilePaths {
      NSLog("[AppDelegate] Flushing pending file: \(path)")
      fileOpenChannel?.invokeMethod("fileOpened", arguments: path)
    }
    pendingFilePaths.removeAll()
  }
}
