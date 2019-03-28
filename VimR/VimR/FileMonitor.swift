/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import os

private let monitorDispatchQueue = DispatchQueue.global(qos: .userInitiated)

class FileMonitor: UiComponent {

  typealias StateType = AppState

  enum Action {

    case change(in : URL)
  }

  static let fileSystemEventsLatency = 1.0

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()

    source
      .subscribe(onNext: { [unowned self] appState in
        let urlsToMonitor = Set(appState.mainWindows.map { $1.cwd })

        let newUrls = urlsToMonitor.subtracting(self.monitoredUrls)
        let obsoleteUrls = self.monitoredUrls.subtracting(urlsToMonitor)

        newUrls.forEach { url in
          self.log.info("Adding \(url) to monitoring")
          self.monitoredUrls.insert(url)

          let path = url.path

          // FIXME: Handle EonilFileSystemEventFlag.RootChanged, ie watchRoot: true
          do {
            let monitor = try EonilFSEventStream(
              pathsToWatch: [path],
              sinceWhen: EonilFSEventsEventID.getCurrentEventId(),
              latency: FileMonitor.fileSystemEventsLatency,
              flags: [],
              handler: { [weak self] event in
                let url = URL(fileURLWithPath: event.path)
                let parent = FileUtils.commonParent(of: [url])

                self?.emit(.change(in: parent))
              })
            monitor.setDispatchQueue(monitorDispatchQueue)
            try monitor.start()
            self.monitors[url] = monitor
          } catch {
            self.log.error("Could not start file monitor for \(path): "
                           + "\(error)")
          }
        }

        obsoleteUrls.forEach { url in
          self.log.info("Removing \(url) from monitoring")
          self.monitoredUrls.remove(url)

          self.monitors[url]?.stop()
          self.monitors[url]?.invalidate()
          self.monitors.removeValue(forKey: url)
        }
      })
      .disposed(by: self.disposeBag)
  }

  deinit {
    self.monitors.values.forEach { monitor in
      monitor.stop()
      monitor.invalidate()
    }
  }

  private let emit: (Action) -> Void
  private let disposeBag = DisposeBag()

  private var monitoredUrls = Set<URL>()
  private var monitors = [URL: EonilFSEventStream]()

  private let log = OSLog(subsystem: Defs.loggerSubsystem,
                          category: Defs.LoggerCategory.uiComponents)
}
