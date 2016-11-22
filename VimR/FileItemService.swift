/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift
import EonilFileSystemEvents

enum FileItemServiceChange {

  case childrenChanged(root: URL, fileItem: FileItem?)
}

class FileItemService: StandardFlow {

  /// Used to cache fnmatch calls in `FileItem`.
  fileprivate var ignoreToken = Token()

  /// When at least this much of non-directory and visible files are scanned, they are emitted.
  fileprivate let emitChunkSize = 1000

  fileprivate let scanDispatchQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
  fileprivate let monitorDispatchQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)

  fileprivate let root = FileItem(URL(fileURLWithPath: "/", isDirectory: true))

  fileprivate let fileSystemEventsLatency = Double(2)
  fileprivate var monitors = [URL: FileSystemEventMonitor]()
  fileprivate var monitorCounter = [URL: Int]()

  fileprivate let workspace = NSWorkspace.shared()
  fileprivate let iconsCache = NSCache<NSURL, NSImage>()

  fileprivate var spinLock = OS_SPINLOCK_INIT

  // MARK: - API
  fileprivate(set) var ignorePatterns: Set<FileItemIgnorePattern> = [] {
    didSet {
      self.ignoreToken = Token()
    }
  }

  override init(source: Observable<Any>) {
    super.init(source: source)

    self.iconsCache.countLimit = 2000
    self.iconsCache.name = "icon-cache"
  }

  func set(ignorePatterns patterns: Set<FileItemIgnorePattern>) {
    self.ignorePatterns = patterns
  }

  func icon(forType type: String) -> NSImage {
    return self.workspace.icon(forFileType: type)
  }

  func icon(forUrl url: URL) -> NSImage? {
    if let cached = self.iconsCache.object(forKey: url as NSURL) {
      return cached
    }

    let path = url.path
    let icon = workspace.icon(forFile: path)
    icon.size = CGSize(width: 16, height: 16)
    self.iconsCache.setObject(icon, forKey: url as NSURL)

    return icon
  }

  func monitor(url: URL) {
    let path = url.path

    // FIXME: Handle EonilFileSystemEventFlag.RootChanged, ie watchRoot: true
    let monitor = FileSystemEventMonitor(pathsToWatch: [path],
                                         latency: self.fileSystemEventsLatency,
                                         watchRoot: false,
                                         queue: self.monitorDispatchQueue)
    { [unowned self] events in
      let urls = events.map { URL(fileURLWithPath: $0.path) }
      let parent = FileUtils.commonParent(of: urls)

      let parentItem = self.fileItem(for: parent)

      parentItem?.needsScanChildren = true
      self.publish(event: FileItemServiceChange.childrenChanged(root: url, fileItem: parentItem))
    }

    self.monitors[url] = monitor
    if let counter = self.monitorCounter[url] {
      self.monitorCounter[url] = counter + 1
    } else {
      self.monitorCounter[url] = 1
    }
  }

  func unmonitor(url: URL) {
    guard let counter = self.monitorCounter[url] else {
      return
    }

    let newCounter = counter - 1
    if newCounter > 0 {
      self.monitorCounter[url] = newCounter
    } else {
      self.monitorCounter.removeValue(forKey: url)
      self.monitors.removeValue(forKey: url)

      // TODO Remove cached items more aggressively?
      let hasRelations = self.monitors.keys.reduce(false) { (result, monitoredUrl) in
        return result ? result : monitoredUrl.isParent(of: url) || url.isParent(of: monitoredUrl)
      }

      if hasRelations {
        return
      }

      self.parentFileItem(of: url).removeChild(withUrl: url)
    }
  }

  func flatFileItems(ofUrl url: URL) -> Observable<[FileItem]> {
    guard url.isFileURL else {
      return Observable.empty()
    }

    guard FileUtils.fileExistsAtUrl(url) else {
      return Observable.empty()
    }

    let pathComponents = url.pathComponents
    return Observable.create { [unowned self] observer in
      let cancel = Disposables.create {
        // noop
      }

      self.scanDispatchQueue.async { [unowned self] in
        guard let targetItem = self.fileItem(for: pathComponents) else {
          observer.onCompleted()
          return
        }

        var flatNewFileItems: [FileItem] = []

        var dirStack: [FileItem] = [targetItem]
        while let curItem = dirStack.popLast() {
          if cancel.isDisposed {
            observer.onCompleted()
            return
          }

          if !curItem.childrenScanned || curItem.needsScanChildren {
            self.scanChildren(curItem)
          }

          curItem.children
            .filter { item in
              if item.isHidden || item.isPackage {
                return false
              }

              // This item already has been fnmatch'ed, thus return the cached value.
              if item.ignoreToken == self.ignoreToken {
                return !item.ignore
              }

              item.ignoreToken = self.ignoreToken
              item.ignore = false

              let path = item.url.path
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
            .forEach { $0.isDir ? dirStack.append($0) : flatNewFileItems.append($0) }

          if flatNewFileItems.count >= self.emitChunkSize {
            observer.onNext(flatNewFileItems)
            flatNewFileItems = []
          }
        }

        if !cancel.isDisposed {
          observer.onNext(flatNewFileItems)
          observer.onCompleted()
        }
      }

      return cancel
    }
  }

  /// Returns the `FileItem` corresponding to the `url` parameter with children. This is like mkdir -p, i.e. it
  /// instantiates the intermediate `FileItem`s.
  ///
  /// - returns: `FileItem` corresponding to `url` with children. `nil` if the file does not exist.
  func fileItemWithChildren(for url: URL) -> FileItem? {
    guard let fileItem = self.fileItem(for: url) else {
      return nil
    }

    if !fileItem.childrenScanned || fileItem.needsScanChildren {
      self.scanChildren(fileItem)
    }

    return fileItem
  }

  // FIXME: what if root?
  fileprivate func parentFileItem(of url: URL) -> FileItem {
    return self.fileItem(for: Array(url.pathComponents.dropLast()))!
  }

  /// Returns the `FileItem` corresponding to the `url` parameter. This is like mkdir -p, i.e. it
  /// instantiates the intermediate `FileItem`s. The children of the result may be empty.
  ///
  /// - returns: `FileItem` corresponding to `pathComponents`. `nil` if the file does not exist.
  fileprivate func fileItem(for url: URL) -> FileItem? {
    let pathComponents = url.pathComponents
    return self.fileItem(for: pathComponents)
  }

  /// Returns the `FileItem` corresponding to the `pathComponents` parameter. This is like mkdir -p, i.e. it
  /// instantiates the intermediate `FileItem`s. The children of the result may be empty.
  ///
  /// - returns: `FileItem` corresponding to `pathComponents`. `nil` if the file does not exist.
  fileprivate func fileItem(for pathComponents: [String]) -> FileItem? {
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
  fileprivate func child(withName name: String, ofParent parent: FileItem, create: Bool = false) -> FileItem? {
    let filteredChildren = parent.children.filter { $0.url.lastPathComponent == name }

    if filteredChildren.isEmpty && create {
      let childUrl = parent.url.appendingPathComponent(name)

      guard FileUtils.fileExistsAtUrl(childUrl) else {
        return nil
      }

      let child = FileItem(childUrl)
      self.syncAddChildren { parent.children.append(child) }

      return child
    }

    return filteredChildren.first
  }

  fileprivate func scanChildren(_ item: FileItem) {
    let children = FileUtils.directDescendants(item.url).map(FileItem.init)
    self.syncAddChildren { item.children = children }

    item.childrenScanned = true
    item.needsScanChildren = false
  }

  fileprivate func syncAddChildren(_ fn: () -> Void) {
    OSSpinLockLock(&self.spinLock)
    fn()
    OSSpinLockUnlock(&self.spinLock)
  }

  override func subscription(source: Observable<Any>) -> Disposable {
    return source
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribe(onNext: { [unowned self] data in
        if data.general.ignorePatterns == self.ignorePatterns {
          return
        }

        self.set(ignorePatterns: data.general.ignorePatterns)
        })
  }
}
