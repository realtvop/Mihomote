import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static let windowChromeChannelName = "app.mihomote/window_chrome"

  private var windowChromeChannel: FlutterMethodChannel?
  private var windowObservers: [NSObjectProtocol] = []

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    (NSApp.delegate as? AppDelegate)?.attachMenuBarHost(
      to: flutterViewController.engine
    )

    super.awakeFromNib()

    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    titlebarSeparatorStyle = .none
    styleMask.insert(.fullSizeContentView)

    let channel = FlutterMethodChannel(
      name: Self.windowChromeChannelName,
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "getTitlebarHeight" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.titlebarHeight ?? 0)
    }
    windowChromeChannel = channel

    let notifications: [Notification.Name] = [
      NSWindow.didResizeNotification,
      NSWindow.didEnterFullScreenNotification,
      NSWindow.didExitFullScreenNotification,
    ]
    windowObservers = notifications.map { name in
      NotificationCenter.default.addObserver(
        forName: name,
        object: self,
        queue: .main
      ) { [weak self] _ in
        self?.publishTitlebarHeight()
      }
    }
  }

  deinit {
    for observer in windowObservers {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  private var titlebarHeight: Double {
    max(0, frame.height - contentLayoutRect.height)
  }

  private func publishTitlebarHeight() {
    windowChromeChannel?.invokeMethod(
      "titlebarHeightChanged",
      arguments: titlebarHeight
    )
  }
}
