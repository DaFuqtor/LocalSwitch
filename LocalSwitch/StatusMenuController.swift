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

func servCheck() -> String {
  return shell("ps -eo comm,etime,user | grep root | grep httpd")
}

func getTime(_ query: String) -> String {
  return query.condenseWhitespace().components(separatedBy: " ")[1]
}

var statusItem = NSStatusBar.system.statusItem(withLength: 27)

func runServer() {
  shell("sudo apachectl graceful")
  statusItem.button?.appearsDisabled = false
}
func stopServer() {
  shell("sudo apachectl graceful-stop")
  statusItem.button?.appearsDisabled = true
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
  
  @IBAction func quitClicked(_ sender: NSMenuItem) {
    NSApplication.shared.terminate(self)
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
  
  override func awakeFromNib() {
    statusItem.menu = statusMenu
    statusItem.isVisible = true
    statusItem.behavior = .terminationOnRemoval
    statusMenu.delegate = self
    if let button = statusItem.button {
      button.image = NSImage(named: "statusIcon")
      button.image?.isTemplate = true
      button.toolTip = "LocalSwitch"
      button.appearsDisabled = servCheck().isEmpty
      
      let rmhView = RightMouseHandlerView(frame: statusItem.button!.frame)
      rmhView.onRightMouseDown = {
        button.appearsDisabled ? runServer() : self.letsVisit()
      }
      button.addSubview(rmhView)
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

      executeRepeatedly()
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
  
  private func executeRepeatedly() {
    if !stopExecution {
      let checkRes = servCheck()
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
