//
// Created by Tae Won Ha on 25.08.18.
// Copyright (c) 2018 Tae Won Ha. All rights reserved.
//

import Foundation

struct FontTrait: OptionSet {

  let rawValue: UInt

  static let italic = FontTrait(rawValue: 1 << 0)
  static let bold = FontTrait(rawValue: 1 << 1)
  static let underline = FontTrait(rawValue: 1 << 2)
  static let undercurl = FontTrait(rawValue: 1 << 3)
}
