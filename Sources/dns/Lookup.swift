//
//  Lookup.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import xsys
import core

public typealias LookupCB = ( Error?, sockaddr_any? ) -> Void

let lookupQueue = DispatchQueue(label:      "io.noze.dns.lookup",
                                attributes: DispatchQueue.Attributes.concurrent)

/// Perform a DNS lookup using the system facilities.
///
/// Note: This is different to Node in that it directly uses the system types
///       (which integrate nicely into Swift)
///
/// Family is AF_INET4 / AF_INET6
///
public func lookup(_ domain : String,
                   family : sa_family_t = sa_family_t(xsys.PF_UNSPEC),
                   cb     : @escaping LookupCB)
{
  core.module.retain()
  
  lookupQueue.async {
    defer { core.module.release() }
    
    var hints = addrinfo()
    hints.ai_family = Int32(family)
    
    var ptr : UnsafeMutablePointer<addrinfo>? = nil
    defer { freeaddrinfo(ptr) } /* free OS resources (TBD: works with nil?) */
    
    let rc = getaddrinfo(domain, nil, &hints, &ptr)
    guard rc == 0 else {
      nextTick {
        cb(POSIXErrorCode(rawValue: rc), nil)
      }
      return
    }
    
    // Does this mean no error, but no result either?
    guard ptr != nil else {
      nextTick {
        cb(nil, nil)
      }
      return
    }
    
    /* copy results - we just take the first match */
    let info   = ptr!.pointee
    var result : sockaddr_any? = nil
    
    if info.ai_addr == nil {
      result = nil // TODO: proper error
    }
    else if info.ai_family == xsys.AF_INET {
      //let aiptr = UnsafePointer<xsys_sockaddr_in>(info.ai_addr) // cast
      info.ai_addr.withMemoryRebound(to: xsys_sockaddr_in.self, capacity: 1) {
        aiptr in
        result = sockaddr_any.AF_INET(aiptr.pointee)
      }
    }
    else if info.ai_family == xsys.AF_INET6 {
      info.ai_addr.withMemoryRebound(to: xsys_sockaddr_in6.self, capacity: 1) {
        aiptr in
        result = sockaddr_any.AF_INET6(aiptr.pointee)
      }
    }
    else {
      result = nil // TODO: proper error
    }
        
    nextTick {
      cb(nil, result)
    }
  }
}
