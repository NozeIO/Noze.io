//
//  MustacheTests.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import mustache

public class PersonClass {
  
  var firstname : String
  var lastname  : String
  
  var name : String { return "\(firstname) \(lastname)" }
    // unsupported by reflection
  
  init(_ firstname: String, _ lastname: String) {
    self.firstname = firstname
    self.lastname  = lastname
  }
}

public struct PersonStruct {
  
  var firstname : String
  var lastname  : String
  var name : String { return "\(firstname) \(lastname)" }
    // unsupported by reflection
  
  init(_ firstname: String, _ lastname: String) {
    self.firstname = firstname
    self.lastname = lastname
  }
}

class MustacheTests: XCTestCase {
  
  let fixTaxTemplate =
    "Hello {{name}}\n" +
    "You have just won {{& value}} dollars!\n" +
    "{{#in_ca}}\n" +
    "Well, {{{taxed_value}}} dollars, after taxes." +
    "{{/in_ca}}\n" +
    "{{#addresses}}" +
    "  Has address in: {{city}}" +
    "{{/addresses}}" +
    "{{^addresses}}" +
    "Has NO addresses" +
    "{{/addresses}}" +
  ""
  let fixTaxTemplate2 = // same but no {{& x} inverted sections
    "Hello {{name}}\n" +
    "You have just won {{{value}}} dollars!\n" +
    "{{#in_ca}}\n" +
    "Well, {{{taxed_value}}} dollars, after taxes." +
    "{{/in_ca}}\n" +
    "{{#addresses}}" +
    "  Has address in: {{city}}" +
    "{{/addresses}}" +
    "{{^addresses}}" +
    "Has NO addresses" +
    "{{/addresses}}" +
  ""
  
  let baseTemplate =
    "<h2>Names</h2>\n" +
    "{{#names}}" +
    "  {{>     user}}\n" +
    "{{/names}}" +
  ""
  let userTemplate = "<strong>{{lastname}}</strong>"
  
  let fixDictChris : [ String : Any ] = [
    "name"        : "Ch<r>is",
    "value"       : 10000,
    "taxed_value" : Int(10000 - (10000 * 0.4)),
    "in_ca"       : true,
    "addresses"   : [
      [ "city"    : "Cupertino" ]
    ]
  ]
  
  let fixUsers = [
    [ "lastname": "Duck",  "firstname": "Donald"   ],
    [ "lastname": "Duck",  "firstname": "Dagobert" ],
    [ "lastname": "Mouse", "firstname": "Mickey"   ]
  ]
  let fixUsersClass = [
    PersonClass("Donald",   "Duck"),
    PersonClass("Dagobert", "Duck"),
    PersonClass("Mickey",   "Mouse")
  ]
  let fixUsersStruct = [
    PersonStruct("Donald",   "Duck"),
    PersonStruct("Dagobert", "Duck"),
    PersonStruct("Mickey",   "Mouse")
  ]
  
  let fixChrisResult =
    "Hello Ch&lt;r&gt;is\n" +
    "You have just won 10000 dollars!\n" +
    "\n" +
    "Well, 6000 dollars, after taxes." +
    "\n" +
    "" +
    "  Has address in: Cupertino" +
    "" +
  ""
  
  let fixFullNameKVCTemplate1 =
        "{{#persons}}{{firstname}} {{lastname}}\n{{/persons}}"
  let fixFullNameKVCResults1 = "Donald Duck\nDagobert Duck\nMickey Mouse\n"
  
  let fixLambdaTemplate1 =
    "{{#wrapped}}{{name}} is awesome.{{/wrapped}}"
  
  let fixLambda1 : [ String : Any ] = [
    "name"    : "Willy",
    "wrapped" : { ( text: String, render: ( String ) -> String ) -> String in
      return "<b>" + render(text) + "</b>"
    }
  ]
  let fixSimpleLambda1 : [ String : Any ] = [
    "name"    : "Willy",
    "wrapped" : { ( text: String ) -> String in return "<b>" + text + "</b>" }
  ]
  
