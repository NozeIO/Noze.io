//
//  Logger.swift
//  Noze.io
//
//  Created by Helge Hess on 31/05/16.
//  Copyright © 2016-2017 ZeeZide GmbH. All rights reserved.
//

import xsys
import process
import console
import net
import http
import leftpad

// TODO: do some actual parsing of formats :-)

/// Logging middleware.
///
/// Currently accepts four formats:
/// - default
/// - short
/// - tiny
/// - dev    (colorized status)
///
public func logger(_ format: String = "default") -> Middleware {
  return { req, res, next in
    let startTS = timespec.monotonic()
    let fmt     = formats[format] ?? format
    
    func printLog() {
      let endTS = timespec.monotonic()
      let diff  = (endTS - startTS).milliseconds
      
      let info = LogInfoProvider(req: req, res: res, diff: diff)
      
      var msg          = ""
      
      switch fmt {
        case formats["short"]!:
          msg += "\(info.remoteAddr) -"
          msg += " \"\(req.method) \(req.url) HTTP/\(req.httpVersion)\""
          msg += " \(info.status) \(info.clen)"
          msg += " - \(info.responseTime) ms"
        
        case formats["dev"]!:
          msg += "\(req.method) \(info.paddedURL)"
          msg += " \(info.colorStatus) \(info.clen)"
          let rt = "\(info.responseTime)".leftpad(3)
          msg += " - \(rt) ms"
        
        case formats["tiny"]!:
          msg += "\(req.method) \(req.url)"
          msg += " \(info.status) \(info.clen)"
          msg += " - \(info.responseTime) ms"
        
        case formats["default"]!:
          fallthrough
        default:
          msg += "\(info.remoteAddr) - - [\(info.date)]"
          msg += " \"\(req.method) \(req.url) HTTP/\(req.httpVersion)\""
          msg += " \(info.status) \(info.clen)"
          msg += " \(info.qReferrer) \(info.qUA)"
      }
      
      // let msg = res.statusMessage ?? HTTPStatus.text(forStatus: res.statusCode!)
      console.log(msg)
    }
    
    _ = res.onFinish { printLog() }
    next()
  }
}


private let formats = [
  "default":
    ":remote-addr - - [:date] \":method :url HTTP/:http-version\"" +
    " :status :res[content-length] \":referrer\" \":user-agent\"",
  "short":
    ":remote-addr - :method :url HTTP/:http-version" +
    " :status :res[content-length] - :response-time ms",
  "tiny": ":method :url :status :res[content-length] - :response-time ms",
  "dev":
     ":method :paddedurl :colorstatus :res[content-length] - :response-time ms"
]


private struct LogInfoProvider {
  
  let req  : IncomingMessage
  let res  : ServerResponse
  let diff : Int
  
  let noval        = "-"
  
  var remoteAddr   : String {
    guard let sock = req.stream as? Socket else { return noval }
    guard let addr = sock.remoteAddress    else { return noval }
    switch addr {
      case .AF_INET (let addr): return "\(addr.address)"
      case .AF_INET6(let addr): return "\(addr.address)"
      default: return noval
    }
  }
  var responseTime : String { return "\(diff)" }
  
  var ua           : String? { return req.headers[ci: "User-Agent"] as? String }
  var referrer     : String? { return req.headers[ci: "Referrer"]   as? String }
  
  var qReferrer : String {
    guard let s = referrer else { return noval }
    return "\"\(s)\""
  }
  var qUA : String {
    guard let s = ua else { return noval }
    return "\"\(s)\""
  }
  
  var date  : String {
    // 31/May/2016:07:53:29 +0200
    let logdatefmt = "%d/%b/%Y:%H:%M:%S %z"
    let time = xsys.time(nil).componentsInLocalTime
    return "\(time.format(logdatefmt))"
  }
  
  var clen  : String {
    let clenI = Int((res.getHeader("Content-Length") as? String) ?? "") ?? -1
    return clenI >= 0 ? "\(clenI)" : noval
  }
  
  var status      : String {
    return res.statusCode != nil ? "\(res.statusCode!)" : noval
  }
  var colorStatus : String {
    let colorStatus : String
    
    if !process.stdout.isTTY || process.isRunningInXCode {
      colorStatus = self.status
    }
    else if let status = res.statusCode {
      switch status {
        case 200..<300: colorStatus = "\u{001B}[0;32m\(status)\u{001B}[0m"
        case 300..<400: colorStatus = "\u{001B}[0;34m\(status)\u{001B}[0m"
        case 400..<500: colorStatus = "\u{001B}[0;35m\(status)\u{001B}[0m"
        case 500..<600: colorStatus = "\u{001B}[0;31m\(status)\u{001B}[0m"
        default:        colorStatus = "\(status)"
      }
    }
    else {
      colorStatus = noval
    }
    
    return colorStatus
  }
  
  static var urlPadLen = 28
  var paddedURL : String {
    let url       = req.url
    #if swift(>=3.2)
      let oldLength = url.count
    #else
      let oldLength = url.characters.count
    #endif
    if oldLength > LogInfoProvider.urlPadLen {
      LogInfoProvider.urlPadLen = oldLength + ( oldLength % 2)
    }
    let padlen = LogInfoProvider.urlPadLen
    
    // right pad :-)
    let s = Array<Character>(repeating: " ", count: (padlen - oldLength))
    return url + String(s)
  }
}
