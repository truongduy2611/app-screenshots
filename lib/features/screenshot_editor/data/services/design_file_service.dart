import 'dart:convert';
import 'dart:io';

import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:archive/archive.dart';
import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Result of parsing a multi-design (folder) export file.
class FolderImportResult {
  final String folderName;
  final List<SavedDesign> designs;

  const FolderImportResult({required this.folderName, required this.designs});
}

/// Service for exporting/importing screenshot designs as portable `.appshots`
/// zip bundles.
///
/// The `.appshots` format is a zip archive containing:
/// - `manifest.json` — design metadata envelope
/// - `thumbnail.png` — design thumbnail
/// - `screenshot.png` — main screenshot image (if exists)
/// - `screenshots/{i}.png` — multi-canvas images (if exists)
/// - `overlays/{j}.ext` — user-added image overlay files (if any)
///
/// For folder exports, each design occupies a subdirectory named by its index:
/// - `0/manifest.json`, `0/thumbnail.png`, `0/screenshot.png`, etc.
class DesignFileService {
  static const int _currentVersion = 2;
  static const String _fileExtension = '.appshots';

  final Directory? _tempDirOverride;

  /// Creates a [DesignFileService].
  ///
  /// [tempDirOverride] is used only for testing to avoid platform channel calls.
  DesignFileService({Directory? tempDirOverride})
    : _tempDirOverride = tempDirOverride;

  Future<Directory> get _tempDir async =>
      _tempDirOverride ?? await getTemporaryDirectory();

  // ---------------------------------------------------------------------------
  // Export — Single Design
  // ---------------------------------------------------------------------------

  /// Exports a [SavedDesign] to a portable `.appshots` zip bundle.
  ///
  /// The file is written to the system's temporary directory and can then be
  /// shared via `share_plus` or saved via `FilePicker`.
  Future<File> createExportFile(SavedDesign design) async {
    final archive = Archive();

    await _addDesignToArchive(archive, design, prefix: '');

    return _writeArchiveToFile(archive, design.name);
  }

  // ---------------------------------------------------------------------------
  // Export — Multiple Designs (Folder)
  // ---------------------------------------------------------------------------

  /// Exports multiple [SavedDesign]s as a single `.appshots` zip bundle.
  Future<File> createExportFileForMultiple(
    List<SavedDesign> designs, {
    required String folderName,
  }) async {
    final archive = Archive();

    // Add folder manifest
    final folderManifest = jsonEncode({
      'version': _currentVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'screenshot_folder',
      'folderName': folderName,
      'designCount': designs.length,
    });
    archive.addFile(
      ArchiveFile.bytes('manifest.json', utf8.encode(folderManifest)),
    );

    // Add each design in its own subdirectory
    for (int i = 0; i < designs.length; i++) {
      await _addDesignToArchive(archive, designs[i], prefix: '$i/');
    }

    return _writeArchiveToFile(archive, folderName);
  }

  // ---------------------------------------------------------------------------
  // Import — Single Design
  // ---------------------------------------------------------------------------