  let fixLambda1Result       = "<b>Willy is awesome.</b>"
  let fixSimpleLambda1Result = "<b>{{name}} is awesome.</b>"
  let fixPartialResult1 =
    "<h2>Names</h2>\n" +
    "  <strong>Duck</strong>\n" +
    "  <strong>Duck</strong>\n" +
    "  <strong>Mouse</strong>\n"
  
  // MARK: - Tests

  func testDictKVC() throws {
    let v = KeyValueCoding.value(forKey: "name", inObject: fixDictChris)
    XCTAssertNotNil(v)
    if v != nil {
      XCTAssertTrue(v! is String)
      XCTAssertEqual(v as? String, "Ch<r>is")
    }
  }
  
  func testDictNumberKVC() throws {
    let v = KeyValueCoding.value(forKey: "value", inObject: fixDictChris)
    XCTAssertNotNil(v)
    if v != nil {
      XCTAssertTrue(v! is Int)
      XCTAssertEqual(v as? Int, 10000)
    }
  }
  
  func testSimpleMustacheDict() throws {
    let parser = MustacheParser()
    let tree   = parser.parse(string: fixTaxTemplate)
    let result = tree.render(object: fixDictChris)
    
    XCTAssertFalse(result.isEmpty)
    XCTAssertEqual(result, fixChrisResult)
  }
  
  func testTreeRendering() throws {
    let parser = MustacheParser()
    let tree   = parser.parse(string: fixTaxTemplate2)
    let result = tree.asMustacheString
    
    XCTAssertEqual(result, fixTaxTemplate2)
  }
  
  func testClassKVCRendering() {
    let parser = MustacheParser()
    let tree   = parser.parse(string: fixFullNameKVCTemplate1)
    let result = tree.render(object: ["persons": fixUsersClass])
    
    XCTAssertEqual(result, fixFullNameKVCResults1)
  }
  
  func testStructKVCRendering() {
    let parser = MustacheParser()
    let tree   = parser.parse(string: fixFullNameKVCTemplate1)
    let result = tree.render(object: ["persons": fixUsersClass])
    
    XCTAssertEqual(result, fixFullNameKVCResults1)
  }
  
  func testLambda() throws {
    let parser = MustacheParser()
    let tree   = parser.parse(string: fixLambdaTemplate1)
    let result = tree.render(object: fixLambda1)
    
    XCTAssertFalse(result.isEmpty)
    XCTAssertEqual(result, fixLambda1Result)
  }
  
  func testSimpleLambda() throws {
    let parser = MustacheParser()
    let tree   = parser.parse(string: fixLambdaTemplate1)
    let result = tree.render(object: fixSimpleLambda1)
    
    XCTAssertFalse(result.isEmpty)
    XCTAssertEqual(result, fixSimpleLambda1Result)
  }
  
  func testPartialParsing() throws {
    let parser = MustacheParser()
    let tree   = parser.parse(string: baseTemplate)
    
    XCTAssertNotNil(tree)
    // print("tree: \(tree)")
    // print("tree: \(tree.asMustacheString)")
  }
  
  
  // MARK: - Test Partials
  
  class TestCtx : MustacheDefaultRenderingContext {
    
    var nameToTemplate = [ String : String ]()
    
    override func retrievePartial(name n: String) -> MustacheNode? {
      guard let template = nameToTemplate[n] else { return nil }
      
      let parser = MustacheParser()
      let tree   = parser.parse(string: template)
      return tree
    }
    
  }
  
  func testPartial() throws {
    let parser = MustacheParser()
    let tree   = parser.parse(string: baseTemplate)

    let ctx = TestCtx(["names": fixUsers])
    ctx.nameToTemplate["base"] = baseTemplate
    ctx.nameToTemplate["user"] = userTemplate
    tree.render(inContext: ctx)
    let result = ctx.string
    
    //print("result: \(result)")
    XCTAssertNotNil(result)
    XCTAssertEqual(result, fixPartialResult1)
  }
  
  
#if os(Linux)
  static var allTests = {
    return [
      ( "testSimpleMustacheDict", testSimpleMustacheDict ),
    ]
  }()
#endif
}
