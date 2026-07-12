import Flutter
import Foundation

/// Handles iCloud backup and sync operations via Flutter method channel.
class ICloudBackupHandler: NSObject {
  static let shared = ICloudBackupHandler()

  private let channelName = "com.progressiostudio.appscreenshots/icloud"
  private var channel: FlutterMethodChannel?

  /// NSMetadataQuery for monitoring iCloud file changes.
  private var metadataQuery: NSMetadataQuery?

  /// Debounce timer to batch rapid change notifications.
  private var debounceTimer: Timer?

  /// Background queue for iCloud container resolution (avoids main-thread blocking).
  private let iCloudQueue = DispatchQueue(label: "com.progressiostudio.appscreenshots.icloud", qos: .userInitiated)

  /// Cached ubiquity container URL — resolved once, reused for the session.
  private var cachedContainerURL: URL?
  private var containerResolved = false

  private struct OpenedDocument {
    let originalURL: URL
    let hasSecurityScope: Bool
  }

  /// Maps sandbox working copies back to the open-in-place URLs supplied by
  /// Files. Keeping the security scope alive lets later saves update the shared
  /// iCloud Drive document instead of only changing the temporary copy.
  private var openedDocuments: [String: OpenedDocument] = [:]
  private let openedDocumentsLock = NSLock()

  private override init() {
    super.init()
  }

  /// Sets up the method channel with the Flutter binary messenger.
  func setup(binaryMessenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: binaryMessenger
    )

