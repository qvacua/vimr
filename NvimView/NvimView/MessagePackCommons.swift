//
// Created by Tae Won Ha on 10.05.18.
// Copyright (c) 2018 Tae Won Ha. All rights reserved.
//

import Foundation
import MessagePack

extension MessagePackValue {

  var intValue: Int? {
    guard let i64 = self.integerValue else {
      return nil
    }

    return Int(i64)
  }
}
