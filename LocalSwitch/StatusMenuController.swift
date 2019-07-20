@discardableResult
func shell(_ command: String) -> String {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
    
    return output
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

import Cocoa

class StatusMenuController: NSObject, NSMenuDelegate {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var uptimeStat: NSMenuItem!
    
    @IBOutlet weak var visitBut: NSMenuItem!
    @IBOutlet weak var runBut: NSMenuItem!
    @IBOutlet weak var stopBut: NSMenuItem!

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    @IBAction func runClicked(_ sender: NSMenuItem) {
        shell("sudo apachectl graceful")
    }
    @IBAction func stopClicked(_ sender: NSMenuItem) {
        shell("sudo apachectl graceful-stop")
//        let theASScript = "do shell script \"apachectl graceful-stop\" with administrator privileges"
//        let appleScript = NSAppleScript(source: theASScript)
//        appleScript?.executeAndReturnError(nil)
    }
    
    func letsVisit() {
        let url = URL(string: "http://" + trimSpaces(shell("hostname")))!
        if NSWorkspace.shared.open(url) {
            print("default browser was successfully opened")
        }
    }
    
    @IBAction func visitClicked(_ sender: NSMenuItem) {
        letsVisit()
    }
    
    func trimSpaces(_ query: String) -> String {
        return query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    class RightMouseHandlerView: NSView {

        var onRightMouseDown: (()->())? = nil

        override func rightMouseDown(with event: NSEvent) {
            super.rightMouseDown(with: event)

            if onRightMouseDown != nil {
                onRightMouseDown!()
            }
        }
    }

    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.menu = statusMenu
        statusItem.length = 28
        statusMenu.delegate = self
        if let button = statusItem.button {
            button.image = icon
            
            let rmhView = RightMouseHandlerView(frame: statusItem.button!.frame)
            rmhView.onRightMouseDown = {
                if (!self.visitBut.isHidden) {
                    self.letsVisit()
                }
            }
            button.addSubview(rmhView)
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        checkServUp()
    }
    func menuDidClose(_ menu: NSMenu) {
        stopExecution = true
    }
    
    func checkServUp() {
        let checkRes = servCheck()
        if (!checkRes.isEmpty) {
            uptimeStat.title = "Server uptime: " + getTime(checkRes)
            visitBut.title = trimSpaces(shell("hostname"))
            visitBut.toolTip = shell("ipconfig getifaddr en0")
            visitBut.isHidden = false
            
            runBut.title = "Restart"
            stopBut.isEnabled = true
            stopExecution = false
            executeRepeatedly()
        } else {
            uptimeStat.title = "Server is stopped"
            runBut.title = "Run"
            visitBut.isHidden = true
            
            stopBut.isEnabled = false
            stopExecution = true
        }
    }
    
    var stopExecution = false
    
    private func executeRepeatedly() {
        if (!stopExecution) {
            let checkRes = servCheck()
            print(checkRes)
            if (!checkRes.isEmpty) {
                uptimeStat.title = "Server uptime: " + getTime(checkRes)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.executeRepeatedly()
                }
            }
        }
        
    }
}
