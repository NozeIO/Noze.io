//
//  Streams.swift
//  Noze.io
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams

// MARK: - Create Read * Write filesystem streams

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
