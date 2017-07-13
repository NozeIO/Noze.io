//
//  Created by Helge Hess on 07/12/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

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
    var config      = "debug"
    var startScript : String
    var sourceDir   : String
  }
  
  let options : Options
  
  var child   : ChildProcess? = nil

  init(options: Options) {
    self.options = options
  }
  convenience init(config: String = "debug", startScript: String, 
                   sourceDir: String) 
  {
    self.init(options: Options(config: config, startScript: startScript,
                               sourceDir: sourceDir))
  }
  
  func start() {
    console.log(colors.yellow("\(config.data.title) watching " +
                              "\(options.sourceDir)"))
        
    _ = fs.watch(options.sourceDir, recursive: true) { event in
      // TODO: coalesce
      
      console.log(colors.gray ("\(event.filename ?? "unknown") " +
                               "file has been changed"),
                  colors.green("restarting ..."))
      self.restartProcess()
    }
    
    restartProcess()
  }
  
  func killChild() {
    guard let c = child else { return }
    self.child = nil
    
    try? process.kill(Int(c.pid))
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
      
      console.log(">>>\n")
      self.child = spawn(startScript, stdio: [ .Inherit, .Inherit, .Inherit ])
      _ = self.child?.onceExit { code, signal in
        guard let code = code else { return }
        console.log("\n<<<")
        console.log("Exited with code: \(code)\n\(sep)")
      }
    }
  }
  
}

let sep = "------------------------------------------------------------\n"
