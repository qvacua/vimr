/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Foundation
import Testing
@testable import NvimApi

struct DictionaryExtensionTests {
  @Test func testMapToDict() {
    let input = ["a": 1, "b": 2, "c": 3]
    
    let result = input.mapToDict { key, value in
      (key.uppercased(), value * 2)
    }
    
    #expect(result == ["A": 2, "B": 4, "C": 6])
  }
  
  @Test func testMapToDictWithTypeConversion() {
    let input = [1: "one", 2: "two", 3: "three"]
    
    let result = input.mapToDict { key, value in
      (value, key)
    }
    
    #expect(result == ["one": 1, "two": 2, "three": 3])
  }
  
  @Test func testMapToDictEmpty() {
    let input: [String: Int] = [:]
    
    let result = input.mapToDict { key, value in
      (key, value)
    }
    
    #expect(result.isEmpty)
  }
  
  @Test func testCompactMapToDict() {
    let input = ["a": 1, "b": 2, "c": 3, "d": 4]
    
    let result = input.compactMapToDict { key, value -> (String, Int)? in
      guard value % 2 == 0 else { return nil }
      return (key.uppercased(), value * 2)
    }
    
    #expect(result == ["B": 4, "D": 8])
  }
  
  @Test func testCompactMapToDictAllNil() {
    let input = ["a": 1, "b": 3, "c": 5]
    
    let result = input.compactMapToDict { key, value -> (String, Int)? in
      return nil
    }
    
    #expect(result.isEmpty)
  }
  
  @Test func testCompactMapToDictTypeConversion() {
    let input = ["1": "one", "2": "two", "invalid": "three"]
    
    let result = input.compactMapToDict { key, value -> (Int, String)? in
      guard let intKey = Int(key) else { return nil }
      return (intKey, value)
    }
    
    #expect(result == [1: "one", 2: "two"])
  }
  
  @Test func testCompactMapToDictEmpty() {
    let input: [String: Int] = [:]
    
    let result = input.compactMapToDict { key, value -> (String, Int)? in
      (key, value)
    }
    
    #expect(result.isEmpty)
  }
}
