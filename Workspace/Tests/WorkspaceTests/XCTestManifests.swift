import XCTest

#if !canImport(ObjectiveC)
  public func allTests() -> [XCTestCaseEntry] {
    [
      testCase(WorkspaceTests.allTests),
    ]
  }
#endif
