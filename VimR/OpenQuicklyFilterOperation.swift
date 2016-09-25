/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

class OpenQuicklyFilterOperation: Operation {

  fileprivate let chunkSize = 100
  fileprivate let maxResultCount = 500

  fileprivate unowned let openQuicklyWindow: OpenQuicklyWindowComponent
  fileprivate let pattern: String
  fileprivate let flatFileItems: [FileItem]
  fileprivate let cwd: URL

  init(forOpenQuicklyWindow openQuicklyWindow: OpenQuicklyWindowComponent) {
    self.openQuicklyWindow = openQuicklyWindow
    self.pattern = openQuicklyWindow.pattern
    self.cwd = openQuicklyWindow.cwd as URL
    self.flatFileItems = openQuicklyWindow.flatFileItems
    
    super.init()
  }

  override func main() {
    self.openQuicklyWindow.scanCondition.lock()
    self.openQuicklyWindow.pauseScan = true
    defer {
      self.openQuicklyWindow.pauseScan = false
      self.openQuicklyWindow.scanCondition.broadcast()
      self.openQuicklyWindow.scanCondition.unlock()
    }

    if self.isCancelled {
      return
    }

    let sorted: [ScoredFileItem]
    if pattern.characters.count == 0 {
      let truncatedItems = self.flatFileItems[0...min(self.maxResultCount, self.flatFileItems.count - 1)]
      sorted = truncatedItems.map { ScoredFileItem(score: 0, url: $0.url) }
    } else {
      DispatchUtils.gui { self.openQuicklyWindow.startProgress() }
      defer { DispatchUtils.gui { self.openQuicklyWindow.endProgress() } }

      let count = self.flatFileItems.count
      let chunksCount = Int(ceil(Float(count) / Float(self.chunkSize)))
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

        let startIndex = min(idx * self.chunkSize, count)
        let endIndex = min(startIndex + self.chunkSize, count)

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

    DispatchUtils.gui {
      let result = Array(sorted[0...min(self.maxResultCount, sorted.count - 1)])
      self.openQuicklyWindow.reloadFileView(withScoredItems: result)
    }
  }
}
