/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble

class ScorerTest: XCTestCase {

  func testScore1() {
    let pattern = "sw/nvv".replacingOccurrences(of: "/", with: "")
    let targets = [
      "SwiftNeoVim/NeoVimView.swift",
      "build/Release/NeoVimServer.dSYM/Contents/Resources/DWARF/NeoVimServer",
    ].map { $0.replacingOccurrences(of: "/", with: "") }
    
    expect(Scorer.score(targets[0], pattern: pattern)).to(beGreaterThan(Scorer.score(targets[1], pattern: pattern)))
  }
  
  func testScore2() {
    let pattern = "nvv"
    let targets = [
      "NeoVimView.swift",
      "NeoVimViewDelegate.swift",
      "NeoVimAgent",
    ]

    expect(Scorer.score(targets[0], pattern: pattern)).to(beGreaterThan(Scorer.score(targets[1], pattern: pattern)))
    expect(Scorer.score(targets[1], pattern: pattern)).to(beGreaterThan(Scorer.score(targets[2], pattern: pattern)))
  }
}
