//
//  pipe.swift
//  Noze.io
//
//  Created by Helge Hess on 31/03/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import xsys
import core
import events

// TODO: this has quite a few open ends aside from the happy path

private let tickPipe       = true
private let enableHeavyLog = false

#if swift(>=3.0) // #swift3-discardable-result
/// Pipe operator for streams, neat :-)
///
/// Like so:
///
///   request | zip | encrypt | fs
///
@discardableResult
public func |<ReadStream: GReadableStreamType, WriteStream: GWritableStreamType
              where ReadStream.ReadType == WriteStream.WriteType>
             (left: ReadStream, right: WriteStream) -> WriteStream
{
  return left.pipe(right)
}

@discardableResult
public func |<ReadStream: GReadableStreamType, WriteStream: GWritableStreamType
              where ReadStream.ReadType == WriteStream.WriteType>
             (left: ReadStream?, right: WriteStream) -> WriteStream
{
  guard left != nil else {
    // left side has nothing to pipe, immediately end target stream.
    // TBD: good idea? :-) Added this to support: spawn("ls").stdout | ...
    right.end()
    return right
  }
  
  return left!.pipe(right)
}
#else
/// Pipe operator for streams, neat :-)
///
/// Like so:
///
///   request | zip | encrypt | fs
///
public func |<ReadStream: GReadableStreamType, WriteStream: GWritableStreamType
              where ReadStream.ReadType == WriteStream.WriteType>
             (left: ReadStream, right: WriteStream) -> WriteStream
{
  return left.pipe(right)
}

public func |<ReadStream: GReadableStreamType, WriteStream: GWritableStreamType
              where ReadStream.ReadType == WriteStream.WriteType>
             (left: ReadStream?, right: WriteStream) -> WriteStream
{
  guard left != nil else {
    // left side has nothing to pipe, immediately end target stream.
    // TBD: good idea? :-) Added this to support: spawn("ls").stdout | ...
    right.end()
    return right
  }
  
  return left!.pipe(right)
}
#endif

public extension GReadableStreamType {

#if swift(>=3.0) // #swift3-1st-arg #swift3-discardable-result
  @discardableResult
  public func pipe<TO: GWritableStreamType where Self.ReadType == TO.WriteType>
                  (_ outStream: TO,
                   endOnFinish: Bool = true, passErrors: Bool = true)
              -> TO
  {
    return pipe(to: outStream, endOnFinish: endOnFinish, passErrors: passErrors)
  }
#else
  public func pipe<TO: GWritableStreamType where Self.ReadType == TO.WriteType>
                  (outStream: TO,
                   endOnFinish: Bool = true, passErrors: Bool = true)
              -> TO
  {
    return pipe(to: outStream, endOnFinish: endOnFinish, passErrors: passErrors)
  }
#endif

  /// pipe(in: GReadableStreamType, out: GWritableStreamType)
  ///
  /// pipe() simply connects an input stream with an output stream, but in an
  /// asynchronous way. 
  /// - as input becomes available on the input stream, it is pushed into the 
  ///   output stream
  /// - if the output stream is busy/full, the input stream is suspended
  ///
  public func pipe<TO: GWritableStreamType where Self.ReadType == TO.WriteType>
                  (to outStream: TO,
                   endOnFinish: Bool = true, passErrors: Bool = true)
              -> TO
  {
    // Node.JS notes:
    // - onPipe is sent by writable stream (and onUnpipe)
    // - though the current code doesn't seem to be pull-stream based?
    
    // to test drain:
    //   self.highWaterMark = 1 // with 0 it stalls
    
    let state = StreamPipeState(self, outStream,
                                endOnFinish: endOnFinish, passErrors: passErrors)
    
    // TODO: Node.JS tracks the pipes in the source streams. I don't think this
    //       is necessary, but might be useful for debugging.
    
    if let emitTarget = outStream as? PipeEmitTarget {
      emitTarget.emit(pipe: self)
    }
    
    _ = self.onError       { error in state.onSourceError(error) }
    _ = outStream.onError  { error in state.onTargetError(error) }
    _ = self.onEnd         { state.onEnd()    }
    _ = outStream.onFinish { state.onFinish() }
    
    
    // start the piping
    
    heavyLog("install initial read handler ...")
    let log : Logger?
    if let ll = self as? LameLogObjectType { log = ll.log }
    else { log = nil }
    
    _ = self.onceReadable {
      log?.enter(function: "onReadable")
      defer { log?.leave(function: "onReadable") }
      
      heavyLog("  initial pipe call")
      state.onPipeSourceReadable()
    }
    
    return outStream
  }
  
