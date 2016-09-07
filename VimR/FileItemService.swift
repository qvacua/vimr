/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import EonilFileSystemEvents

func == (left: Token, right: Token) -> Bool {
  return left === right
}

class Token: Equatable {}

class FileItemService {

  private(set) var ignorePatterns: Set<FileItemIgnorePattern> = [] {
    didSet {
      self.ignoreToken = Token()
    }
  }

  /// Used to cache fnmatch calls in `FileItem`.
  private var ignoreToken = Token()

  /// When at least this much of non-directory and visible files are scanned, they are emitted.
  private let emitChunkSize = 1000

  private let scanDispatchQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
  private let monitorDispatchQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)

  private let root = FileItem(NSURL(fileURLWithPath: "/", isDirectory: true))

  private let fileSystemEventsLatency = Double(2)
  private var monitors = [NSURL: FileSystemEventMonitor]()
  private var monitorCounter = [NSURL: Int]()
  
  private let workspace = NSWorkspace.sharedWorkspace()
  private let iconsCache = NSCache()

  private var spinLock = OS_SPINLOCK_INIT
  
  init() {
    self.iconsCache.countLimit = 2000
    self.iconsCache.name = "icon-cache"
  }

  func set(ignorePatterns patterns: Set<FileItemIgnorePattern>) {
    self.ignorePatterns = patterns
  }
  
  func icon(forUrl url: NSURL) -> NSImage? {
    guard let path = url.path else {
      return nil
    }
    
    let icon = workspace.iconForFile(path)
    icon.size = CGSize(width: 16, height: 16)
    self.iconsCache.setObject(icon, forKey: url)
    
    return icon
  }

  func monitor(url url: NSURL) {
    guard let path = url.path else {
      return
    }

    // FIXME: Handle EonilFileSystemEventFlag.RootChanged, ie watchRoot: true
    let monitor = FileSystemEventMonitor(pathsToWatch: [path],
                                         latency: self.fileSystemEventsLatency,
                                         watchRoot: false,
                                         queue: self.monitorDispatchQueue)
    { [unowned self] events in
      let urls = events.map { NSURL(fileURLWithPath: $0.path) }
      let parent = FileUtils.commonParent(ofUrls: urls)
      self.fileItem(forUrl: parent)?.needsScanChildren = true
    }

    self.monitors[url] = monitor
    if let counter = self.monitorCounter[url] {
      self.monitorCounter[url] = counter + 1
    } else {
      self.monitorCounter[url] = 1
    }
  }

  func unmonitor(url url: NSURL) {
    guard let counter = self.monitorCounter[url] else {
      return
    }

    let newCounter = counter - 1
    if newCounter > 0 {
      self.monitorCounter[url] = newCounter
    } else {
      self.monitorCounter.removeValueForKey(url)
      self.monitors.removeValueForKey(url)

      // TODO Remove cached items more aggressively?
      let hasRelations = self.monitors.keys.reduce(false) { (result, monitoredUrl) in
        return result ? result : monitoredUrl.parent(ofUrl: url) || url.parent(ofUrl: monitoredUrl)
      }

      if hasRelations {
        return
      }

      self.parentFileItem(ofUrl: url).removeChild(withUrl: url)
    }
  }

  private func parentFileItem(ofUrl url: NSURL) -> FileItem {
    return self.fileItem(forPathComponents: Array(url.pathComponents!.dropLast()))!
  }

  func flatFileItems(ofUrl url: NSURL) -> Observable<[FileItem]> {
    guard url.fileURL else {
      return Observable.empty()
    }

    guard FileUtils.fileExistsAtUrl(url) else {
      return Observable.empty()
    }

    guard let pathComponents = url.pathComponents else {
      return Observable.empty()
    }

    return Observable.create { [unowned self] observer in
      let cancel = AnonymousDisposable {
        // noop
      }

      dispatch_async(self.scanDispatchQueue) { [unowned self] in
        guard let targetItem = self.fileItem(forPathComponents: pathComponents) else {
          observer.onCompleted()
          return
        }

        var flatNewFileItems: [FileItem] = []

        var dirStack: [FileItem] = [targetItem]
        while let curItem = dirStack.popLast() {
          if cancel.disposed {
            observer.onCompleted()
            return
          }

          if !curItem.childrenScanned || curItem.needsScanChildren {
            self.scanChildren(curItem)
          }

          curItem.children
            .filter { item in
              if item.hidden {
                return false
              }

              // This item already has been fnmatch'ed, thus return the cached value.
              if item.ignoreToken == self.ignoreToken {
                return !item.ignore
              }

              item.ignoreToken = self.ignoreToken
              item.ignore = false

              let path = item.url.path!
              for pattern in self.ignorePatterns {
                // We don't use `String.FnMatchOption.leadingDir` (`FNM_LEADING_DIR`) for directories since we do not
                // scan ignored directories at all when filtering. For example "*/.git" would create a `FileItem`
                // for `/some/path/.git`, but not scan its children when we filter.
                if pattern.match(absolutePath: path) {
                  item.ignore = true
                  return false
                }
              }

              return true
            }
            .forEach { $0.dir ? dirStack.append($0) : flatNewFileItems.append($0) }

          if flatNewFileItems.count >= self.emitChunkSize {
            observer.onNext(flatNewFileItems)
            flatNewFileItems = []
          }
        }

        if !cancel.disposed {
          observer.onNext(flatNewFileItems)
          observer.onCompleted()
        }
      }

      return cancel
    }
  }

  private func fileItem(forUrl url: NSURL) -> FileItem? {
    guard let pathComponents = url.pathComponents else {
      return nil
    }

    return self.fileItem(forPathComponents: pathComponents)
  }

  /// Returns the `FileItem` corresponding to the `pathComponents` parameter. This is like mkdir -p, i.e. it
  /// instantiates the intermediate `FileItem`s.
  ///
  /// - returns: `FileItem` corresponding to `pathComponents`. `nil` if the file does not exist.
  private func fileItem(forPathComponents pathComponents: [String]) -> FileItem? {
    let result = pathComponents.dropFirst().reduce(self.root) { (resultItem, childName) -> FileItem? in
      guard let parent = resultItem else {
        return nil
      }

      return self.child(withName: childName, ofParent: parent, create: true)
    }

    return result
  }

  /// Even when the result is nil it does not mean that there's no child with the given name. It could well be that
  /// it's not been scanned yet. However, if `create` parameter was true and `nil` is returned, the requested
  /// child does not exist.
  ///
  /// - parameters:
  ///   - name: name of the child to get.
  ///   - parent: parent of the child.
  ///   - create: whether to create the child `FileItem` if it's not scanned yet.
  /// - returns: child `FileItem` or nil.
  private func child(withName name: String, ofParent parent: FileItem, create: Bool = false) -> FileItem? {
    let filteredChildren = parent.children.filter { $0.url.lastPathComponent == name }

    if filteredChildren.isEmpty && create {
      let childUrl = parent.url.URLByAppendingPathComponent(name)

      guard FileUtils.fileExistsAtUrl(childUrl) else {
        return nil
      }

      let child = FileItem(childUrl)
      self.syncAddChildren { parent.children.append(child) }

      return child
    }

    return filteredChildren.first
  }
  
  private func scanChildren(item: FileItem) {
    let children = FileUtils.directDescendants(item.url).map(FileItem.init)
    self.syncAddChildren { item.children = children }

    item.childrenScanned = true
    item.needsScanChildren = false
  }

  private func syncAddChildren(@noescape fn: () -> Void) {
    OSSpinLockLock(&self.spinLock)
    fn()
    OSSpinLockUnlock(&self.spinLock)
  }
}
