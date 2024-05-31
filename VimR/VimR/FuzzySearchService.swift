/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Commons
import CoreData
import Foundation
import Ignore
import Misc
import os

final class FuzzySearchService {
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

        let matcher = FzyMatcher(needle: pattern)

        self.scanScoreSavedFiles(matcher: matcher, context: ctx, callback: callback)

        if self.shouldStop() { return }

        self.scanScoreFilesNeedScanning(matcher: matcher, context: ctx, callback: callback)
      }

      self.log.info("Finished fuzzy search for \(pattern) in \(self.root)")
    }
  }

  private func scanScoreSavedFiles(
    matcher: FzyMatcher,
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
    self.log.info("Scoring \(count) Files for pattern \(matcher.needle)")

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
        try self.scoreFiles(
          matcher: matcher,
          files: context.fetch(fetchReq),
          callback: callback
        )
      } catch {
        self.log.error("Could not fetch \(fetchReq): \(error)")
      }

      context.reset()
    }
  }

  private func scanScoreFilesNeedScanning(
    matcher: FzyMatcher,
    context: NSManagedObjectContext,
    callback: ([ScoredUrl]) -> Void
  ) {
    let req = self.fileFetchRequest("needsScanChildren == TRUE AND direntType == %d", [DT_DIR])
    do {
      let foldersToScan = try context.fetch(req)
      // We use the ID of objects since we reset in scanScore(), which resets all properties of
      // foldersToScan after first folderToScan.
      for folder in foldersToScan {
        self.scanScore(
          matcher: matcher,
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
    matcher: FzyMatcher,
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

    let initialBaton = self.ignoreService.ignore(for: folder.url!)
    let testIgnores = self.usesVcsIgnores
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
            guard testIgnores, let ignore = baton else { return true }

            let isExcluded = ignore.excludes($0)
            if isExcluded { self.log.debug("Ignoring \($0.path)") }
            return !isExcluded
          }

        let childFiles = childUrls
          .filter { !$0.isPackage }
          .map { url -> FileItem in self.file(fromUrl: url, in: context) }
        saveCounter += childFiles.count
        counter += childFiles.count

        folder.addChildren(Set(childFiles))
        folder.needsScanChildren = false

        let childFolders = childFiles.filter { $0.direntType == DT_DIR }
        let childBatons = childFolders.map { self.ignoreService.ignore(for: $0.url!) }

        stack.append(contentsOf: zip(childBatons, childFolders))

        if saveCounter > coreDataBatchSize {
          self.log.debug(
            "Flushing and scoring \(saveCounter) Files, stack has \(stack.count) Files"
          )
          self.scoreAllRegisteredFiles(
            matcher: matcher,
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
    self.scoreAllRegisteredFiles(matcher: matcher, context: context, callback: callback)
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
    matcher: FzyMatcher,
    context: NSManagedObjectContext,
    callback: ([ScoredUrl]) -> Void
  ) {
    let files = context.registeredObjects
      .compactMap { $0 as? FileItem }
      .filter { $0.direntType != DT_DIR }

    self.log.debug("Scoring \(files.count) Files")
    self.scoreFiles(matcher: matcher, files: files, callback: callback)
  }

  private func scoreFiles(
    matcher: FzyMatcher,
    files: [FileItem],
    callback: ScoredUrlsCallback
  ) {
    let matchFullPath = matcher.needle.contains("/")
    let count = files.count

    let chunkCount = Int(ceil(Double(count) / Double(fuzzyMatchChunkSize)))
    DispatchQueue.concurrentPerform(iterations: chunkCount) { chunkIndex in
      let start = Swift.min(chunkIndex * fuzzyMatchChunkSize, count)
      let end = Swift.min(start + fuzzyMatchChunkSize, count)

      if self.shouldStop() { return }

      let scoreThreshold = 1.0
      callback(files[start..<end].compactMap { file in
        let url = file.url!
        let haystack = matchFullPath ? url.path : url.lastPathComponent

        guard matcher.hasMatch(haystack) else { return nil }

        let score = matcher.score(haystack)
        if score < scoreThreshold { return nil }

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

    self.ignoreService = IgnoreService(count: 500, root: root)

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
          _ = self.file(fromUrl: self.root, in: ctx)
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

          for child in folder.children ?? [] {
            ctx.delete(child)
          }

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

  private func file(fromUrl url: URL, in context: NSManagedObjectContext) -> FileItem {
    let file = FileItem(context: context)
    file.url = url
    file.direntType = url.direntType
    file.isHidden = url.isHidden
    file.isPackage = url.isPackage
    if url.hasDirectoryPath { file.needsScanChildren = true }

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

  private let coreDataStack: CoreDataStack
  private let writeContext: NSManagedObjectContext
  private let ignoreService: IgnoreService

  private let log = OSLog(subsystem: Defs.loggerSubsystem, category: Defs.LoggerCategory.service)
}

private let fuzzyMatchChunkSize = 100
private let coreDataBatchSize = 10000
