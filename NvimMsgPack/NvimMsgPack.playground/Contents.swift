//: Playground - noun: a place where people can play

import Cocoa
import NvimMsgPack

// Start nvim as follows:
// $ NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim $SOME_FILES
guard let nvim = NvimApi(at: "/tmp/nvim.sock") else {
  preconditionFailure("Could not connect to nvim")
}

try? nvim.connect()

nvim.rpc(method: "nvim_buf_get_option", params: [], expectsReturnValue: true)
nvim.listBufs()
