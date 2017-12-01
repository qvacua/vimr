//: Playground - noun: a place where people can play

import Cocoa
import NvimMsgPack

// Start nvim as follows:
// $ NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim $SOME_FILES
guard let nvim = Nvim(at: "/tmp/nvim.sock") else {
  preconditionFailure("Could not connect to nvim")
}

nvim.connect()

print(nvim.getVar(name: "cwd"))
