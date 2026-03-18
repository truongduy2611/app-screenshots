import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // ── App Icon method channel ──
    let channel = FlutterMethodChannel(
      name: "app_icon",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { (call, result) in
      guard call.method == "setIcon" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let iconName = call.arguments as? String ?? "default"
      if iconName == "alternative",
        let path = Bundle.main.path(forResource: "alternative_icon", ofType: "png"),
        let image = NSImage(contentsOfFile: path)
      {
        NSApp.applicationIconImage = image
      } else {
        NSApp.applicationIconImage = nil  // revert to default
      }
      result(nil)
    }

    super.awakeFromNib()
  }
}
