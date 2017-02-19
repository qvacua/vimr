/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import EonilFileSystemEvents

fileprivate let fileSystemEventsLatency = 2.0
fileprivate let monitorDispatchQueue = DispatchQueue.global(qos: .userInitiated)

class FileMonitor: UiComponent {

  typealias StateType = AppState

  enum Action {

    case change(in : URL)
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emitter = emitter

    source
      .subscribe(onNext: { [unowned self] appState in
        let urlsToMonitor = Set(appState.mainWindows.map { $1.cwd })

        let newUrls = urlsToMonitor.subtracting(self.monitoredUrls)
        let obsoleteUrls = self.monitoredUrls.subtracting(urlsToMonitor)

        newUrls.forEach { url in
          NSLog("adding \(url) to monitoring")
          self.monitoredUrls.insert(url)

          let path = url.path
          // FIXME: Handle EonilFileSystemEventFlag.RootChanged, ie watchRoot: true
          let monitor = FileSystemEventMonitor(pathsToWatch: [path],
                                               latency: fileSystemEventsLatency,
                                               watchRoot: false,
                                               queue: monitorDispatchQueue)
          { [unowned self] events in
            let urls = events.map { URL(fileURLWithPath: $0.path) }
            let parent = FileUtils.commonParent(of: urls)

            self.emitter.emit(Action.change(in: parent))
          }

          self.monitors[url] = monitor
        }

        obsoleteUrls.forEach { url in
          NSLog("removing \(url) from monitoring")
          self.monitoredUrls.remove(url)
          self.monitors.removeValue(forKey: url)
        }
      })
      .addDisposableTo(self.disposeBag)
  }

  fileprivate let emitter: ActionEmitter
  fileprivate let disposeBag = DisposeBag()

  fileprivate var monitoredUrls = Set<URL>()
  fileprivate var monitors = [URL: FileSystemEventMonitor]()
}
