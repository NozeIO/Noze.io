//
//  Stdio.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import streams
import fs

public var stdin  = createStdin()
public var stdout = createStdoutOrErr(fd: xsys.STDOUT_FILENO)
public var stderr = createStdoutOrErr(fd: xsys.STDERR_FILENO)

// TODO: Need a protocol to abstract the Readable? from the source?
// TODO: figure out whether 0/1/2 is a file or terminal to create either a
//       threaded or an kqueued file descript

private func createStdin() -> SourceStream<StdInSource> {
  return StdInSource().readable()
}

// public for testing
private func createStdoutOrErr(fd lfd: Int32 = xsys.STDOUT_FILENO)
             -> TargetStream<StdOutTarget>
{
  return StdOutTarget(fd: Int32(lfd)).writable()
}


// MARK: - TTY

public extension SourceStream where G: StdInSource {
  
  public var isTTY : Bool {
    return source.fd.isTTY
  }
  
}

public extension TargetStream where T: StdOutTarget {

  public var isTTY : Bool {
    return target.fd.isTTY
  }
  
}
