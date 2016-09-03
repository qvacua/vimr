/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import XCTest
import Nimble

class ScorerTest: XCTestCase {
  
  func testScore() {
    let pattern = "s/nvv"
    let targets = [
      "SwiftNeoVim/NeoVimView.swift",
      "build/Release/NeoVimServer.dSYM/Contents/Resources/DWARF/NeoVimServer"
    ]
    
    expect(Scorer.score(targets[0], pattern: pattern)).to(beGreaterThan(Scorer.score(targets[1], pattern: pattern)))
  }
}
