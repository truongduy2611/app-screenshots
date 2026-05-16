import Cocoa
import FlutterMacOS

/// Handles iCloud backup and sync operations via Flutter method channel (macOS).
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
                  let cloudFileName = args["cloudFileName"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
                return
            }
            uploadToICloud(localPath: localPath, cloudFileName: cloudFileName, result: result)
            
        case "downloadFromICloud":
            guard let args = call.arguments as? [String: Any],
                  let cloudFileName = args["cloudFileName"] as? String,
                  let localPath = args["localPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
                return
            }
            downloadFromICloud(cloudFileName: cloudFileName, localPath: localPath, result: result)
            
        case "listICloudBackups":
            listICloudBackups(result: result)
            
        case "deleteICloudBackup":
            guard let args = call.arguments as? [String: Any],
                  let fileName = args["fileName"] as? String else {
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
            try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        }
        return documentsURL
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
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: nil)
        NSLog("[ICloudBackupHandler] Stopped monitoring iCloud changes")
    }
    
    @objc private func metadataQueryDidFinishGathering(_ notification: Notification) {
        metadataQuery?.enableUpdates()
    }
    
    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let added = (userInfo[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem]) ?? []
        let removed = (userInfo[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem]) ?? []
        let changed = (userInfo[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem]) ?? []
        
        let addedNames = added.compactMap { $0.value(forAttribute: NSMetadataItemFSNameKey) as? String }
        let removedNames = removed.compactMap { $0.value(forAttribute: NSMetadataItemFSNameKey) as? String }
        let changedNames = changed.compactMap { $0.value(forAttribute: NSMetadataItemFSNameKey) as? String }
        
        guard !addedNames.isEmpty || !removedNames.isEmpty || !changedNames.isEmpty else { return }
        
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
    
    private func uploadToICloud(localPath: String, cloudFileName: String, result: @escaping FlutterResult) {
        guard let iCloudURL = getICloudDocumentsURL() else {
            result(FlutterError(code: "ICLOUD_UNAVAILABLE", message: "iCloud not available", details: nil))
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
                    result(["cloudPath": cloudURL.path, "fileName": cloudFileName])
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "UPLOAD_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func downloadFromICloud(cloudFileName: String, localPath: String, result: @escaping FlutterResult) {
        guard let iCloudURL = getICloudDocumentsURL() else {
            result(FlutterError(code: "ICLOUD_UNAVAILABLE", message: "iCloud not available", details: nil))
            return
        }
        let cloudURL = iCloudURL.appendingPathComponent(cloudFileName)
        let localURL = URL(fileURLWithPath: localPath)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if let rv = try? cloudURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]),
                   rv.ubiquitousItemDownloadingStatus != .current {
                    try FileManager.default.startDownloadingUbiquitousItem(at: cloudURL)
                }
                var attempts = 0
                while attempts < 30 {
                    if let rv = try? cloudURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]),
                       rv.ubiquitousItemDownloadingStatus == .current { break }
                    Thread.sleep(forTimeInterval: 1.0)
                    attempts += 1
                }
                guard FileManager.default.fileExists(atPath: cloudURL.path) else {
                    throw NSError(domain: "ICloudBackup", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
                }
                if FileManager.default.fileExists(atPath: localPath) {
                    try FileManager.default.removeItem(atPath: localPath)
                }
                try FileManager.default.copyItem(at: cloudURL, to: localURL)
                DispatchQueue.main.async { result(true) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "DOWNLOAD_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func listICloudBackups(result: @escaping FlutterResult) {
        guard let iCloudURL = getICloudDocumentsURL() else { result([]); return }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: iCloudURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                    options: .skipsHiddenFiles
                )
                let backups: [[String: Any]] = fileURLs.filter { $0.pathExtension == "zip" }.compactMap { url in
                    let rv = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                    return [
                        "fileName": url.lastPathComponent,
                        "filePath": url.path,
                        "createdAt": ISO8601DateFormatter().string(from: rv?.creationDate ?? Date()),
                        "sizeInBytes": rv?.fileSize ?? 0
                    ]
                }.sorted { ($0["createdAt"] as? String ?? "") > ($1["createdAt"] as? String ?? "") }
                DispatchQueue.main.async { result(backups) }
            } catch {
                DispatchQueue.main.async { result([]) }
            }
        }
    }
    
    private func deleteICloudBackup(fileName: String, result: @escaping FlutterResult) {
        guard let iCloudURL = getICloudDocumentsURL() else { result(false); return }
        let fileURL = iCloudURL.appendingPathComponent(fileName)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    DispatchQueue.main.async { result(false) }; return
                }
                try FileManager.default.removeItem(at: fileURL)
                DispatchQueue.main.async { result(true) }
            } catch {
                DispatchQueue.main.async { result(false) }
            }
        }
    }
}