  /// Parses a `.appshots` zip bundle and returns a [SavedDesign] with all
  /// assets extracted to a local directory.
  ///
  /// Returns `null` if the file is missing, malformed, or has an unsupported
  /// version.
  Future<SavedDesign?> parseExportFile(File file) async {
    try {
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Read manifest
      final manifestFile = archive.findFile('manifest.json');
      if (manifestFile == null) return null;
      final manifestJson =
          jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
      if (manifestJson['type'] != 'screenshot_design') return null;

      // Create extraction dir
      final extractDir = await _createExtractDir();

      return _extractDesignFromArchive(
        archive,
        manifestJson,
        extractDir,
        prefix: '',
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to parse file',
        tag: 'DesignFile',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Import — Multiple Designs (Folder)
  // ---------------------------------------------------------------------------

  /// Parses a folder-type `.appshots` zip bundle and returns a
  /// [FolderImportResult] with all assets extracted.
  Future<FolderImportResult?> parseMultipleFromFile(File file) async {
    try {
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Read root manifest
      final manifestFile = archive.findFile('manifest.json');
      if (manifestFile == null) return null;
      final rootJson =
          jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
      if (rootJson['type'] != 'screenshot_folder') return null;

      final folderName = rootJson['folderName'] as String? ?? 'Imported Folder';
      final designCount = rootJson['designCount'] as int? ?? 0;
      final extractDir = await _createExtractDir();

      final designs = <SavedDesign>[];
      for (int i = 0; i < designCount; i++) {
        final subManifest = archive.findFile('$i/manifest.json');
        if (subManifest == null) continue;
        final subJson =
            jsonDecode(utf8.decode(subManifest.content))
                as Map<String, dynamic>;

        final design = await _extractDesignFromArchive(
          archive,
          subJson,
          extractDir,
          prefix: '$i/',
        );
        if (design != null) designs.add(design);
      }

      return FolderImportResult(folderName: folderName, designs: designs);
    } catch (e, st) {
      AppLogger.error(
        'Failed to parse multi file',
        tag: 'DesignFile',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Private — Archive building helpers
  // ---------------------------------------------------------------------------

  /// Adds a single design and all its assets to [archive] under [prefix].
  Future<void> _addDesignToArchive(
    Archive archive,
    SavedDesign design, {
    required String prefix,
  }) async {
    // Collect asset paths for the manifest
    final assetMap = <String, String>{}; // key → zip-relative path

    // 1. Thumbnail
    if (design.thumbnailPath.isNotEmpty) {
      final thumbFile = File(design.thumbnailPath);
      if (await thumbFile.exists()) {
        final ext = p.extension(thumbFile.path).isNotEmpty
            ? p.extension(thumbFile.path)
            : '.png';
        final zipPath = '${prefix}thumbnail$ext';
        archive.addFile(
          ArchiveFile.bytes(zipPath, await thumbFile.readAsBytes()),
        );
        assetMap['thumbnail'] = zipPath;
      }
    }

    // 2. Main screenshot image
    if (design.imagePath != null) {
      final imgFile = File(design.imagePath!);
      if (await imgFile.exists()) {
        final ext = p.extension(imgFile.path).isNotEmpty
            ? p.extension(imgFile.path)
            : '.png';
        final zipPath = '${prefix}screenshot$ext';
        archive.addFile(
          ArchiveFile.bytes(zipPath, await imgFile.readAsBytes()),
        );
        assetMap['screenshot'] = zipPath;
      }
    }

    // 3. Multi-canvas images
    if (design.imagePaths != null) {
      for (int i = 0; i < design.imagePaths!.length; i++) {
        final path = design.imagePaths![i];
        if (path == null) continue;
        final imgFile = File(path);
        if (await imgFile.exists()) {
          final ext = p.extension(imgFile.path).isNotEmpty
              ? p.extension(imgFile.path)
              : '.png';
          final zipPath = '${prefix}screenshots/$i$ext';
          archive.addFile(
            ArchiveFile.bytes(zipPath, await imgFile.readAsBytes()),
          );
          assetMap['screenshot_$i'] = zipPath;
        }
      }
    }

    // 4. Image overlays from all designs
    final allDesigns = [design.design, ...?design.multiDesigns];
    int overlayIndex = 0;
    for (final d in allDesigns) {
      for (final overlay in d.imageOverlays) {
        if (overlay.filePath != null) {
          final overlayFile = File(overlay.filePath!);
          if (await overlayFile.exists()) {
            final ext = p.extension(overlayFile.path).isNotEmpty
                ? p.extension(overlayFile.path)
                : '.png';
            final zipPath = '${prefix}overlays/$overlayIndex$ext';
            archive.addFile(
              ArchiveFile.bytes(zipPath, await overlayFile.readAsBytes()),
            );
            assetMap['overlay_$overlayIndex'] = zipPath;
          }
        }
        overlayIndex++;
      }
    }

    // Build manifest
    final manifest = {
      'version': _currentVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'screenshot_design',
      'assets': assetMap,
      'design': _designToExportJson(design),
    };

    archive.addFile(
      ArchiveFile.bytes(
        '${prefix}manifest.json',
        utf8.encode(jsonEncode(manifest)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private — Archive extraction helpers
  // ---------------------------------------------------------------------------

  Future<Directory> _createExtractDir() async {
    final dir = await _tempDir;
    final extractDir = Directory(
      '${dir.path}/appshots_import_${DateTime.now().millisecondsSinceEpoch}',
    );
    await extractDir.create(recursive: true);
    return extractDir;
  }

  /// Extracts a single design from [archive] and returns the parsed
  /// [SavedDesign] with all asset paths pointing to local files.
  Future<SavedDesign?> _extractDesignFromArchive(
    Archive archive,
    Map<String, dynamic> manifestJson,
    Directory extractDir, {
    required String prefix,
  }) async {
    try {
      final assets = (manifestJson['assets'] as Map<String, dynamic>?) ?? {};
      final designJson = manifestJson['design'] as Map<String, dynamic>;
      final newId = const Uuid().v4();

      // Extract all asset files
      final extractedPaths = <String, String>{}; // assetKey → local path
      for (final entry in assets.entries) {
        final archiveFile = archive.findFile(entry.value as String);
        if (archiveFile != null) {
          final ext = p.extension(entry.value as String);
          final localFile = File(
            '${extractDir.path}/${newId}_${entry.key}$ext',
          );
          await localFile.writeAsBytes(archiveFile.content);
          extractedPaths[entry.key] = localFile.path;
        }
      }

      // Build SavedDesign with remapped paths
      final parsedDesign = ScreenshotDesign.fromJson(
        designJson['design'] as Map<String, dynamic>,
      );

      // Remap image overlay paths
      final remappedDesign = _remapOverlayPaths(
        parsedDesign,
        extractedPaths,
        0,
      );

      // Remap multi-designs
      List<ScreenshotDesign>? multiDesigns;
      int overlayOffset = parsedDesign.imageOverlays.length;
      if (designJson.containsKey('multiDesigns')) {
        multiDesigns = [];
        for (final d in designJson['multiDesigns'] as List) {
          final md = ScreenshotDesign.fromJson(d as Map<String, dynamic>);
          multiDesigns.add(
            _remapOverlayPaths(md, extractedPaths, overlayOffset),
          );
          overlayOffset += md.imageOverlays.length;
        }
      }

      // Remap multi-canvas image paths
      List<String?>? imagePaths;
      if (designJson.containsKey('imagePaths')) {
        final count = (designJson['imagePaths'] as List).length;
        imagePaths = List.generate(count, (i) {
          return extractedPaths['screenshot_$i'];
        });
      }

      return SavedDesign(
        id: newId,
        name: designJson['name'] ?? 'Imported Design',
        lastModified: DateTime.now(),
        thumbnailPath: extractedPaths['thumbnail'] ?? '',
        imagePath: extractedPaths['screenshot'],
        design: remappedDesign,
        multiDesigns: multiDesigns,
        imagePaths: imagePaths,
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to extract design',
        tag: 'DesignFile',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Remaps [ImageOverlay.filePath] in a design using extracted paths.
  ScreenshotDesign _remapOverlayPaths(
    ScreenshotDesign design,
    Map<String, String> extractedPaths,
    int overlayOffset,
  ) {
    if (design.imageOverlays.isEmpty) return design;

    final remapped = <ImageOverlay>[];
    for (int i = 0; i < design.imageOverlays.length; i++) {
      final overlay = design.imageOverlays[i];
      final key = 'overlay_${overlayOffset + i}';
      if (overlay.filePath != null && extractedPaths.containsKey(key)) {
        remapped.add(overlay.copyWith(filePath: extractedPaths[key]));
      } else {
        remapped.add(overlay);
      }
    }
    return design.copyWith(imageOverlays: remapped);
  }

  // ---------------------------------------------------------------------------
  // Private — Serialization helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _designToExportJson(SavedDesign design) {
    final json = <String, dynamic>{
      'id': design.id,
      'name': design.name,
      'lastModified': design.lastModified.toIso8601String(),
      'design': design.design.toJson(),
    };

    if (design.multiDesigns != null && design.multiDesigns!.isNotEmpty) {
      json['multiDesigns'] = design.multiDesigns!
          .map((d) => d.toJson())
          .toList();
    }

    if (design.imagePaths != null) {
      json['imagePaths'] = design.imagePaths;
    }

    return json;
  }

  // ---------------------------------------------------------------------------
  // Private — File I/O
  // ---------------------------------------------------------------------------

  Future<File> _writeArchiveToFile(Archive archive, String baseName) async {
    final dir = await _tempDir;
    final safeName = baseName
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final fileName = '$safeName$_fileExtension';
    final file = File('${dir.path}/$fileName');
    final zipBytes = ZipEncoder().encode(archive);
    await file.writeAsBytes(zipBytes);
    return file;
  }
}
