//
//  Streams.swift
//  NozeIO
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams

// MARK: - Create Read * Write filesystem streams

#if swift(>=3.0) // #swift3-1st-arg
public func createReadStream(_ path : String,
                             hwm  : Int = FileSource.defaultHighWaterMark)
            -> SourceStream<FileSource>
{
  return FileSource(path: path).readable(hwm: hwm)
}

public func createWriteStream(_ path : String,
                              hwm  : Int = FileTarget.defaultHighWaterMark)
            -> TargetStream<FileTarget>
{
  return FileTarget(path: path).writable(hwm: hwm)
}
#else // Swift 2.2
public func createReadStream(path : String,
                             hwm  : Int = FileSource.defaultHighWaterMark)
            -> SourceStream<FileSource>
{
  return FileSource(path: path).readable(hwm)
}

public func createWriteStream(path : String,
                              hwm  : Int = FileTarget.defaultHighWaterMark)
            -> TargetStream<FileTarget>
{
  return FileTarget(path: path).writable(hwm: hwm)
}
#endif // Swift 2.2
