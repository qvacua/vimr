/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation
import os

class FuzzySearchFileMonitor {

  static let fileSystemEventsLatency = 1.0

  private(set) var urlToMonitor = FileUtils.userHomeUrl

  func monitor(url: URL, eventHandler: (@escaping (URL) -> Void)) throws {
    self.stopMonitor()
    self.urlToMonitor = url
    self.monitor = try EonilFSEventStream(
      pathsToWatch: [urlToMonitor.path],
      sinceWhen: EonilFSEventsEventID.getCurrentEventId(),
      latency: FuzzySearchFileMonitor.fileSystemEventsLatency,
      flags: [],
      handler: { [weak self] event in
        if event.flag == .historyDone {
          self?.log.info("Not firing first event (.historyDone): \(event)")
          return
        }

        eventHandler(URL(fileURLWithPath: event.path))
      }
    )
    self.monitor?.setDispatchQueue(globalFileMonitorQueue)

    try self.monitor?.start()
    self.log.info("Started monitoring \(self.urlToMonitor)")
  }

  deinit { stopMonitor() }

  private func stopMonitor() {
    self.monitor?.stop()
    self.monitor?.invalidate()
  }

  private var monitor: EonilFSEventStream?

  private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.service)
}

private let globalFileMonitorQueue = DispatchQueue.global(qos: .userInitiated)
