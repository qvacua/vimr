/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Commons
import CoreData
import Foundation
import os

class FuzzySearchService {
  typealias ScoredUrlsCallback = ([ScoredUrl]) -> Void

  var root: URL {
    didSet {
      self.queue.sync {
        self.deleteAllFiles()
        self.ensureRootFileInStore()
      }
    }
  }

  var usesVcsIgnores = true {
    willSet { self.stopScanScore() }
    didSet {
      self.queue.sync {
        self.deleteAllFiles()
        self.ensureRootFileInStore()
      }
    }
  }

  let coreDataStack: CoreDataStack

  func cleanUp() {
    do {
      try self.coreDataStack.deleteStore()
    } catch {
      self.log.error("Could not delete core data store: \(error)")
    }
  }

  func stopScanScore() {
    self.stopLock.lock()
    defer { self.stopLock.unlock() }

    self.stop = true
  }

  func scanScore(
    for pattern: String,
    beginCallback: @escaping () -> Void,
    endCallback: @escaping () -> Void,
    callback: @escaping ScoredUrlsCallback
  ) {
    self.queue.async {
      self.log.info("Starting fuzzy search for \(pattern) in \(self.root)")
      beginCallback()
      defer { endCallback() }

      let ctx = self.writeContext
      ctx.performAndWait {
        self.stopLock.lock()
        self.stop = false
        self.stopLock.unlock()

        let matcherPool = FuzzyMatcherPool(pattern: pattern, initialPoolSize: 2)

        self.scanScoreSavedFiles(matcherPool: matcherPool, context: ctx, callback: callback)

        if self.shouldStop() { return }

        self.scanScoreFilesNeedScanning(matcherPool: matcherPool, context: ctx, callback: callback)
      }

      self.log.info("Finished fuzzy search for \(pattern) in \(self.root)")
    }
  }

  private func scanScoreSavedFiles(
    matcherPool: FuzzyMatcherPool,
    context: NSManagedObjectContext,
    callback: ScoredUrlsCallback
  ) {
    let predicate = NSPredicate(format: "direntType != %d", DT_DIR)

    let countReq = FileItem.fetchRequest()
    countReq.predicate = predicate
    countReq.includesSubentities = false
    guard let count = try? context.count(for: countReq) else {
      self.log.error("Could not get count of Files")
      return
    }
    self.log.info("Scoring \(count) Files for pattern \(matcherPool.pattern)")

    let urlSorter = NSSortDescriptor(key: "url", ascending: true)
    let fetchReq = FileItem.fetchRequest()
    fetchReq.fetchLimit = coreDataBatchSize
    fetchReq.sortDescriptors = [urlSorter]
    fetchReq.predicate = predicate

    let chunkCount = Int(ceil(Double(count) / Double(coreDataBatchSize)))
    for chunkIndex in 0..<chunkCount {
      if self.shouldStop({ context.reset() }) { return }

      let start = Swift.min(chunkIndex * coreDataBatchSize, count)
      fetchReq.fetchOffset = start
      do {
        self.scoreFiles(
          matcherPool: matcherPool,
          files: try context.fetch(fetchReq),
          callback: callback
        )
      } catch {
        self.log.error("Could not fetch \(fetchReq): \(error)")
      }

      context.reset()
    }
  }

  private func scanScoreFilesNeedScanning(
    matcherPool: FuzzyMatcherPool,
    context: NSManagedObjectContext,
    callback: ([ScoredUrl]) -> Void
  ) {
    let req = self.fileFetchRequest("needsScanChildren == TRUE AND direntType == %d", [DT_DIR])
    do {
      let foldersToScan = try context.fetch(req)
      // We use the ID of objects since we reset in scanScore(), which resets all properties of
      // foldersToScan after first folderToScan.
      foldersToScan.forEach { folder in
        self.scanScore(
          matcherPool: matcherPool,
          folderId: folder.objectID,
          context: context,
          callback: callback
        )
      }
    } catch {
      self.log.error("Could not fetch \(req): \(error)")
    }
  }

