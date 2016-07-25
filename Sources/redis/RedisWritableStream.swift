//
//  RedisWritableStream.swift
//  Noze.io
//
//  Created by Helge Heß on 6/25/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams

private let eol       : [ UInt8 ]    = [ 13, 10 ]
private let nilString : [ [ UInt8 ]] = [[ 36, 45, 49, 13, 10 ]] // $-1\r\n
private let nilArray  : [ [ UInt8 ]] = [[ 42, 45, 49, 13, 10 ]] // *-1\r\n

extension GWritableStreamType where WriteType == UInt8 {
  // TBD: this could also be a TransformStream<RedisValue, UInt8>
  //      - Which I guess would be betta? Well, we would gain better piping,
  //        but this solution here has less overhead? TBD
  
  
  public func write(redisValue v: RedisValue) {
    switch v {
      case .SimpleString(let s): writeRedis(simpleString: s)
      case .BulkString  (let s): writeRedis(bulkString:   s)
      case .Integer     (let i): writeRedis(int: i)
      case .Error(let error):
        write("-\(error.code) \(error.message)\r\n")
      
      case .Array(let array):
        writeRedis(array: array)
    }
  }
  public func write(redisValue v: RedisEncodable) {
    write(redisValue: v.toRedis())
  }
  
  
  // MARK: - arrays
  
  public func writeRedis(array v: [ RedisValue ]?) {
    guard let array = v else {
      writev(buckets: nilArray, done: nil)
      return
    }
    
    write("*\(array.count)\r\n") // FIXME: slow&lame
    for item in array {
      write(redisValue: item)
    }
  }
  
  // MARK: - base types
  
  public func writeRedis(bulkString v: [UInt8]?) {
    guard let s = v else { // nil
      writev(buckets: nilString, done: nil)
      return
    }
    
    write("$\(s.count)\r\n") // FIXME: slow&lame
    writev(buckets: [ s, eol ], done: nil)
  }
  
  public func writeRedis(bulkString v: String) {
    writeRedis(bulkString: Array<UInt8>(v.utf8)) // copying, sigh
  }
  
  public func writeRedis(simpleString v: [UInt8]) {
    writev(buckets: [ [ 43 ], v, eol ], done: nil)
  }
  public func writeRedis(simpleString v: String) {
    writeRedis(simpleString: Array<UInt8>(v.utf8)) // copying, sigh
  }
  
  public func writeRedis(int v: Int) {
    write(":\(v)\r\n") // FIXME: slow&lame
  }
}
