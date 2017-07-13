//
//  Created by Helge Hess on 07/12/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import xsys
import fs
import console
import process
import child_process

enum config {
  enum data {
    static let title = "swiftmon/S"
  }
}

final class Daemon {
  
  struct Options {
    var config           = "debug"
    var startScript      : String
    var sourceDir        : String
    var restartDelayInMS = 100
  }
  
  let options      : Options
  var child        : ChildProcess? = nil
  var needsRestart = false

  init(options: Options) {
    self.options = options
  }
  convenience init(config: String = "debug", startScript: String, 
                   sourceDir: String, restartDelayInMS: Int = 100)
  {
    self.init(options: Options(config: config, startScript: startScript,
                               sourceDir: sourceDir,
                               restartDelayInMS: restartDelayInMS))
  }
  
  func start() {
    console.log(colors.yellow("\(config.data.title) watching " +
                              "\(options.sourceDir)"))
        
    _ = fs.watch(options.sourceDir, recursive: true) { event in
      // TODO: coalesce
      
      console.log(colors.gray ("\(event.filename ?? "unknown") " +
                               "file has been changed"),
                  colors.green("restarting ..."))
      self.setNeedsRestart()
    }
    
    restartProcess()
  }
  
  func setNeedsRestart() {
    guard !needsRestart else { return }
    
    needsRestart = true
    setTimeout(options.restartDelayInMS) {
      guard self.needsRestart else { return }
      self.needsRestart = false
      
      self.restartProcess()
    }
  }
  
  func killChild() {
    guard let c = child
     else {
      //console.info("got no child to kill ...") // uh oh
      return
     }
    self.child = nil
    
    if !c.kill(xsys.SIGKILL) { // SIGTERM is not good enough
      console.error("failed to kill \(c.pid)")
    }
  }
  
  func restartProcess() {
    let startScript = "./.build/\(options.config)/\(options.startScript)"
    console.log(colors.green("\(config.data.title) building and starting..."))

    killChild()
    assert(child == nil)
    
    // TODO: { shell: true, detached: true }
    let build = spawn("swift", stdio: [ .Inherit, .Inherit, .Inherit ],
                      "build")
                  
    _ = build.onceExit { code, signal in
      guard let code = code else { return }
      guard code == 0 else {
        console.log(colors.red("build failed!"), "\n\(sep)")
        return
      }
      
      console.log(colors.gray(">>>\n"))
      
      self.child = spawn(startScript, stdio: [ .Inherit, .Inherit, .Inherit ])
      
      _ = self.child?.onceExit { code, signal in
        guard let code = code else { return }
        console.log(colors.gray("\n<<<"))
        if code == 0 {
          console.log("Exited with code: \(colors.green(code))\n\(sep)")
        }
        else {
          console.error("Exited with code: \(colors.red(code))\n\(sep)")
        }
      }
    }
  }
  
}

let sep = "------------------------------------------------------------\n"
