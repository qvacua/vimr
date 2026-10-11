import Foundation
import NvimApi
import Testing

@Test func invalidUtf8MessageFinishesPipeStream() async throws {
  let rpc = MsgpackRpc()
  let inPipe = Pipe()
  let outPipe = Pipe()
  let errorPipe = Pipe()
  let messages = await rpc.messagesStream

  try await rpc.run(inPipe: inPipe, outPipe: outPipe, errorPipe: errorPipe)
  try outPipe.fileHandleForWriting.write(contentsOf: Data([0x91, 0xa1, 0xff]))

  let streamClosed = await withTaskGroup(of: Bool.self) { group in
    group.addTask {
      for await _ in messages {}
      return true
    }
    group.addTask {
      try? await Task.sleep(for: .seconds(1))
      return false
    }

    let result = await group.next() ?? false
    group.cancelAll()
    return result
  }

  await rpc.stop()
  #expect(streamClosed)
}
