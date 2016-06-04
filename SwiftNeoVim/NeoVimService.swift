/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

public class NeoVimService {

  public private(set) var neoVims: [NeoVim] = []

  public func newNeoVim() -> NeoVim {
    let neoVim = NeoVim()
    self.neoVims.append(neoVim);

    return neoVim
  }
}