/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Commons
import EonilFSEvents
import Foundation
import os

// TODO: Think about producing an AsyncStream of events
// actors cannot have deinit where we want to stop the FSStream.
final class FileMonitor: @unchecked Sendable {
  static let fileSystemEventsLatency = 1.0

  private(set) var urlToMonitor = FileUtils.userHomeUrl

  func monitor(url: URL, eventHandler: @Sendable @escaping (URL) -> Void) throws {
    self.monitorLock.lock()
    defer { self.monitorLock.unlock() }

    self.stopMonitor()
    self.urlToMonitor = url
    self.monitor = try EonilFSEventStream(
      pathsToWatch: [self.urlToMonitor.path],
      sinceWhen: EonilFSEventsEventID.getCurrentEventId(),
      latency: FileMonitor.fileSystemEventsLatency,
      flags: [],
      handler: { event in
        if event.flag == .historyDone {
          dlog.debug("Not firing first event (.historyDone): \(event)")
          return
        }
        let url = URL(fileURLWithPath: event.path)

        eventHandler(url)
      }
    )
    self.monitor?.setDispatchQueue(self.queue)

    try self.monitor?.start()
    dlog.debug("Started monitoring \(self.urlToMonitor)")
  }

  deinit { stopMonitor() }

  private func stopMonitor() {
    self.monitor?.stop()
    self.monitor?.invalidate()
  }

  private var monitor: EonilFSEventStream?
  private let monitorLock = OSAllocatedUnfairLock()

  private let queue = DispatchQueue(
    label: String(reflecting: FileMonitor.self) + "-\(UUID())",
    qos: .userInitiated,
    target: .global(qos: .userInitiated)
  )
}
