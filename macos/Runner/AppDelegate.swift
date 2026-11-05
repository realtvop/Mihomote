import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var menuBarController: MenuBarController?
  private var menuBarHostEngine: FlutterEngine?

  override func awakeFromNib() {
    super.awakeFromNib()
    // This delegate is instantiated by MainMenu.xib. In that setup AppKit can
    // connect the delegate after the did-finish-launching notification, while
    // awakeFromNib is guaranteed to run for the actual delegate instance.
    menuBarController = MenuBarController()
    if let menuBarHostEngine {
      menuBarController?.attachHost(to: menuBarHostEngine)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Closing the main window keeps the status item and its proxy popover
    // available. The native menu has an explicit Quit action.
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  func attachMenuBarHost(to engine: FlutterEngine) {
    menuBarHostEngine = engine
    menuBarController?.attachHost(to: engine)
  }
}

private final class MenuBarController: NSObject, NSPopoverDelegate {
  private static let channelName = "app.mihomote/menu_bar"
  private static let hostChannelName = "app.mihomote/menu_bar_host"
  private static let showTrafficKey = "menuBar.showTraffic"
  private static let trafficStatusItemLength: CGFloat = 72

  private let statusItem = NSStatusBar.system.statusItem(
    withLength: NSStatusItem.variableLength
  )
  private let menu = NSMenu()
  private let showTrafficItem = NSMenuItem()
  private let openMainWindowItem = NSMenuItem()
  private let quitItem = NSMenuItem()
  private let popover = NSPopover()
  private let trafficContentView = StatusItemTrafficContentView()
  private let engine = FlutterEngine(
    name: "mihomote-menu-bar",
    project: nil,
    allowHeadlessExecution: true
  )

  private var channel: FlutterMethodChannel?
  private var hostChannel: FlutterMethodChannel?
  private var hostSnapshots: [String: [String: Any]] = [:]
  private var preferencesObserver: NSObjectProtocol?
  private var preferencesWorkItem: DispatchWorkItem?
  private var latestUp = 0
  private var latestDown = 0
  private var hasStatusImage = false
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
    hostChannel?.setMethodCallHandler(nil)
    engine.shutDownEngine()
  }

  func attachHost(to engine: FlutterEngine) {
    let channel = FlutterMethodChannel(
      name: Self.hostChannelName,
      binaryMessenger: engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      guard call.method == "publish",
            let snapshot = call.arguments as? [String: Any],
            let topic = snapshot["topic"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.hostSnapshots[topic] = snapshot
      if topic == "traffic" {
        let traffic = snapshot["value"] as? [String: Any]
        self.latestUp = (traffic?["up"] as? NSNumber)?.intValue ?? 0
        self.latestDown = (traffic?["down"] as? NSNumber)?.intValue ?? 0
        self.updateStatusTitle()
      }
      self.channel?.invokeMethod("hostSnapshot", arguments: snapshot)
      result(nil)
    }
    hostChannel = channel
  }

  private func configureStatusItem() {
    guard let button = statusItem.button else { return }
    let image = NSImage(
      systemSymbolName: "network",
      accessibilityDescription: "Mihomote"
    )
    image?.isTemplate = true
    button.image = image
    hasStatusImage = image != nil
    button.imagePosition = .imageOnly
    trafficContentView.frame = button.bounds
    trafficContentView.autoresizingMask = [.width, .height]
    button.addSubview(trafficContentView)
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
      case "openMainWindow":
        self.openMainWindow()
        result(nil)
      case "menuReady":
        for snapshot in self.hostSnapshots.values {
          self.channel?.invokeMethod("hostSnapshot", arguments: snapshot)
        }
        result(nil)
      case "hostCall":
        guard let hostChannel = self.hostChannel else {
          result(
            FlutterError(
              code: "unknown",
              message: "Main window data host is unavailable",
              details: nil
            )
          )
          return
        }
        hostChannel.invokeMethod("call", arguments: call.arguments) {
          response in result(response)
        }
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
      sender.highlight(true)
      menu.popUp(
        positioning: nil,
        at: NSPoint(x: 0, y: sender.bounds.height + 2),
        in: sender
      )
      sender.highlight(false)
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
      DispatchQueue.main.async { [weak self] in
        guard let self, self.popover.isShown else { return }
        self.statusItem.button?.highlight(true)
      }
    }
  }

  func popoverDidShow(_ notification: Notification) {
    statusItem.button?.highlight(true)
  }

  func popoverDidClose(_ notification: Notification) {
    statusItem.button?.highlight(false)
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
    if showTraffic {
      // Keep the popover anchor stable while live values change. Two compact
      // lines are centered by a dedicated view because NSButtonCell lays out
      // newline titles against a single-line baseline near the top edge.
      statusItem.length = Self.trafficStatusItemLength
      button.imagePosition = .noImage
      button.title = ""
      trafficContentView.isHidden = false
      trafficContentView.setSpeeds(
        up: Self.formatSpeed(latestUp),
        down: Self.formatSpeed(latestDown)
      )
    } else if hasStatusImage {
      // A variable-length item with only an image can collapse to zero width
      // on some macOS/menu-bar layouts. The standard square slot guarantees
      // that the template icon remains visible.
      statusItem.length = NSStatusItem.squareLength
      trafficContentView.isHidden = true
      button.image = NSImage(
        systemSymbolName: "network",
        accessibilityDescription: "Mihomote"
      )
      button.image?.isTemplate = true
      button.imagePosition = .imageOnly
      button.title = ""
    } else {
      // SF Symbols should always contain `network` on the supported macOS
      // versions, but keep the status item discoverable if loading fails.
      statusItem.length = NSStatusItem.variableLength
      trafficContentView.isHidden = true
      button.image = nil
      button.imagePosition = .noImage
      button.title = "M"
    }
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

/// Draws the traffic readout independently from `NSButtonCell` so its two
/// lines stay vertically centered inside the status-bar button and left-aligned
/// to keep the icon stationary. Frame-based layout ensures the host button's
/// height never collapses under Auto Layout. Returning nil from hit testing
/// forwards all clicks to the native button.
private final class StatusItemTrafficContentView: NSView {
  private let speedLabel = NSTextField(labelWithString: "")
  private let imageView = NSImageView()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    autoresizingMask = [.width, .height]

    let image = NSImage(
      systemSymbolName: "network",
      accessibilityDescription: nil
    )
    image?.isTemplate = true
    imageView.image = image
    imageView.contentTintColor = .labelColor
    addSubview(imageView)

    speedLabel.font = NSFont.monospacedDigitSystemFont(
      ofSize: 8,
      weight: .medium
    )
    speedLabel.textColor = .labelColor
    speedLabel.alignment = .left
    speedLabel.maximumNumberOfLines = 2
    speedLabel.lineBreakMode = .byClipping
    speedLabel.isBezeled = false
    speedLabel.drawsBackground = false
    speedLabel.isEditable = false
    speedLabel.isSelectable = false
    addSubview(speedLabel)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()
    let h = bounds.height
    let iconSize: CGFloat = 14
    let leftMargin: CGFloat = 3
    let spacing: CGFloat = 2

    imageView.frame = NSRect(
      x: leftMargin,
      y: floor((h - iconSize) / 2),
      width: iconSize,
      height: iconSize
    )

    let labelX = leftMargin + iconSize + spacing
    let labelHeight: CGFloat = 20
    speedLabel.frame = NSRect(
      x: labelX,
      y: floor((h - labelHeight) / 2),
      width: max(0, bounds.width - labelX - 1),
      height: labelHeight
    )
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    nil
  }

  func setSpeeds(up: String, down: String) {
    speedLabel.stringValue = "↑ \(up)\n↓ \(down)"
  }
}
