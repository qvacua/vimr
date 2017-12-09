//: Playground - noun: a place where people can play

import Cocoa
import NvimMsgPack

// Start nvim as follows:
// $ NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim $SOME_FILES
guard let nvim = NvimApi(at: "/tmp/nvim.sock") else {
  preconditionFailure("Could not connect to nvim")
}

nvim.connect()

if nvim.getMode().value?["blocking"]?.boolValue == true {
  print("blocked!")
} else {
  print("not blocked!")
}

print(nvim.getMode())

nvim.listBufs().value?.forEach { buf in
    print(nvim.bufGetOption(buffer: buf, name: "buflisted", checkBlocked: false))
}
let curBuf = nvim.getCurrentBuf().value!
print(nvim.bufGetOption(buffer: curBuf, name: "buflisted", checkBlocked: false))
