import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldHandleReopen(_ sender: NSApplication,
                                     hasVisibleWindows flag: Bool) -> Bool
  {
    if (servCheck().isEmpty) {
      shell("sudo apachectl graceful")
    } else {
      shell("sudo apachectl graceful-stop")
    }
    return true
  }
}
