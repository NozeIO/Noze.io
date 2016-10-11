//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import core
import fs

public class NozeConsole : NozeModule {
}

public var module = NozeConsole()

public var defaultConsole : ConsoleType =
             Console2(StdOutTarget(fd: Int32(xsys.STDOUT_FILENO)).writable(),
                      StdOutTarget(fd: Int32(xsys.STDERR_FILENO)).writable())

// top level functions, so that you can do: console.info() ...
// Note: yes, we could name `defaultConsole` 'console', but then stuff
//       like console.module gets weird.

public func error(_ msg: @autoclosure () -> String, _ values : Any?...) {
  defaultConsole.primaryLog(.Error, msg, values)
}
public func warn (_ msg: @autoclosure () -> String, _ values : Any?...) {
  defaultConsole.primaryLog(.Warn, msg, values)
}
public func log  (_ msg: @autoclosure () -> String, _ values : Any?...) {
  defaultConsole.primaryLog(.Log, msg, values)
}
public func info (_ msg: @autoclosure () -> String, _ values : Any?...) {
  defaultConsole.primaryLog(.Info, msg, values)
}
public func trace(_ msg: @autoclosure () -> String, _ values : Any?...) {
  defaultConsole.primaryLog(.Trace, msg, values)
}

public func dir(_ obj: Any?) {
  // TODO: implement more
  defaultConsole.dir(obj)
}
