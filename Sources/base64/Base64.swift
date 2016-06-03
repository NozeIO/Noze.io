// Base64.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// FIXME(hh): The implementation is a little, well. OK. It does its job :-)
//            Replace it later.
// TODO:
// - use ptrs
// - this is a byte-to-byte transformation

public struct Base64 {

  public static func decode(string s: String) -> [UInt8] {
    return decode(data: Array(s.utf8))
  }
  
  public static func decode(data input: [UInt8]) -> [UInt8] {
    // FIXME: this should be a generic method
    var decoded     = [UInt8]() // TODO: reserve capacity
    var unreadBytes = 0
    
    for b in input {
      if ascii[Int(b)] > 63 {
        break
      }
      
      unreadBytes += 1
    }
    
    func byte(at index: Int) -> Int {
      return Int(input[index])
    }
    
    // let encodedBytes = string.utf8.map { Int($0) }
    var index = 0
    
    while unreadBytes > 4 {
      let c0 = ascii[byte(at: index + 0)] << 2 | ascii[byte(at: index + 1)] >> 4
      let c1 = ascii[byte(at: index + 1)] << 4 | ascii[byte(at: index + 2)] >> 2
      let c2 = ascii[byte(at: index + 2)] << 6 | ascii[byte(at: index + 3)]
      decoded.append(c0)
      decoded.append(c1)
      decoded.append(c2)
      index       += 4
      unreadBytes -= 4
    }
    
    if unreadBytes > 1 {
      let c0 = ascii[byte(at: index + 0)] << 2 | ascii[byte(at: index + 1)] >> 4
      decoded.append(c0)
    }
    
    if unreadBytes > 2 {
      let c1 = ascii[byte(at: index + 1)] << 4 | ascii[byte(at: index + 2)] >> 2
      decoded.append(c1)
    }
    
    if unreadBytes > 3 {
      let c2 = ascii[byte(at: index + 2)] << 6 | ascii[byte(at: index + 3)]
      decoded.append(c2)
    }
    
    return decoded
  }
  
  public static func encode(data d: [UInt8], specialChars: String = "+/",
                            paddingChar: Character? = "=") -> String
  {
    let data = d
    let base64 = base64Chars + specialChars
    var encoded: String = ""
    
    func appendCharacterFromBase(idx character: Int) {
      #if swift(>=3.0) // #swift3-fd
        let idx = base64.index(base64.startIndex, offsetBy: character)
      #else
        let idx = base64.startIndex.advancedBy(character)
      #endif
      encoded.append(base64[idx])
    }
    
    func byte(at index: Int) -> Int {
      return Int(data[index])
    }
    
    let decodedBytes = data.map { Int($0) }
    
    var i = 0
    
    while i < decodedBytes.count - 2 {
      let c0 = ( byte(at: i) >> 2) & 0x3F
      let c1 = ((byte(at: i)       & 0x3) << 4) | ((byte(at: i + 1) & 0xF0) >> 4)
      let c2 = ((byte(at: i + 1)   & 0xF) << 2) | ((byte(at: i + 2) & 0xC0) >> 6)
      let c3 =   byte(at: i + 2)   & 0x3F
      appendCharacterFromBase(idx: c0)
      appendCharacterFromBase(idx: c1)
      appendCharacterFromBase(idx: c2)
      appendCharacterFromBase(idx: c3)
      i += 3
    }
    
    if i < decodedBytes.count {
      let c0 = (byte(at: i) >> 2) & 0x3F
      appendCharacterFromBase(idx: c0)
      
      if i == decodedBytes.count - 1 {
        let c1 = ((byte(at: i) & 0x3) << 4)
        appendCharacterFromBase(idx: c1)
        if let paddingChar = paddingChar {
          encoded.append(paddingChar)
        }
      } else {
        let c1 = ((byte(at: i)     & 0x3) << 4) | ((byte(at: i + 1) & 0xF0) >> 4)
        let c2 = ((byte(at: i + 1) & 0xF) << 2)
        appendCharacterFromBase(idx: c1)
        appendCharacterFromBase(idx: c2)
      }
      
      if let paddingChar = paddingChar {
        encoded.append(paddingChar)
      }
    }
    
    return encoded
  }
  
  public static func urlSafeEncode(data d: [UInt8]) -> String {
    return Base64.encode(data: d, specialChars: "-_", paddingChar: nil)
  }
}

private let base64Chars =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

private let ascii: [UInt8] = [
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 62, 64, 63,
  52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
  64, 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14,
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 63,
  64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
  41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
]