  // TODO: unpipe() function? not really necessary though ...
}

private class StreamPipeState<TI: GReadableStreamType, TO: GWritableStreamType
                              where TI.ReadType == TO.WriteType>
{
  let src         : TI
  let dest        : TO
  let endOnFinish : Bool
  let passErrors  : Bool
  
  init(_ src: TI, _ dest: TO, endOnFinish: Bool, passErrors: Bool) {
    self.endOnFinish = endOnFinish
    self.passErrors  = passErrors
    self.src  = src
    self.dest = dest
  }
  
  
  // MARK: - onReadable
  
  final func onPipeSourceReadable() {
    let inStream  = src
    let outStream = dest
    
#if swift(>=3.0) // #swift3-1st-arg
    func heavyPipeLog(_ s : String) { heavyLog("  <<[DO pipe: \(s)]>>  ") }
#else
    func heavyPipeLog(s   : String) { heavyLog("  <<[DO pipe: \(s)]>>  ") }
#endif
    
    heavyPipeLog("before read \(inStream)")
    let bucketOrEOF = inStream.read()
    heavyPipeLog(" after read \(inStream)")
    
    guard let bucket = bucketOrEOF else {
      heavyPipeLog("\nCCC hit ********** EOF ***********. \(inStream)")
      // FIXME: hitEOF apparently not set on sockets?
      //assert(inStream.hitEOF)
      if endOnFinish {
        heavyPipeLog("closing out")
        outStream.end()
      }
      else {
        heavyPipeLog("keeping out open")
      }
      return
    }
    
    heavyPipeLog("  got bucket size #\(bucket.count), " +
                 "write it .. \(inStream)")
    if bucket.count < 20 {
      heavyPipeLog("BUCKET: \(bucket)")
    }
    
    // NOTE: Even if this returns false, the outStream still caches the
    //       buckets. I think it is a hint that the inStream should pause.
    let couldWriteEverything = outStream.write(bucket)
    //let couldWriteEverything = true
    
    heavyPipeLog(couldWriteEverything
                 ? "  wrote-all: #\(bucket.count) \(outStream)"
                 : "  buffer overflow: \(outStream)")
    
    
    if couldWriteEverything {
      heavyPipeLog("  install onceReadable ...: \(inStream)")
      _ = inStream.onceReadable {
        heavyPipeLog("    got onceReadable, " +
                     "call doPipeStuff \(inStream)")
        if tickPipe {
          nextTick { self.onPipeSourceReadable() }
            // recurse // this makes us hit EOF
        }
        else {
          self.onPipeSourceReadable() // recurse
        }
      }
    }
    else {
      heavyPipeLog("    PAUSing because we could not write everything:\n" +
                   "      in=\(inStream)\n" +
                   "     out=\(outStream)")
      inStream.pause()
      
      heavyPipeLog("C: install drain handler ...")
      _ = outStream.onceDrain {
        heavyPipeLog("\nC: got ************** drain ************ ...\n" +
                     "      in=\(inStream)\n" +
                     "     out=\(outStream)")
        
        _ = inStream.onceReadable {
          heavyPipeLog("\n*** running onceReadable")
          if tickPipe {
            nextTick { self.onPipeSourceReadable() }
              // recurse // this makes us hit EOF
          }
          else {
            self.onPipeSourceReadable() // recurse
          }
        }
        
        inStream.resume()
      }
    }
  }
  
  
  // MARK: - Errors
  
  var ignoreTargetErrors = false // in case we are the ones emitting them ;-)
  
  final func onSourceError(error: ErrorProtocol) {
    //efprint("CCC GOT ERROR: \(error)") // TODO
    
    //if let perr = error as? POSIXError {
    //  efprint("  Posix: \(perr.rawValue)")
    //}
    
    // TODO: what should we do here?
    // - forward error to target and unpipe?
    //
    // Well:
    // - http://grokbase.com/t/gg/nodejs/12bwd4zm4x/should-stream-pipe-forward-errors
    // - http://stackoverflow.com/questions/21771220/error-handling-with-node-js-streams
    // "According to this thread .pipe() is not built to forward errors":
    //   createStream()
    //     .onError { e in handleError(e) }
    //   .pipe(b)
    //     .onError { e in handleError(e) }
    //   .pipe(c)
    //     .onError { e in handleError(e) }
    
    // We do pass along errors by default. Because, I think, it just makes
    // sense ... We do, however, wrap the error.
    if passErrors {
      // TBD: Only forward if the source has no error handler besides the
      //      pipe itself? Would be nice.
      if let errDest = dest as? ErrorEmitTarget {
        let pipeError : PipeSourceError
        if let oldPipeError = error as? PipeSourceError {
          // TBD: should we add this stream as a pass-through to the error?
          pipeError = oldPipeError
        }
        else {
          pipeError = PipeSourceError(error: error, stream: src)
        }
        
        ignoreTargetErrors = true // we are done
        errDest.emit(error: pipeError)
      }
    }
    
    // an error ends the target
    onEnd()
  }
  
  final func onTargetError(error: ErrorProtocol) {
    // TODO: do we actually care about target errors?
    
    // Note: The OutStream can be a Duplex! I.e. the error might also be an
    //       error of the in-side of the Duplex
    efprint("Pipe TargetError: ERROR: \(error)")
    
    if ignoreTargetErrors {
      return
    }
    
    // TODO: what should we do here?
    
    //xsys.exit(42)
  }
  
  final func onEnd() {
    if let emitTarget = dest as? PipeEmitTarget {
      heavyLog("EMIT UNPIPE: \(src) \(dest)")
      emitTarget.emit(unpipe: src)
      heavyLog("DID  UNPIPE: \(src) \(dest)")
    }
    if endOnFinish {
      heavyLog("Closing \(dest)")
      dest.end()
    }
    else {
      heavyLog("Keeping open \(dest)")
    }
  }
  
  final func onFinish() {
    heavyLog("\nC hit ********** FINISHED ***********.")
    // TODO: need to do anything on self, like pause the source?
  }
  
#if swift(>=3.0) // #swift3-1st-arg
  final func onSourceError(_ error: ErrorProtocol) { onSourceError(error: error) }
  final func onTargetError(_ error: ErrorProtocol) { onTargetError(error: error) }
#endif
}


// TEMPORARY, for hacking

#if os(Linux)
import Glibc
#endif

private var nzStdErr = StdErrStream()

#if swift(>=3.0)
private struct StdErrStream : OutputStream {
  mutating func write(_ string: String) { fputs(string, stderr) }
}

private func efprint<T>(_ value: T) {
  fflush(stderr)
  print(value, nzStdErr)
  fflush(stderr)
}
private func heavyLog<T>(_ value: T) {
  if enableHeavyLog { efprint(value) }
}
#else
private struct StdErrStream : OutputStreamType {
  mutating func write(string: String) { fputs(string, stderr) }
}

private func efprint<T>(value: T) {
  fflush(stderr)
  print(value, toStream:&nzStdErr)
  fflush(stderr)
}
private func heavyLog<T>(value: T) {
  if enableHeavyLog { efprint(value) }
}
#endif
