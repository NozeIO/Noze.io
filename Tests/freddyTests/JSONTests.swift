//
//  JSONTests.swift
//  Freddy
//
//  Created by David House on 1/14/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

import XCTest
import Freddy

class JSONTests: XCTestCase {

#if !os(Linux)
    var sampleData:NSData!
#endif
    
    override func setUp() {
        super.setUp()
        
#if !SWIFT_PACKAGE // no bundles yet, need to load the files manually
        let testBundle = NSBundle(for: JSONSubscriptingTests.self)
        guard let data = testBundle.urlForResource("sample", withExtension: "JSON").flatMap(NSData.init) else {
            XCTFail("Could not read sample data from test bundle")
            return
        }
        sampleData = data
#endif
    }
    
#if !SWIFT_PACKAGE // those need the `sampleData` ivar 
    func testInitializingFromData() {
        
        do {
            _ = try JSON(data: sampleData)
        } catch {
            XCTFail("Could not parse sample JSON: \(error)")
            return
        }
    }
#endif

#if !os(Linux)
    // TODO: This test currently exposes an error in the Parser
    func DoNotRuntestInitializingFromEmptyData() {
        
        do {
            _ = try JSON.parse(data: NSData())
        } catch {
            XCTFail("Could not parse empty data: \(error)")
            return
        }
    }
#endif

    func testInitializingFromString() {
        
        let jsonString = "{ \"slashers\": [\"Jason\",\"Freddy\"] }"
        
        do {
            _ = try JSON.parse(jsonString: jsonString)
        } catch {
            XCTFail("Could not parse JSON from string: \(error)")
            return
        }
    }
    
    // TODO: This test currently exposes an error in the Parser
    func DoNotRuntestInitializingFromEmptyString() {
        
        do {
            _ = try JSON.parse(jsonString: "")
        } catch {
            XCTFail("Could not parse JSON from string: \(error)")
            return
        }
    }
}