  private func scanScore(
    matcherPool: FuzzyMatcherPool,
    folderId: NSManagedObjectID,
    context: NSManagedObjectContext,
    callback: ([ScoredUrl]) -> Void
  ) {
    var saveCounter = 1
    var counter = 1

    guard let folder = context.object(with: folderId) as? FileItem else {
      self.log.error("Could not convert object with ID \(folderId) to File")
      return
    }

    let (initialBaton, initialBatons) = self.baton(for: folder.url!)
    let testIgnores = self.usesVcsIgnores
    var batons = initialBatons
    var stack = [(initialBaton, folder)]
    while let iterElement = stack.popLast() {
      if self.shouldStop({ self.saveAndReset(context: context) }) { return }

      autoreleasepool {
        let baton = iterElement.0
        let folder = iterElement.1

        let urlToScan = folder.url!

        let childUrls = FileUtils
          .directDescendants(of: urlToScan)
          .filter {
            let keep = testIgnores ? baton.test($0) : true
            if !keep { self.log.debug("Ignoring \($0.path)") }
            return keep
          }

        let childFiles = childUrls
          .filter { !$0.isPackage }
          .map { url -> FileItem in
            self.file(fromUrl: url, pathStart: baton.pathStart, in: context)
          }
        saveCounter += childFiles.count
        counter += childFiles.count

        folder.addChildren(Set(childFiles))
        folder.needsScanChildren = false

        let childFolders = childFiles.filter { $0.direntType == DT_DIR }
        let childBatons = childFolders.map { FileScanBaton(parent: baton, url: $0.url!) }

        batons.append(contentsOf: childBatons)
        stack.append(contentsOf: zip(childBatons, childFolders))

        if saveCounter > coreDataBatchSize {
          self.log.debug(
            "Flushing and scoring \(saveCounter) Files, stack has \(stack.count) Files"
          )
          self.scoreAllRegisteredFiles(
            matcherPool: matcherPool,
            context: context,
            callback: callback
          )
          self.saveAndReset(context: context)

          saveCounter = 0

          // We have to re-fetch the Files in stack to get the parent-children relationship right.
          // Since objectID survives NSManagedObjectContext.reset(), we can re-populate (re-fetch)
          // stack using the objectIDs.
          let ids = stack.map(\.1.objectID)
          stack = Array(zip(
            stack.map(\.0),
            ids.map { context.object(with: $0) as! FileItem }
          ))
        }
      }
    }

    self.log.debug("Flushing and scoring last \(saveCounter) Files")
    self.scoreAllRegisteredFiles(matcherPool: matcherPool, context: context, callback: callback)
    self.saveAndReset(context: context)

    self.log.debug("Stored \(counter) Files")
  }

  private func saveAndReset(context: NSManagedObjectContext) {
    do {
      try context.save()
    } catch {
      self.log.error("There was an error saving the context: \(error)")
    }
    context.reset()
  }

  private func shouldStop(_ body: (() -> Void)? = nil) -> Bool {
    self.stopLock.lock()
    defer { self.stopLock.unlock() }

    if self.stop {
      body?()
      return true
    }

    return false
  }

  private func scoreAllRegisteredFiles(
    matcherPool: FuzzyMatcherPool,
    context: NSManagedObjectContext,
    callback: ([ScoredUrl]) -> Void
  ) {
    let files = context.registeredObjects
      .compactMap { $0 as? FileItem }
      .filter { $0.direntType != DT_DIR }

    self.log.debug("Scoring \(files.count) Files")
    self.scoreFiles(matcherPool: matcherPool, files: files, callback: callback)
  }

  private func scoreFiles(
    matcherPool: FuzzyMatcherPool,
    files: [FileItem],
    callback: ScoredUrlsCallback
  ) {
    let matchFullPath = matcherPool.pattern.contains("/")
    let count = files.count

    let chunkCount = Int(ceil(Double(count) / Double(fuzzyMatchChunkSize)))
    DispatchQueue.concurrentPerform(iterations: chunkCount) { chunkIndex in
      let matcher = matcherPool.request()
      defer { matcherPool.giveBack(matcher) }

      let start = Swift.min(chunkIndex * fuzzyMatchChunkSize, count)
      let end = Swift.min(start + fuzzyMatchChunkSize, count)

      if self.shouldStop() { return }

      let scoreThreshold = FuzzyMatcher.minScore() + 1
      callback(files[start..<end].compactMap { file in
        let url = file.url!
        let score = matcher.score(matchFullPath ? url.path : url.lastPathComponent)
        if score <= scoreThreshold { return nil }

        return ScoredUrl(url: url, score: score)
      })
    }
  }

