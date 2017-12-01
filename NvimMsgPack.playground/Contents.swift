//: Playground - noun: a place where people can play

import Cocoa
import NvimMsgPack

// Start nvim as follows:
// $ NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim $SOME_FILES
guard let nvim = Nvim(at: "/tmp/nvim.sock") else {
  preconditionFailure("Could not connect to nvim")
}

nvim.connect()

if nvim.getMode().value?.dictionaryValue?[.string("blocked")]?.boolValue == true {
  print("blocked!")
} else {
  print("not blocked!")
}

print(nvim.getMode())
