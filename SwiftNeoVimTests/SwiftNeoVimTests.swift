//
//  SwiftNeoVimTests.swift
//  SwiftNeoVimTests
//
//  Created by Tae Won Ha on 03/07/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

import XCTest
import Quick
import Nimble
@testable import SwiftNeoVim

class GridSpec: QuickSpec {

  override func spec() {
    describe("something") {
      it("does things") {
        let g = Grid()
        expect(g.foreground).to(equal(qDefaultForeground))
      }
    }
  }
}