    channel?.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call: call, result: result)
    }
  }

  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isICloudAvailable":
      isICloudAvailableAsync(result: result)

    case "uploadToICloud":
      guard let args = call.arguments as? [String: Any],
        let localPath = args["localPath"] as? String,
        let cloudFileName = args["cloudFileName"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
        return
      }
      uploadToICloud(localPath: localPath, cloudFileName: cloudFileName, result: result)

    case "downloadFromICloud":
      guard let args = call.arguments as? [String: Any],
        let cloudFileName = args["cloudFileName"] as? String,
        let localPath = args["localPath"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
        return
      }
      downloadFromICloud(cloudFileName: cloudFileName, localPath: localPath, result: result)

    case "listICloudBackups":
      listICloudBackups(result: result)

    case "deleteICloudBackup":
      guard let args = call.arguments as? [String: Any],
        let fileName = args["fileName"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
        return
      }
      deleteICloudBackup(fileName: fileName, result: result)

    // ── iCloud Sync methods ──

    case "getICloudDesignsPath":
      getICloudDesignsPathAsync(result: result)

    case "getLocalDesignsPath":
      getLocalDesignsPathAsync(result: result)

    case "startMonitoringChanges":
      startMonitoringChanges()
      result(nil)

    case "stopMonitoringChanges":
      stopMonitoringChanges()
      result(nil)

    case "shareICloudDocument":
      guard let args = call.arguments as? [String: Any],
        let localPath = args["localPath"] as? String,
        let fileName = args["fileName"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
        return
      }
      shareICloudDocument(localPath: localPath, fileName: fileName, result: result)

    case "saveOpenedDocument":
      guard let args = call.arguments as? [String: Any],
        let localPath = args["localPath"] as? String,
        let workingPath = args["workingPath"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
        return
      }
      saveOpenedDocument(localPath: localPath, workingPath: workingPath, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - iCloud Operations

  /// Resolves the ubiquity container URL (blocking) — call from background queue only.
  private func resolveContainerURL() -> URL? {
    if containerResolved {
      return cachedContainerURL
    }
    cachedContainerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
    containerResolved = true
    return cachedContainerURL
  }

  /// Async version: dispatches the heavy ubiquity container check to a background queue.
  private func isICloudAvailableAsync(result: @escaping FlutterResult) {
    iCloudQueue.async { [weak self] in
      let hasToken = FileManager.default.ubiquityIdentityToken != nil
      let hasContainer = self?.resolveContainerURL() != nil
      let available = hasToken && hasContainer
      DispatchQueue.main.async {
        result(available)
      }
    }
  }

  /// Synchronous check using cached container — safe for main thread after initial resolve.
  private func getICloudDocumentsURL() -> URL? {
    guard let containerURL = cachedContainerURL else { return nil }

    let documentsURL = containerURL.appendingPathComponent("Documents")

    if !FileManager.default.fileExists(atPath: documentsURL.path) {
      do {
        try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
      } catch {
        return nil
      }
    }

    return documentsURL
  }

  // MARK: - iCloud Drive Collaboration

  /// Creates a coordinated working copy for a document opened in place.
  /// The original URL and its security scope are retained for the editor's
  /// later Save command.
  func prepareOpenedDocument(url: URL) -> String? {
    let hasSecurityScope = url.startAccessingSecurityScopedResource()
    let destination = FileManager.default.temporaryDirectory
      .appendingPathComponent("appshots_open_\(UUID().uuidString)_\(url.lastPathComponent)")

    var coordinationError: NSError?
    var copyError: Error?
    NSFileCoordinator(filePresenter: nil).coordinate(
      readingItemAt: url,
      options: [],
      error: &coordinationError
    ) { coordinatedURL in
      do {
        try FileManager.default.copyItem(at: coordinatedURL, to: destination)
      } catch {
        copyError = error
      }
    }

    if let error = coordinationError ?? copyError as NSError? {
      if hasSecurityScope { url.stopAccessingSecurityScopedResource() }
      NSLog("[ICloudBackupHandler] Failed to open coordinated document: \(error.localizedDescription)")
      return nil
    }

    openedDocumentsLock.lock()
    openedDocuments[destination.path] = OpenedDocument(
      originalURL: url,
      hasSecurityScope: hasSecurityScope
    )
    openedDocumentsLock.unlock()
    return destination.path
  }

  private func saveOpenedDocument(
    localPath: String,
    workingPath: String,
    result: @escaping FlutterResult
  ) {
    openedDocumentsLock.lock()
    let openedDocument = openedDocuments[workingPath]
    openedDocumentsLock.unlock()

    guard let openedDocument = openedDocument else {
      result(false)
      return
    }

    iCloudQueue.async {
      let sourceURL = URL(fileURLWithPath: localPath)
      var coordinationError: NSError?
      var writeError: Error?

      NSFileCoordinator(filePresenter: nil).coordinate(
        writingItemAt: openedDocument.originalURL,
        options: .forReplacing,
        error: &coordinationError
      ) { coordinatedURL in
        do {
          let stagedURL = coordinatedURL.deletingLastPathComponent()
            .appendingPathComponent(".appshots-save-\(UUID().uuidString)")
          try FileManager.default.copyItem(at: sourceURL, to: stagedURL)
          if FileManager.default.fileExists(atPath: coordinatedURL.path) {
            try FileManager.default.removeItem(at: coordinatedURL)
          }
          try FileManager.default.moveItem(at: stagedURL, to: coordinatedURL)
        } catch {
          writeError = error
        }
      }

      let error = coordinationError ?? writeError as NSError?
      if error == nil {
        let workingURL = URL(fileURLWithPath: workingPath)
        try? FileManager.default.removeItem(at: workingURL)
        try? FileManager.default.copyItem(at: sourceURL, to: workingURL)
      }

      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(
            code: "COLLABORATION_SAVE_FAILED",
            message: error.localizedDescription,
            details: nil
          ))
        } else {
          result(true)
        }
      }
    }
  }

  private func shareICloudDocument(
    localPath: String,
    fileName: String,
    result: @escaping FlutterResult
  ) {
    iCloudQueue.async { [weak self] in
      guard let self = self else { return }
      let _ = self.resolveContainerURL()
      guard let documentsURL = self.getICloudDocumentsURL() else {
        DispatchQueue.main.async {
          result(FlutterError(code: "ICLOUD_UNAVAILABLE", message: "iCloud Drive is unavailable", details: nil))
        }
        return
      }

      let sharedDirectory = documentsURL.appendingPathComponent("Shared Designs", isDirectory: true)
      let safeFileName = URL(fileURLWithPath: fileName).lastPathComponent
      let cloudURL = sharedDirectory.appendingPathComponent(safeFileName)
      let sourceURL = URL(fileURLWithPath: localPath)

      do {
        try FileManager.default.createDirectory(
          at: sharedDirectory,
          withIntermediateDirectories: true
        )
        if FileManager.default.fileExists(atPath: cloudURL.path) {
          var coordinationError: NSError?
          var writeError: Error?
          NSFileCoordinator(filePresenter: nil).coordinate(
            writingItemAt: cloudURL,
            options: .forReplacing,
            error: &coordinationError
          ) { coordinatedURL in
            do {
              try FileManager.default.removeItem(at: coordinatedURL)
              try FileManager.default.copyItem(at: sourceURL, to: coordinatedURL)
            } catch {
              writeError = error
            }
          }
          if let error = coordinationError ?? writeError as NSError? { throw error }
        } else {
          try FileManager.default.copyItem(at: sourceURL, to: cloudURL)
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "ICLOUD_SHARE_PREPARATION_FAILED",
            message: error.localizedDescription,
            details: nil
          ))
        }
        return
      }

      DispatchQueue.main.async {
        guard let presenter = self.topViewController() else {
          result(FlutterError(code: "NO_PRESENTER", message: "Unable to present sharing controls", details: nil))
          return
        }

        let provider = NSItemProvider()
        provider.suggestedName = safeFileName
        provider.registerFileRepresentation(
          forTypeIdentifier: "com.progressiostudio.appscreenshots",
          fileOptions: [.openInPlace],
          visibility: .all
        ) { completion in
          completion(cloudURL, true, nil)
          return nil
        }

        let shareSheet: UIActivityViewController
        if #available(iOS 14.0, *) {
          let configuration = UIActivityItemsConfiguration(itemProviders: [provider])
          configuration.metadataProvider = { key in
            key == .title ? safeFileName.replacingOccurrences(of: ".appshots", with: "") : nil
          }
          shareSheet = UIActivityViewController(activityItemsConfiguration: configuration)
        } else {
          // iOS 13 can still send a copy; collaboration controls require the
          // activity-items configuration initializer available on iOS 14+.
          shareSheet = UIActivityViewController(activityItems: [cloudURL], applicationActivities: nil)
        }
        if let popover = shareSheet.popoverPresentationController {
          popover.sourceView = presenter.view
          popover.sourceRect = CGRect(
            x: presenter.view.bounds.midX,
            y: presenter.view.bounds.midY,
            width: 1,
            height: 1
          )
          popover.permittedArrowDirections = []
        }
        presenter.present(shareSheet, animated: true)
        result(["cloudPath": cloudURL.path])
      }
    }
  }

  private func topViewController() -> UIViewController? {
    var controller = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  // MARK: - iCloud Sync

  /// Async version: resolves iCloud designs path on a background queue.
  private func getICloudDesignsPathAsync(result: @escaping FlutterResult) {
    iCloudQueue.async { [weak self] in
      guard let self = self else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      // Ensure container is resolved
      let _ = self.resolveContainerURL()

      guard let docsURL = self.getICloudDocumentsURL() else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      let designsURL = docsURL.appendingPathComponent("screenshot_designs")

      if !FileManager.default.fileExists(atPath: designsURL.path) {
        do {
          try FileManager.default.createDirectory(at: designsURL, withIntermediateDirectories: true)
        } catch {
          NSLog("[ICloudBackupHandler] Failed to create iCloud designs dir: \(error)")
          DispatchQueue.main.async { result(nil) }
          return
        }
      }

      let path = designsURL.path
      DispatchQueue.main.async { result(path) }
    }
  }

  /// Async version: resolves local designs path on a background queue.
  private func getLocalDesignsPathAsync(result: @escaping FlutterResult) {
    iCloudQueue.async {
      guard let appDocsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      let designsURL = appDocsURL.appendingPathComponent("screenshot_designs")

      if !FileManager.default.fileExists(atPath: designsURL.path) {
        do {
          try FileManager.default.createDirectory(at: designsURL, withIntermediateDirectories: true)
        } catch {
          NSLog("[ICloudBackupHandler] Failed to create local designs dir: \(error)")
          DispatchQueue.main.async { result(nil) }
          return
        }
      }

      let path = designsURL.path
      DispatchQueue.main.async { result(path) }
    }
  }

  /// Starts monitoring iCloud for file changes using NSMetadataQuery.
  private func startMonitoringChanges() {
    guard metadataQuery == nil else { return }

    let query = NSMetadataQuery()
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
    query.predicate = NSPredicate(format: "%K LIKE '*'", NSMetadataItemFSNameKey)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(metadataQueryDidUpdate(_:)),
      name: .NSMetadataQueryDidUpdate,
      object: query
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(metadataQueryDidFinishGathering(_:)),
      name: .NSMetadataQueryDidFinishGathering,
      object: query
    )

    metadataQuery = query
    query.start()
    NSLog("[ICloudBackupHandler] Started monitoring iCloud changes")
  }

  /// Stops monitoring iCloud for file changes.
  private func stopMonitoringChanges() {
    metadataQuery?.stop()
    metadataQuery = nil
    debounceTimer?.invalidate()
    debounceTimer = nil
    NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: nil)
    NotificationCenter.default.removeObserver(
      self, name: .NSMetadataQueryDidFinishGathering, object: nil)
    NSLog("[ICloudBackupHandler] Stopped monitoring iCloud changes")
  }

  @objc private func metadataQueryDidFinishGathering(_ notification: Notification) {
    metadataQuery?.enableUpdates()
  }

    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        // Extract changed file info from the notification.
        let userInfo = notification.userInfo ?? [:]
        let added = (userInfo[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem]) ?? []
        let removed = (userInfo[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem]) ?? []
        let changed = (userInfo[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem]) ?? []
        
        let addedNames = added.compactMap { $0.value(forAttribute: NSMetadataItemFSNameKey) as? String }
        let removedNames = removed.compactMap { $0.value(forAttribute: NSMetadataItemFSNameKey) as? String }
        let changedNames = changed.compactMap { $0.value(forAttribute: NSMetadataItemFSNameKey) as? String }
        
        // Skip if no actual file changes (e.g. download progress updates).
        guard !addedNames.isEmpty || !removedNames.isEmpty || !changedNames.isEmpty else { return }
        
        // Debounce: batch rapid notifications into a single callback.
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            let args: [String: Any] = [
                "added": addedNames,
                "removed": removedNames,
                "changed": changedNames,
            ]
            self?.channel?.invokeMethod("onICloudFilesChanged", arguments: args)
        }
    }
    
    // MARK: - Backup Operations

  /// Uploads a local file to iCloud.
  private func uploadToICloud(
    localPath: String, cloudFileName: String, result: @escaping FlutterResult
  ) {
    guard let iCloudURL = getICloudDocumentsURL() else {
      result(
        FlutterError(code: "ICLOUD_UNAVAILABLE", message: "iCloud not available", details: nil))
      return
    }

    let localURL = URL(fileURLWithPath: localPath)
    let cloudURL = iCloudURL.appendingPathComponent(cloudFileName)

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        if FileManager.default.fileExists(atPath: cloudURL.path) {
          try FileManager.default.removeItem(at: cloudURL)
        }

        try FileManager.default.copyItem(at: localURL, to: cloudURL)

        DispatchQueue.main.async {
          result([
            "cloudPath": cloudURL.path,
            "fileName": cloudFileName,
          ])
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(code: "UPLOAD_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  /// Downloads a file from iCloud to local storage.
  private func downloadFromICloud(
    cloudFileName: String, localPath: String, result: @escaping FlutterResult
  ) {
    guard let iCloudURL = getICloudDocumentsURL() else {
      result(
        FlutterError(code: "ICLOUD_UNAVAILABLE", message: "iCloud not available", details: nil))
      return
    }

    let cloudURL = iCloudURL.appendingPathComponent(cloudFileName)
    let localURL = URL(fileURLWithPath: localPath)

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        // Start downloading if needed
        if let resourceValues = try? cloudURL.resourceValues(forKeys: [
          .ubiquitousItemDownloadingStatusKey
        ]),
          resourceValues.ubiquitousItemDownloadingStatus != .current
        {
          try FileManager.default.startDownloadingUbiquitousItem(at: cloudURL)
        }

        // Wait for download to complete
        var attempts = 0
        while attempts < 30 {
          if let resourceValues = try? cloudURL.resourceValues(forKeys: [
            .ubiquitousItemDownloadingStatusKey
          ]),
            resourceValues.ubiquitousItemDownloadingStatus == .current
          {
            break
          }
          Thread.sleep(forTimeInterval: 1.0)
          attempts += 1
        }

        guard FileManager.default.fileExists(atPath: cloudURL.path) else {
          throw NSError(
            domain: "ICloudBackup", code: 404,
            userInfo: [NSLocalizedDescriptionKey: "File not found in iCloud"])
        }

        if FileManager.default.fileExists(atPath: localPath) {
          try FileManager.default.removeItem(atPath: localPath)
        }

        try FileManager.default.copyItem(at: cloudURL, to: localURL)

        DispatchQueue.main.async {
          result(true)
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(code: "DOWNLOAD_FAILED", message: error.localizedDescription, details: nil)
          )
        }
      }
    }
  }

  /// Lists all backup files in iCloud.
  private func listICloudBackups(result: @escaping FlutterResult) {
    guard let iCloudURL = getICloudDocumentsURL() else {
      result([])
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let fileURLs = try FileManager.default.contentsOfDirectory(
          at: iCloudURL,
          includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
          options: .skipsHiddenFiles
        )

        let backups: [[String: Any]] =
          fileURLs
          .filter { $0.pathExtension == "zip" }
          .compactMap { url in
            let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
            let createdAt = resourceValues?.creationDate ?? Date()
            let size = resourceValues?.fileSize ?? 0

            return [
              "fileName": url.lastPathComponent,
              "filePath": url.path,
              "createdAt": ISO8601DateFormatter().string(from: createdAt),
              "sizeInBytes": size,
            ]
          }
          .sorted {
            ($0["createdAt"] as? String ?? "") > ($1["createdAt"] as? String ?? "")
          }

        DispatchQueue.main.async {
          result(backups)
        }
      } catch {
        DispatchQueue.main.async {
          result([])
        }
      }
    }
  }

  /// Deletes a backup file from iCloud.
  private func deleteICloudBackup(fileName: String, result: @escaping FlutterResult) {
    guard let iCloudURL = getICloudDocumentsURL() else {
      result(false)
      return
    }

    let fileURL = iCloudURL.appendingPathComponent(fileName)

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
          DispatchQueue.main.async { result(false) }
          return
        }

        try FileManager.default.removeItem(at: fileURL)

        DispatchQueue.main.async { result(true) }
      } catch {
        DispatchQueue.main.async { result(false) }
      }
    }
  }
}
