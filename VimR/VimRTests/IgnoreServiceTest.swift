/// Tae Won Ha - http://taewon.de - @hataewon
/// See LICENSE

import Nimble
import XCTest

class IgnoreServiceTest: XCTestCase {
  var base: URL!
  var service: IgnoreService!

  override func setUp() {
    self.base = Bundle(for: type(of: self)).url(
      forResource: "ignore-service-test",
      withExtension: nil,
      subdirectory: "Resources"
    )!
    self.service = IgnoreService(count: 100, root: self.base)

    super.setUp()
  }

  func testDeepest() {
    let ignoreAaa = self.service.ignore(for: self.base.appendingPathComponent("a/aa/aaa"))!

    expect(ignoreAaa.filters.count).to(beGreaterThanOrEqualTo(4))
    expect(ignoreAaa.filters[back: 0].pattern).to(equal("last-level"))
    expect(ignoreAaa.filters[back: 1].pattern).to(equal("level-aaa"))
    expect(ignoreAaa.filters[back: 2].pattern).to(equal("level-a"))
    expect(ignoreAaa.filters[back: 3].pattern).to(equal("root-level"))
  }

  func testWholeTree() {
    let ignoreBase = self.service.ignore(for: self.base)!
    let ignoreA = self.service.ignore(for: self.base.appendingPathComponent("a/"))!
    let ignoreAa = self.service.ignore(for: self.base.appendingPathComponent("a/aa/"))!
    let ignoreAaa = self.service.ignore(for: self.base.appendingPathComponent("a/aa/aaa"))!

    expect(ignoreBase.filters.count).to(beGreaterThanOrEqualTo(1))
    expect(ignoreBase.filters[back: 0].pattern).to(equal("root-level"))

    expect(ignoreA.filters.count).to(equal(ignoreBase.filters.count + 1))
    expect(ignoreA.filters[back: 0].pattern).to(equal("level-a"))
    expect(ignoreA.filters[back: 1].pattern).to(equal("root-level"))

    expect(ignoreAa).to(be(ignoreA))

    expect(ignoreAaa.filters.count).to(equal(ignoreAa.filters.count + 2))
    expect(ignoreAaa.filters[back: 0].pattern).to(equal("last-level"))
    expect(ignoreAaa.filters[back: 1].pattern).to(equal("level-aaa"))
    expect(ignoreAaa.filters[back: 2].pattern).to(equal("level-a"))
    expect(ignoreAaa.filters[back: 3].pattern).to(equal("root-level"))
  }
}

private extension BidirectionalCollection {
  subscript(back i: Int) -> Element { self[index(endIndex, offsetBy: -(i + 1))] }
}
