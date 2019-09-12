import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldHandleReopen(_ sender: NSApplication,
                                     hasVisibleWindows flag: Bool) -> Bool
  {
    if let button = statusItem.button {
      button.highlight(true)
      DispatchQueue.main.asyncAfter(deadline: .now()) {
        Server.check().isEmpty ? Server.run() : Server.stop()
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        button.highlight(false)
      }
    }
    return true
  }
  func applicationWillFinishLaunching(_ aNotification: Notification) {
    LetsMove.shared.moveToApplicationsFolderIfNecessary()
  }
}