  init(root: URL) throws {
    self.coreDataStack = try CoreDataStack(
      modelName: "FuzzySearch",
      storeLocation: .temp(UUID().uuidString),
      deleteOnDeinit: true
    )
    self.root = root
    self.writeContext = self.coreDataStack.newBackgroundContext()

    self.queue.sync { self.ensureRootFileInStore() }
    try self.fileMonitor.monitor(url: root) { [weak self] url in self?.handleChange(in: url) }
  }

  private func ensureRootFileInStore() {
    self.queue.async {
      let ctx = self.writeContext
      ctx.performAndWait {
        let req = self.fileFetchRequest("url == %@", [self.root])
        do {
          let files = try ctx.fetch(req)
          guard files.isEmpty else { return }
          _ = self.file(fromUrl: self.root, pathStart: ".", in: ctx)
          try ctx.save()
        } catch {
          self.log.error("Could not ensure root File in Core Data: \(error)")
        }
      }
    }
  }

  private func handleChange(in folderUrl: URL) {
    self.queue.async {
      let ctx = self.writeContext
      ctx.performAndWait {
        let req = self.fileFetchRequest("url == %@", [folderUrl])
        do {
          let fetchResult = try ctx.fetch(req)
          guard let folder = fetchResult.first else {
            return
          }

          for child in folder.children ?? [] { ctx.delete(child) }

          folder.needsScanChildren = true
          self.log.trace("Marked \(folder.url!) for scanning")

          try ctx.save()
        } catch {
          self.log.error(
            "Could not fetch File with url \(folderUrl) "
              + "or could not save after setting needsScanChildren: \(error)"
          )
        }

        ctx.reset()
      }
    }
  }

  private func fileFetchRequest(
    _ format: String,
    _ arguments: [Any]? = nil
  ) -> NSFetchRequest<FileItem> {
    let req: NSFetchRequest<FileItem> = FileItem.fetchRequest()
    req.predicate = NSPredicate(format: format, argumentArray: arguments)

    return req
  }

  /// Call this in self.queue.(a)sync
  private func deleteAllFiles() {
    let delReq = NSBatchDeleteRequest(
      fetchRequest: NSFetchRequest(entityName: String(describing: FileItem.self))
    )

    let ctx = self.writeContext
    ctx.performAndWait {
      do {
        try ctx.execute(delReq)
      } catch {
        self.log.error("Could not delete all Files: \(error)")
      }
    }
  }

  private func baton(for url: URL) -> (FileScanBaton, [FileScanBaton]) {
    assert(self.root.isParent(of: url) || url == self.root)

    if url == self.root {
      let rootBaton = FileScanBaton(baseUrl: self.root)
      return (rootBaton, [rootBaton])
    }

    let rootBaton = FileScanBaton(baseUrl: self.root)
    var batons = [rootBaton]

    var pathComps = url.pathComponents.suffix(from: self.root.pathComponents.count)

    var lastBaton = rootBaton
    var lastUrl = self.root
    while let pathComp = pathComps.popFirst() {
      let childUrl = lastUrl.appendingPathComponent(pathComp)
      let childBaton = FileScanBaton(parent: lastBaton, url: childUrl)
      batons.append(childBaton)

      lastBaton = childBaton
      lastUrl = childUrl
    }

    return (lastBaton, batons)
  }

  private func file(
    fromUrl url: URL,
    pathStart: String,
    in context: NSManagedObjectContext
  ) -> FileItem {
    let file = FileItem(context: context)
    file.url = url
    file.direntType = Int16(url.direntType)
    file.isHidden = url.isHidden
    file.isPackage = url.isPackage
    file.pathStart = pathStart
    if url.isDir { file.needsScanChildren = true }

    return file
  }

  func debug() {
    let req = self.fileFetchRequest("needsScanChildren == TRUE AND direntType == %d", [DT_DIR])

    self.queue.async {
      let moc = self.writeContext
      moc.performAndWait {
        do {
          let result = try moc.fetch(req)
          Swift.print("Files with needsScanChildren = true:")
          result.forEach { Swift.print("\t\(String(describing: $0.url))") }
          Swift.print("--- \(result.count)")
        } catch {
          Swift.print(error)
        }
      }
    }
  }

  private var stop = false
  private let stopLock = NSLock()

  private let queue = DispatchQueue(
    label: "scan-score-queue",
    qos: .userInitiated,
    target: .global(qos: .userInitiated)
  )

  private let fileMonitor = FileMonitor()
  private let writeContext: NSManagedObjectContext

  private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.service)
}

private let fuzzyMatchChunkSize = 100
private let coreDataBatchSize = 10000
