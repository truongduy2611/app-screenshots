import 'dart:io';

import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/design_file_service.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DesignFileService service;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('design_file_test_');
    service = DesignFileService(tempDirOverride: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  SavedDesign createTestDesign({
    String id = 'test-id-123',
    String name = 'My Test Design',
    bool isMulti = false,
    String? thumbnailPath,
    String? imagePath,
    List<ImageOverlay>? imageOverlays,
  }) {
    final design = ScreenshotDesign(
      backgroundColor: const Color(0xFF112233),
      padding: 16.0,
      displayType: 'iphone_6_7_inch',
      cornerRadius: 12.0,
      imageOverlays: imageOverlays ?? [],
    );

    return SavedDesign(
      id: id,
      name: name,
      lastModified: DateTime(2025, 1, 15, 10, 30),
      thumbnailPath: thumbnailPath ?? '',
      imagePath: imagePath,
      design: design,
      multiDesigns: isMulti ? [design, design] : null,
      imagePaths: isMulti ? [null, null] : null,
    );
  }

  /// Creates a temporary PNG-like file and returns its path.
  String createTempImage(String name) {
    final file = File('${tempDir.path}/$name');
    // Write a minimal valid-ish file (doesn't need to be real PNG for tests)
    file.writeAsBytesSync([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    return file.path;
  }

  group('DesignFileService', () {
    group('createExportFile', () {
      test('creates a valid .appshots zip file', () async {
        final design = createTestDesign();

        final file = await service.createExportFile(design);

        expect(file.existsSync(), isTrue);
        expect(file.path.endsWith('.appshots'), isTrue);
      });

      test('file name is sanitized from design name', () async {
        final design = createTestDesign(name: 'My Design / Test!');

        final file = await service.createExportFile(design);

        expect(file.path, contains('My_Design__Test'));
      });

      test('exported file is a valid zip archive', () async {
        final design = createTestDesign();

        final file = await service.createExportFile(design);
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        expect(archive.files, isNotEmpty);
      });

      test('exported zip contains manifest.json', () async {
        final design = createTestDesign();

        final file = await service.createExportFile(design);
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        final manifest = archive.findFile('manifest.json');
        expect(manifest, isNotNull);
      });

      test('exported zip contains thumbnail when present', () async {
        final thumbPath = createTempImage('thumb.png');
        final design = createTestDesign(thumbnailPath: thumbPath);

        final file = await service.createExportFile(design);
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        final thumb = archive.findFile('thumbnail.png');
        expect(thumb, isNotNull);
      });

      test('exported zip contains screenshot when present', () async {
        final imgPath = createTempImage('screenshot.png');
        final design = createTestDesign(imagePath: imgPath);

        final file = await service.createExportFile(design);
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        final screenshot = archive.findFile('screenshot.png');
        expect(screenshot, isNotNull);
      });
    });

    group('parseExportFile', () {
      test('parses a valid .appshots zip file back to SavedDesign', () async {
        final design = createTestDesign();

        final file = await service.createExportFile(design);
        final result = await service.parseExportFile(file);

        expect(result, isNotNull);
        expect(result!.name, 'My Test Design');
      });

      test('round-trip preserves design name', () async {
        final original = createTestDesign(name: 'Round Trip Test');

        final file = await service.createExportFile(original);
        final parsed = await service.parseExportFile(file);

        expect(parsed!.name, 'Round Trip Test');
      });

      test('round-trip preserves design properties', () async {
        final original = createTestDesign();

        final file = await service.createExportFile(original);
        final parsed = await service.parseExportFile(file);

        expect(parsed!.design.padding, 16.0);
        expect(parsed.design.cornerRadius, 12.0);
        expect(parsed.design.displayType, 'iphone_6_7_inch');
      });

      test('round-trip preserves multi-canvas designs', () async {
        final original = createTestDesign(isMulti: true);

        final file = await service.createExportFile(original);
        final parsed = await service.parseExportFile(file);

        expect(parsed!.isMulti, isTrue);
        expect(parsed.multiDesigns!.length, 2);
      });

      test('round-trip preserves thumbnail asset', () async {
        final thumbPath = createTempImage('thumb.png');
        final original = createTestDesign(thumbnailPath: thumbPath);

        final file = await service.createExportFile(original);
        final parsed = await service.parseExportFile(file);

        expect(parsed, isNotNull);
        expect(parsed!.thumbnailPath, isNotEmpty);
        expect(File(parsed.thumbnailPath).existsSync(), isTrue);
      });

      test('round-trip preserves screenshot asset', () async {
        final imgPath = createTempImage('screenshot.png');
        final original = createTestDesign(imagePath: imgPath);

        final file = await service.createExportFile(original);
        final parsed = await service.parseExportFile(file);

        expect(parsed, isNotNull);
        expect(parsed!.imagePath, isNotNull);
        expect(File(parsed.imagePath!).existsSync(), isTrue);
      });

      test('returns null for invalid data', () async {
        final file = File('${tempDir.path}/invalid.appshots');
        await file.writeAsString('not a zip at all');

        final result = await service.parseExportFile(file);

        expect(result, isNull);
      });

      test('returns null for non-existent file', () async {
        final file = File('${tempDir.path}/nonexistent.appshots');

        final result = await service.parseExportFile(file);

        expect(result, isNull);
      });

      test('parsed design gets a new ID', () async {
        final original = createTestDesign(id: 'original-id');

        final file = await service.createExportFile(original);
        final parsed = await service.parseExportFile(file);

        expect(parsed!.id, isNot('original-id'));
      });
    });

    group('createExportFileForMultiple', () {
      test('creates file containing multiple designs', () async {
        final designs = [
          createTestDesign(id: 'id-1', name: 'Design 1'),
          createTestDesign(id: 'id-2', name: 'Design 2'),
        ];

        final file = await service.createExportFileForMultiple(
          designs,
          folderName: 'My Folder',
        );

        expect(file.existsSync(), isTrue);
        expect(file.path.endsWith('.appshots'), isTrue);

        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        // Root manifest + 2 sub-manifests
        final rootManifest = archive.findFile('manifest.json');
        expect(rootManifest, isNotNull);

        final sub0 = archive.findFile('0/manifest.json');
        expect(sub0, isNotNull);

        final sub1 = archive.findFile('1/manifest.json');
        expect(sub1, isNotNull);
      });
    });

    group('parseMultipleFromFile', () {
      test('parses multiple designs from folder export', () async {
        final designs = [
          createTestDesign(id: 'id-1', name: 'Design 1'),
          createTestDesign(id: 'id-2', name: 'Design 2'),
        ];

        final file = await service.createExportFileForMultiple(
          designs,
          folderName: 'My Folder',
        );

        final result = await service.parseMultipleFromFile(file);

        expect(result, isNotNull);
        expect(result!.designs.length, 2);
        expect(result.folderName, 'My Folder');
        expect(result.designs[0].name, 'Design 1');
        expect(result.designs[1].name, 'Design 2');
      });

      test('each imported design gets a unique new ID', () async {
        final designs = [
          createTestDesign(id: 'same-id', name: 'Design 1'),
          createTestDesign(id: 'same-id', name: 'Design 2'),
        ];

        final file = await service.createExportFileForMultiple(
          designs,
          folderName: 'Folder',
        );

        final result = await service.parseMultipleFromFile(file);

        expect(result!.designs[0].id, isNot(result.designs[1].id));
      });

      test('returns null for invalid file', () async {
        final file = File('${tempDir.path}/bad_multi.appshots');
        await file.writeAsString('bad');

        final result = await service.parseMultipleFromFile(file);

        expect(result, isNull);
      });
    });
  });
}
