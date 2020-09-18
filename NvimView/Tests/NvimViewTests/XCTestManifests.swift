import XCTest

#if !canImport(ObjectiveC)
  public func allTests() -> [XCTestCaseEntry] {
    [
      testCase(NvimViewTests.allTests),
    ]
  }
#endif
