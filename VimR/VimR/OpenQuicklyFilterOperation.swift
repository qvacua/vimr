/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class OpenQuicklyFilterOperation: Operation {

  init(forOpenQuickly openQuickly: OpenQuicklyWindow) {
    self.openQuickly = openQuickly
    self.pattern = openQuickly.pattern
    self.cwd = openQuickly.cwd
    self.flatFileItems = openQuickly.flatFileItems

    super.init()
  }

  override func main() {
    self.openQuickly.scanCondition.lock()
    self.openQuickly.pauseScan = true
    defer {
      self.openQuickly.pauseScan = false
      self.openQuickly.scanCondition.broadcast()
      self.openQuickly.scanCondition.unlock()
    }

    if self.isCancelled {
      return
    }

    if self.flatFileItems.isEmpty {
      return
    }

    let sorted: [ScoredFileItem]
    if pattern.count == 0 {
      let truncatedItems = self.flatFileItems[0...min(maxResultCount, self.flatFileItems.count - 1)]
      sorted = truncatedItems.map { ScoredFileItem(score: 0, url: $0.url) }
    } else {
      DispatchQueue.main.async { self.openQuickly.startProgress() }
      defer { DispatchQueue.main.async { self.openQuickly.endProgress() } }

      let count = self.flatFileItems.count
      let chunksCount = Int(ceil(Float(count) / Float(chunkSize)))
      let useFullPath = pattern.contains("/")
      let cwdPath = self.cwd.path + "/"

      var result = [ScoredFileItem]()
      var spinLock = OS_SPINLOCK_INIT

      let cleanedPattern = useFullPath ? self.pattern.replacingOccurrences(of: "/", with: "")
                                       : self.pattern

      DispatchQueue.concurrentPerform(iterations: chunksCount) { [unowned self] idx in
        if self.isCancelled {
          return
        }

        let startIndex = min(idx * chunkSize, count)
        let endIndex = min(startIndex + chunkSize, count)

        let chunkedItems = self.flatFileItems[startIndex..<endIndex]
        let chunkedResult: [ScoredFileItem] = chunkedItems.flatMap {
          if self.isCancelled {
            return nil
          }

          let url = $0.url

          if useFullPath {
            let target = url.path.replacingOccurrences(of: cwdPath, with: "")
                                 .replacingOccurrences(of: "/", with: "")

            return ScoredFileItem(score: Scorer.score(target, pattern: cleanedPattern), url: url)
          }

          return ScoredFileItem(score: Scorer.score(url.lastPathComponent, pattern: cleanedPattern), url: url)
        }

        if self.isCancelled {
          return
        }

        OSSpinLockLock(&spinLock)
        result.append(contentsOf: chunkedResult)
        OSSpinLockUnlock(&spinLock)
      }

      if self.isCancelled {
        return
      }

      sorted = result.sorted(by: >)
    }

    if self.isCancelled {
      return
    }

    DispatchQueue.main.async {
      let result = Array(sorted[0...min(maxResultCount, sorted.count - 1)])
      self.openQuickly.reloadFileView(withScoredItems: result)
    }
  }

  fileprivate let pattern: String
  fileprivate let flatFileItems: [FileItem]
  fileprivate let cwd: URL

  fileprivate unowned let openQuickly: OpenQuicklyWindow
}

fileprivate let chunkSize = 100
fileprivate let maxResultCount = 500
