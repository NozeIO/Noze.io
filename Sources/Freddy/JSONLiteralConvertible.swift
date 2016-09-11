//
//  JSONLiteralConvertible.swift
//  Freddy
//
//  Created by Zachary Waldowski on 5/11/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

// MARK: - ExpressibleByArrayLiteral

extension JSON: ExpressibleByArrayLiteral {
    
    /// Create an instance by copying each element of the `collection` into a
    /// new `Array`.
    public init<C: Collection>(_ collection: C) 
           where C.Iterator.Element == JSON 
    {
        self = .Array(Swift.Array(collection))
    }
  
    /// Create an instance initialized with `elements`.
    public init(arrayLiteral elements: JSON...) {
        self.init(elements)
    }
    
}

// MARK: - ExpressibleByDictionaryLiteral

extension JSON: ExpressibleByDictionaryLiteral {
    
    /// Create an instance by copying each key/value pair of the `pairs` into
    /// a new `Dictionary`.
    public init<Dictionary: Sequence>(_ pairs: Dictionary)
           where Dictionary.Iterator.Element == (Swift.String, JSON)
    {
        let minCap = 16 // was: pairs.underestimateCount, which is not accessible
        var dictionary = Swift.Dictionary<Swift.String, JSON>(minimumCapacity: minCap)
        for (key, value) in pairs {
            dictionary[key] = value
        }
        self = .Dictionary(dictionary)
    }
  
    /// Create an instance initialized with `pairs`.
    public init(dictionaryLiteral pairs: (Swift.String, JSON)...) {
        self.init(pairs)
    }

}

// MARK: - ExpressibleByFloatLiteral

extension JSON: ExpressibleByFloatLiteral {
    
    /// Create an instance initialized to `Double` `value`.
    public init(_ value: Swift.Double) {
        self = .Double(value)
    }
    
    /// Create a literal instance initialized to `value`.
    public init(floatLiteral value: Swift.Double) {
        self.init(value)
    }

}

// MARK: - ExpressibleByIntegerLiteral

extension JSON: ExpressibleByIntegerLiteral {
    
    /// Create an instance initialized to `Int` by `value`.
    public init(_ value: Swift.Int) {
        self = .Int(value)
    }
    
    /// Create a literal instance initialized to `value`.
    public init(integerLiteral value: Swift.Int) {
        self.init(value)
    }

}

// MARK: - ExpressibleByStringLiteral

extension JSON: ExpressibleByStringLiteral {
    
    /// Create an instance initialized to `String` by `text`.
    public init(_ text: Swift.String) {
        self = .String(text)
    }

    /// Create a literal instance initialized to `value`.
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    /// Create a literal instance initialized to `value`.
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    /// Create a literal instance initialized to `value`.
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
    
}

// MARK: - ExpressibleByBooleanLiteral

extension JSON: ExpressibleByBooleanLiteral {

    /// Create an instance initialized to `Bool` by `value`.
    public init(_ value: Swift.Bool) {
        self = .Bool(value)
    }

    /// Create a literal instance initialized to `value`.
    public init(booleanLiteral value: Swift.Bool) {
        self.init(value)
    }

}

// MARK: - ExpressibleByNilLiteral

extension JSON: ExpressibleByNilLiteral {

    /// Create an instance initialized with `nil`.
    public init(nilLiteral: ()) {
        self = .Null
    }

}
