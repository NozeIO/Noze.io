//
//  Created by Helge Hess on 07/12/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import fs
import process
import console

let env = "debug"

let options = Daemon.Options(
  config           : "debug",
  startScript      : path.basename(process.cwd()),
  sourceDir        : "Sources",
  restartDelayInMS : 100
)

let daemon = Daemon(options: options)
daemon.start()
