import Cocoa
import LoginServiceKit

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

  func parseDuration() -> TimeInterval {
    guard !self.isEmpty else {
      return 0
    }
    
    var interval:Double = 0
    
    let parts = self.components(separatedBy: ":")
    for (index, part) in parts.reversed().enumerated() {
      interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
    }
    
    return interval
  }

}

extension TimeInterval {
  
  func stringFromTimeInterval() -> String {
    
    let time = NSInteger(self)
    
//    let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
    let seconds = time % 60
    let minutes = (time / 60) % 60
    let hours = (time / 3600)
    let days = time / (3600 * 24)
    
    var humanRdableString = String()
    if days != 0 {
      humanRdableString += "\(days)d"
    }
    if hours != 0 {
      humanRdableString += " \(hours)h"
    }
    if minutes != 0 {
      humanRdableString += " \(minutes)m"
    }
    if seconds != 0 {
      humanRdableString += " \(seconds)s"
    }

    humanRdableString = humanRdableString.condenseWhitespace()

    return humanRdableString
    
  }

}

func getTime(_ query: String) -> String {
  let initTime = query.condenseWhitespace().components(separatedBy: " ")[1]
  print(initTime)
  let theInterval = initTime.parseDuration().stringFromTimeInterval()
  print(theInterval)
  return theInterval
}

extension NSStatusBarButton {
  override open func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    print("entered dragging")
    openSitesFolder()
    return NSDragOperation()
  }
}

var statusItem = NSStatusBar.system.statusItem(withLength: 27)

func openSitesFolder() {
  NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: NSHomeDirectory() + "/Sites")
}

public final class Server: NSObject {
  static func check() -> String {
    return shell("ps -eo comm,etime,user | grep root | grep httpd")
  }

  static func run() {
    shell("sudo apachectl graceful")
    statusItem.button?.fadeIn()
    statusItem.button?.spin()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
      if check().isEmpty {
        statusItem.button?.fadeOut()
      }
    }
  }
  static func stop() {
    shell("sudo apachectl graceful-stop")
    if check().isEmpty {
      statusItem.button?.fadeOut()
    }
  }
}

class StatusMenuController: NSObject, NSMenuDelegate {
  @IBOutlet weak var statusMenu: NSMenu!
  @IBOutlet weak var uptimeStat: NSMenuItem!
  
  @IBOutlet weak var runBut: NSMenuItem!
  @IBOutlet weak var restartBut: NSMenuItem!
  @IBAction func runClicked(_ sender: NSMenuItem) {
    Server.run()
  }
  
  @IBOutlet weak var stopBut: NSMenuItem!
  @IBAction func stopClicked(_ sender: NSMenuItem) {
    Server.stop()
  }
  
  func letsVisit(_ url: String = "") {
    let visitThis = url.isEmpty ? trimSpaces(shell("hostname")) : url
    if NSWorkspace.shared.open(URL(string: "http://" + visitThis)!) {
      print("default browser was successfully opened")
    }
  }
  
  @IBOutlet weak var visitBut: NSMenuItem!
  @IBAction func visitClicked(_ sender: NSMenuItem) {
    letsVisit()
  }
  
  @IBOutlet weak var visitLocalhostBut: NSMenuItem!
  @IBAction func visitLocalhostClicked(_ sender: NSMenuItem) {
    letsVisit("localhost")
  }
  
  let foldersMenuItem = NSMenuItem.init(title: "Projects", action: nil, keyEquivalent: "")
  
  @IBAction func openSitesClicked(_ sender: NSMenuItem) {
    openSitesFolder()
  }
  
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
  
  @objc func openFolder(_ sender: NSMenuItem) {
    print(sender.title)
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: NSHomeDirectory() + "/Sites/" + sender.title)
  }
  @objc func openSite(_ sender: NSMenuItem) {
    print(sender.title)
    if NSWorkspace.shared.open(URL(string: "http://localhost/" + sender.title + "/")!) {
      print("default browser was successfully opened")
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
      button.appearsDisabled = Server.check().isEmpty

      let rmhView = RightMouseHandlerView(frame: button.frame)
      rmhView.onRightMouseDown = {
        button.highlight(true)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
          Server.check().isEmpty ? Server.run() : self.letsVisit()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          button.highlight(false)
        }
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
          Server.check().isEmpty ? Server.run() : Server.stop()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          button.highlight(false)
        }
      }
      button.addSubview(lmhView)
      
      let sentence = shell(" ls -F ~/Sites | grep /")
      let lines = sentence.split { $0.isNewline }
      print(lines)   // "[Line 1, Line 2, Line 3]"
      let menuOfFolders = NSMenu()
      
      foldersMenuItem.submenu = menuOfFolders
      
      for item in lines {
        var readyItem = item
        readyItem.remove(at: readyItem.index(before: readyItem.endIndex))

        menuOfFolders.addItem(withTitle: String(readyItem), action: #selector(openSite(_:)), keyEquivalent: "")
        menuOfFolders.item(withTitle: String(readyItem))?.target = self
      }

      foldersMenuItem.indentationLevel = 2
      statusMenu.insertItem(foldersMenuItem, at: 7)
    }
  }
  
  func menuNeedsUpdate(_ menu: NSMenu) {
    launchAtLoginBut.state = LoginServiceKit.isExistLoginItems() ? .on : .off
    let checkRes = Server.check()
    let boolCheckInv = checkRes.isEmpty
    stopExecution = boolCheckInv
  
    uptimeStat.title = boolCheckInv ? "Server: Stopped" : ("Uptime: " + getTime(checkRes))
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
    foldersMenuItem.isHidden = boolCheckInv
  }
  func menuDidClose(_ menu: NSMenu) {
    stopExecution = true
  }
  
  var stopExecution = false
  
  private func executeRepeatedly(_ check: String = "") {
    if !stopExecution {
      let checkRes = check.isEmpty ? Server.check() : check
      print(checkRes)
      if !checkRes.isEmpty {
        uptimeStat.title = "Uptime: " + getTime(checkRes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
          self?.executeRepeatedly()
        }
      }
    }
  }
}
