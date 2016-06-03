//
//  HTTPStatus.swift
//  HTTPParser
//
//  Created by Helge Heß on 6/19/14.
//  Copyright © 2014 Always Right Institute. All rights reserved.
//

public enum HTTPStatus : Equatable {
  // Either inherit from Int (and have raw values) OR have cases with associated
  // values. Pretty annoying and results in all the mapping below (which is
  // kinda OK here given that RFCs are static)
  
  case OK, Created, Accepted, NoContent, ResetContent, PartialContent
  case MultiStatus, AlreadyReported, IMUsed
  
  case MultipleChoices, MovedPermanently, Found, SeeOther, NotModified
  case UseProxy, SwitchProxy
  case TemporaryRedirect
  case ResumeIncomplete // vs .PermanentRedirect
  
  case BadRequest, Unauthorized, 💰Required, Forbidden, NotFound
  case MethodNotAllowed, NotAcceptable
  case ProxyAuthenticationRequired
  case RequestTimeout
  case Conflict, Gone
  case LengthRequired
  case PreconditionFailed
  case RequestEntityTooLarge, RequestURITooLong
  case UnsupportedMediaType
  case RequestRangeNotSatisfiable
  case ExpectationFailed
  case IAmATeapot // there is no teapot Emoji? only a teacan?
  case UnprocessableEntity, Locked, FailedDependency, UnorderedCollection
  case UpgradeRequired, PreconditionRequired
  
  case InternalServerError, NotImplemented, BadGateway, ServiceUnavailable
  case GatewayTimeout, HTTPVersionNotSupported
  case VariantAlsoNegotiates
  case InsufficientStorage, LoopDetected
  case NotExtended
  
  case Extension(Int, String) // status, statusText
}

#if swift(>=3.0) // #swift3-fd
extension HTTPStatus : Boolean {
  public var boolValue : Bool { return status >= 200 && status < 300 }
}
#else
extension HTTPStatus : BooleanType {
  public var boolValue : Bool { return status >= 200 && status < 300 }
}
#endif

extension HTTPStatus : RawRepresentable {
  public init?(rawValue: Int) { self.init(rawValue) }
  public var rawValue: Int { return self.status }
}

public extension HTTPStatus {
  
  public init(_ status: Int, _ text: String? = nil) {
    switch status {
      case 200: self = .OK
      case 201: self = .Created
      case 202: self = .Accepted
      case 204: self = .NoContent
      case 205: self = .ResetContent
      case 206: self = .PartialContent
      case 207: self = .MultiStatus
      case 208: self = .AlreadyReported
      case 226: self = .IMUsed // RFC 3229
      
      case 300: self = .MultipleChoices
      case 301: self = .MovedPermanently
      case 302: self = .Found
      case 303: self = .SeeOther
      case 304: self = .NotModified
      case 305: self = .UseProxy
      case 306: self = .SwitchProxy
      case 307: self = .TemporaryRedirect
      case 308: self = .ResumeIncomplete
      
      case 400: self = .BadRequest
      case 401: self = .Unauthorized
      case 402: self = .💰Required
      case 403: self = .Forbidden
      case 404: self = .NotFound
      case 405: self = .MethodNotAllowed
      case 406: self = .NotAcceptable
      case 407: self = .ProxyAuthenticationRequired
      case 408: self = .RequestTimeout
      case 409: self = .Conflict
      case 410: self = .Gone
      case 411: self = .LengthRequired
      case 412: self = .PreconditionFailed
      case 413: self = .RequestEntityTooLarge
      case 414: self = .RequestURITooLong
      case 415: self = .UnsupportedMediaType
      case 416: self = .RequestRangeNotSatisfiable
      case 417: self = .ExpectationFailed
      case 418: self = .IAmATeapot
      case 422: self = .UnprocessableEntity
      case 423: self = .Locked
      case 424: self = .FailedDependency
      case 425: self = .UnorderedCollection
      case 426: self = .UpgradeRequired
      case 428: self = .PreconditionRequired
      
      case 500: self = .InternalServerError
      case 501: self = .NotImplemented
      case 502: self = .BadGateway
      case 503: self = .ServiceUnavailable
      case 504: self = .GatewayTimeout
      case 505: self = .HTTPVersionNotSupported
      case 506: self = .VariantAlsoNegotiates
      case 507: self = .InsufficientStorage
      case 508: self = .LoopDetected
      case 510: self = .NotExtended
      
      // FIXME: complete me
      
      default:
        let statusText = text ?? HTTPStatus.text(forStatus: status)
        self = .Extension(status, statusText)
    }
  }
  
