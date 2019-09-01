@discardableResult
func shell(_ command: String) -> String {
  let task = Process()
  task.launchPath = "/bin/bash"
  task.arguments = ["-c", command]
  
  let pipe = Pipe()
  task.standardOutput = pipe
  task.launch()
  
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  
  return NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
}

extension String {
  func condenseWhitespace() -> String {
    return self.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
  }
}

extension NSStatusBarButton {
  override open func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    print("entered dragging")
    openSitesFolder()
    return NSDragOperation()
  }
}

func servCheck() -> String {
  return shell("ps -eo comm,etime,user | grep root | grep httpd")
}

func getTime(_ query: String) -> String {
  return query.condenseWhitespace().components(separatedBy: " ")[1]
}

var statusItem = NSStatusBar.system.statusItem(withLength: 27)

func openSitesFolder() {
  NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: NSHomeDirectory() + "/Sites")
}

func runServer() {
  shell("sudo apachectl graceful")
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    if !servCheck().isEmpty {
      statusItem.button?.appearsDisabled = false
    }
  }
}
func stopServer() {
  shell("sudo apachectl graceful-stop")
  if servCheck().isEmpty {
    statusItem.button?.appearsDisabled = true
  }
}

import Cocoa
import LoginServiceKit

class StatusMenuController: NSObject, NSMenuDelegate {
  @IBOutlet weak var statusMenu: NSMenu!
  @IBOutlet weak var uptimeStat: NSMenuItem!
  
  @IBOutlet weak var visitBut: NSMenuItem!
  @IBOutlet weak var visitLocalhostBut: NSMenuItem!
  @IBOutlet weak var runBut: NSMenuItem!
  @IBOutlet weak var stopBut: NSMenuItem!
  @IBOutlet weak var restartBut: NSMenuItem!
  
  @IBOutlet weak var launchAtLoginBut: NSMenuItem!
  
  @IBAction func launchAtLoginClicked(_ sender: NSMenuItem) {
    if LoginServiceKit.isExistLoginItems() {
      LoginServiceKit.removeLoginItems()
      launchAtLoginBut.state = .off
    } else {
      LoginServiceKit.addLoginItems()
      launchAtLoginBut.state = .on
    }
  }
  
  @IBAction func openSitesClicked(_ sender: NSMenuItem) {
    openSitesFolder()
  }
  
  @IBAction func runClicked(_ sender: NSMenuItem) {
    runServer()
  }
  @IBAction func stopClicked(_ sender: NSMenuItem) {
    stopServer()
  }
  
  func letsVisit(_ url: String = "") {
    let visitThis = url.isEmpty ? trimSpaces(shell("hostname")) : url
    if NSWorkspace.shared.open(URL(string: "http://" + visitThis)!) {
      print("default browser was successfully opened")
    }
  }
  
  @IBAction func visitClicked(_ sender: NSMenuItem) {
    letsVisit()
  }
  @IBAction func visitLocalhostClicked(_ sender: NSMenuItem) {
    letsVisit("localhost")
  }
  
  func trimSpaces(_ query: String) -> String {
    return query.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  class RightMouseHandlerView: NSView {
    
    var onRightMouseDown: (()->())? = nil
    
    override func rightMouseDown(with event: NSEvent) {
      onRightMouseDown == nil ? super.rightMouseDown(with: event) : onRightMouseDown!()
    }
  }
  
  class LeftMouseHandlerView: NSView {
    
    var onOtherMouseDown: (()->())? = nil
    
    override func otherMouseDown(with event: NSEvent) {
      onOtherMouseDown == nil ? super.otherMouseDown(with: event) : onOtherMouseDown!()
    }
    
    var onLeftMouseDown: (()->())? = nil
    
    override func mouseDown(with event: NSEvent) {
      onLeftMouseDown == nil ? super.mouseDown(with: event) : onLeftMouseDown!()
    }
  }
  
  override func awakeFromNib() {
    statusItem.menu = statusMenu
    statusItem.isVisible = true
    statusItem.behavior = .terminationOnRemoval
    statusMenu.delegate = self
    if let button = statusItem.button {
      button.image = NSImage(named: "statusIcon")
      button.image?.isTemplate = true
      button.toolTip = "LocalSwitch"
      button.isSpringLoaded = true
      button.appearsDisabled = servCheck().isEmpty

      let rmhView = RightMouseHandlerView(frame: button.frame)
      rmhView.onRightMouseDown = {
        button.highlight(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          button.highlight(false)
        }
        button.appearsDisabled ? runServer() : self.letsVisit()
      }
      button.addSubview(rmhView)
      
      let lmhView = LeftMouseHandlerView(frame: button.frame)
      lmhView.onLeftMouseDown = {
        button.performClick(NSApp.currentEvent)
        if (NSApp.currentEvent?.clickCount == 2) {
          openSitesFolder()
        }
      }
      lmhView.onOtherMouseDown = {
        button.highlight(true)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
          servCheck().isEmpty ? runServer() : stopServer()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          button.highlight(false)
        }
      }
      button.addSubview(lmhView)
    }
  }
  
  func menuWillOpen(_ menu: NSMenu) {
    launchAtLoginBut.state = LoginServiceKit.isExistLoginItems() ? .on : .off
    let checkRes = servCheck()
    let boolCheckInv = checkRes.isEmpty
    stopExecution = boolCheckInv
    uptimeStat.title = "Server"
    uptimeStat.title += boolCheckInv ? ": Stopped" : (" uptime: " + getTime(checkRes))
    runBut.keyEquivalentModifierMask = boolCheckInv ? .command : []
    if !boolCheckInv {
      visitBut.title = "Visit " + trimSpaces(shell("hostname"))
      visitBut.toolTip = shell("ipconfig getifaddr en0")

      executeRepeatedly(checkRes)
    }
    statusItem.button?.appearsDisabled = boolCheckInv
    stopBut.isEnabled = !boolCheckInv
    stopBut.isHidden = boolCheckInv
    
    runBut.isEnabled = boolCheckInv
    
    restartBut.isAlternate = !boolCheckInv
    
    visitBut.isHidden = boolCheckInv
    visitLocalhostBut.isAlternate = !boolCheckInv
    visitLocalhostBut.isHidden = boolCheckInv
  }
  func menuDidClose(_ menu: NSMenu) {
    stopExecution = true
  }
  
  var stopExecution = false
  
  private func executeRepeatedly(_ check: String = "") {
    if !stopExecution {
      let checkRes = check.isEmpty ? servCheck() : check
      print(checkRes)
      if !checkRes.isEmpty {
        uptimeStat.title = "Server uptime: " + getTime(checkRes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
          self?.executeRepeatedly()
        }
      }
    }
  }
}
