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
      result(isICloudAvailable())

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
      result(getICloudDesignsPath())

    case "getLocalDesignsPath":
      result(getLocalDesignsPath())

    case "startMonitoringChanges":
      startMonitoringChanges()
      result(nil)

    case "stopMonitoringChanges":
      stopMonitoringChanges()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - iCloud Operations

  /// Checks if iCloud is available for the current user.
  private func isICloudAvailable() -> Bool {
    guard FileManager.default.ubiquityIdentityToken != nil else {
      return false
    }
    guard FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil else {
      return false
    }
    return true
  }

  /// Returns the URL for the iCloud Documents container.
  private func getICloudDocumentsURL() -> URL? {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
      return nil
    }

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

  // MARK: - iCloud Sync

  /// Returns the iCloud designs directory path, creating it if needed.
  private func getICloudDesignsPath() -> String? {
    guard let docsURL = getICloudDocumentsURL() else { return nil }
    let designsURL = docsURL.appendingPathComponent("screenshot_designs")

    if !FileManager.default.fileExists(atPath: designsURL.path) {
      do {
        try FileManager.default.createDirectory(at: designsURL, withIntermediateDirectories: true)
      } catch {
        NSLog("[ICloudBackupHandler] Failed to create iCloud designs dir: \(error)")
        return nil
      }
    }

    return designsURL.path
  }

  /// Returns the local app-documents designs directory path.
  private func getLocalDesignsPath() -> String? {
    guard
      let appDocsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    else {
      return nil
    }
    let designsURL = appDocsURL.appendingPathComponent("screenshot_designs")

    if !FileManager.default.fileExists(atPath: designsURL.path) {
      do {
        try FileManager.default.createDirectory(at: designsURL, withIntermediateDirectories: true)
      } catch {
        NSLog("[ICloudBackupHandler] Failed to create local designs dir: \(error)")
        return nil
      }
    }

    return designsURL.path
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
