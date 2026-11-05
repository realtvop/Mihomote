import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var menuBarController: MenuBarController?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    menuBarController = MenuBarController()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Closing the main window keeps the status item and its proxy popover
    // available. The native menu has an explicit Quit action.
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

private final class MenuBarController: NSObject, NSPopoverDelegate {
  private static let channelName = "app.mihomote/menu_bar"
  private static let showTrafficKey = "menuBar.showTraffic"

  private let statusItem = NSStatusBar.system.statusItem(
    withLength: NSStatusItem.variableLength
  )
  private let menu = NSMenu()
  private let showTrafficItem = NSMenuItem()
  private let openMainWindowItem = NSMenuItem()
  private let quitItem = NSMenuItem()
  private let popover = NSPopover()
  private let engine = FlutterEngine(
    name: "mihomote-menu-bar",
    project: nil,
    allowHeadlessExecution: true
  )

  private var channel: FlutterMethodChannel?
  private var preferencesObserver: NSObjectProtocol?
  private var preferencesWorkItem: DispatchWorkItem?
  private var latestUp = 0
  private var latestDown = 0
  private var showTraffic: Bool {
    get { UserDefaults.standard.bool(forKey: Self.showTrafficKey) }
    set { UserDefaults.standard.set(newValue, forKey: Self.showTrafficKey) }
  }

  override init() {
    super.init()
    configureStatusItem()
    configureMenu()
    configurePopover()
    observeSharedPreferences()
  }

  deinit {
    preferencesWorkItem?.cancel()
    if let preferencesObserver {
      NotificationCenter.default.removeObserver(preferencesObserver)
    }
    engine.shutDownEngine()
  }

  private func configureStatusItem() {
    guard let button = statusItem.button else { return }
    button.image = NSImage(
      systemSymbolName: "network",
      accessibilityDescription: "Mihomote"
    )
    button.image?.isTemplate = true
    button.imagePosition = .imageLeading
    button.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    button.toolTip = "Mihomote"
    button.target = self
    button.action = #selector(statusItemPressed(_:))
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    updateStatusTitle()
  }

  private func configureMenu() {
    showTrafficItem.title = "Show traffic in menu bar"
    showTrafficItem.target = self
    showTrafficItem.action = #selector(toggleTraffic)
    showTrafficItem.state = showTraffic ? .on : .off

    openMainWindowItem.title = "Open Mihomote"
    openMainWindowItem.target = self
    openMainWindowItem.action = #selector(openMainWindow)

    quitItem.title = "Quit Mihomote"
    quitItem.target = self
    quitItem.action = #selector(quit)

    menu.addItem(showTrafficItem)
    menu.addItem(.separator())
    menu.addItem(openMainWindowItem)
    menu.addItem(quitItem)
  }

  private func configurePopover() {
    guard engine.run(withEntrypoint: "menuBarMain") else {
      assertionFailure("Failed to start the menu-bar Flutter engine")
      return
    }
    RegisterGeneratedPlugins(registry: engine)

    let viewController = FlutterViewController(
      engine: engine,
      nibName: nil,
      bundle: nil
    )
    popover.contentViewController = viewController
    popover.contentSize = NSSize(width: 480, height: 680)
    popover.behavior = .transient
    popover.animates = true
    popover.delegate = self

    let channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "configure":
        if let labels = call.arguments as? [String: Any] {
          self.showTrafficItem.title =
            labels["showTraffic"] as? String ?? self.showTrafficItem.title
          self.openMainWindowItem.title =
            labels["openMainWindow"] as? String ?? self.openMainWindowItem.title
          self.quitItem.title = labels["quit"] as? String ?? self.quitItem.title
        }
        result(nil)
      case "updateTraffic":
        if let traffic = call.arguments as? [String: Any] {
          self.latestUp = (traffic["up"] as? NSNumber)?.intValue ?? 0
          self.latestDown = (traffic["down"] as? NSNumber)?.intValue ?? 0
          self.updateStatusTitle()
        }
        result(nil)
      case "openMainWindow":
        self.openMainWindow()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  private func observeSharedPreferences() {
    preferencesObserver = NotificationCenter.default.addObserver(
      forName: UserDefaults.didChangeNotification,
      object: UserDefaults.standard,
      queue: .main
    ) { [weak self] _ in
      guard let self else { return }
      self.preferencesWorkItem?.cancel()
      let workItem = DispatchWorkItem { [weak self] in
        self?.channel?.invokeMethod("preferencesChanged", arguments: nil)
      }
      self.preferencesWorkItem = workItem
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
  }

  @objc private func statusItemPressed(_ sender: NSStatusBarButton) {
    guard let event = NSApp.currentEvent else { return }
    if event.type == .rightMouseUp {
      popover.performClose(nil)
      menu.popUp(
        positioning: nil,
        at: NSPoint(x: 0, y: sender.bounds.height + 2),
        in: sender
      )
      return
    }

    if popover.isShown {
      popover.performClose(nil)
    } else {
      popover.show(
        relativeTo: sender.bounds,
        of: sender,
        preferredEdge: .minY
      )
      popover.contentViewController?.view.window?.makeKey()
    }
  }

  @objc private func toggleTraffic() {
    showTraffic.toggle()
    showTrafficItem.state = showTraffic ? .on : .off
    updateStatusTitle()
  }

  @objc private func openMainWindow() {
    popover.performClose(nil)
    guard let window = NSApp.windows.first(where: { $0 is MainFlutterWindow }) else {
      return
    }
    if window.isMiniaturized { window.deminiaturize(nil) }
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }

  private func updateStatusTitle() {
    guard let button = statusItem.button else { return }
    button.title = showTraffic
      ? " ↑\(Self.formatSpeed(latestUp)) ↓\(Self.formatSpeed(latestDown))"
      : ""
  }

  private static func formatSpeed(_ bytesPerSecond: Int) -> String {
    let units = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"]
    var value = Double(max(0, bytesPerSecond))
    var unit = 0
    while value >= 1000, unit < units.count - 1 {
      value /= 1024
      unit += 1
    }
    let digits = unit == 0 ? 0 : (value >= 100 ? 0 : (value >= 10 ? 1 : 2))
    return String(format: "%.*f %@", digits, value, units[unit])
  }
}