  public var status : Int {
    // You ask: How to maintain the reverse list of the above? Emacs macro!
  
    switch self {
      case .OK:                          return 200
      case .Created:                     return 201
      case .Accepted:                    return 202
      case .NoContent:                   return 204
      case .ResetContent:                return 205
      case .PartialContent:              return 206
      case .MultiStatus:                 return 207
      case .AlreadyReported:             return 208
      case .IMUsed:                      return 226 // RFC 3229
      
      case .MultipleChoices:             return 300
      case .MovedPermanently:            return 301
      case .Found:                       return 302
      case .SeeOther:                    return 303
      case .NotModified:                 return 304
      case .UseProxy:                    return 305
      case .SwitchProxy:                 return 306
      case .TemporaryRedirect:           return 307
      case .ResumeIncomplete:            return 308
      
      case .BadRequest:                  return 400
      case .Unauthorized:                return 401
      case .💰Required:                  return 402
      case .Forbidden:                   return 403
      case .NotFound:                    return 404
      case .MethodNotAllowed:            return 405
      case .NotAcceptable:               return 406
      case .ProxyAuthenticationRequired: return 407
      case .RequestTimeout:              return 408
      case .Conflict:                    return 409
      case .Gone:                        return 410
      case .LengthRequired:              return 411
      case .PreconditionFailed:          return 412
      case .RequestEntityTooLarge:       return 413
      case .RequestURITooLong:           return 414
      case .UnsupportedMediaType:        return 415
      case .RequestRangeNotSatisfiable:  return 416
      case .ExpectationFailed:           return 417
      case .IAmATeapot:                  return 418
      case .UnprocessableEntity:         return 422
      case .Locked:                      return 423
      case .FailedDependency:            return 424
      case .UnorderedCollection:         return 425
      case .UpgradeRequired:             return 426
      case .PreconditionRequired:        return 428
      
      case .InternalServerError:         return 500
      case .NotImplemented:              return 501
      case .BadGateway:                  return 502
      case .ServiceUnavailable:          return 503
      case .GatewayTimeout:              return 504
      case .HTTPVersionNotSupported:     return 505
      case .VariantAlsoNegotiates:       return 506
      case .InsufficientStorage:         return 507
      case .LoopDetected:                return 508
      case .NotExtended:                 return 510
      
      case .Extension(let code, _):      return code
    }
  }
  
  public var statusText : String {
    switch self {
      case .Extension(_, let text):
        return text
      default:
        return HTTPStatus.text(forStatus: self.status)
    }
  }
  
  public static func text(forStatus status: Int) -> String {
    // FIXME: complete me for type safety ;-)
    
    switch status {
      case 200: return "OK"
      case 201: return "Created"
      case 204: return "No Content"
      case 207: return "MultiStatus"
        
      case 400: return "Bad Request"
      case 401: return "Unauthorized"
      case 402: return "Payment Required"
      case 403: return "FORBIDDEN"
      case 404: return "NOT FOUND"
      case 405: return "Method not allowed"
        
      default:
        return "Status \(status)" // don't want an Optional here
    }
  }
  
}

extension HTTPStatus : CustomStringConvertible {
  
  public var description: String {
    return "\(status) \(statusText)"
  }
  
}

extension HTTPStatus : IntegerLiteralConvertible {
  // this allows: let status : HTTPStatus = 418
  
  public init(integerLiteral value: Int) {
    self.init(value)
  }
  
}

extension HTTPStatus : Hashable {

  public var hashValue: Int {
    return self.status
  }
  
}

public func ==(lhs: HTTPStatus, rhs: HTTPStatus) -> Bool {
  return lhs.status == rhs.status
}
