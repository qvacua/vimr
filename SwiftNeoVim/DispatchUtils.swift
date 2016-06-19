//
//  DispatchUtils.swift
//  nvox
//
//  Created by Tae Won Ha on 19/06/16.
//  Copyright © 2016 Tae Won Ha. All rights reserved.
//

import Foundation

public class DispatchUtils {
  
  private static let qDispatchMainQueue = dispatch_get_main_queue()
  
  public static func gui(call: () -> Void) {
    dispatch_async(DispatchUtils.qDispatchMainQueue, call)
  }
}