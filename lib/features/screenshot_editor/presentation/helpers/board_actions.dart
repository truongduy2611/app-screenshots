import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/crop_zone.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/board_export_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/board_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/design_share_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Export, save, share, and clipboard actions for the board editor.
///
/// Every image-producing action funnels through [captureBoard] + a crop pass,
/// so a board with ten crop zones costs one capture instead of ten.
///
/// The host state must supply [screenshotController], [syncBoardBackground],
/// and [setExporting].
mixin BoardActions<T extends StatefulWidget> on State<T> {
  ScreenshotController get screenshotController;

  /// Pushes the live background/overlay design from [ScreenshotEditorCubit]
  /// into the board before it is captured or persisted.
  void syncBoardBackground();

  void setExporting(bool value);

  // ---------------------------------------------------------------------------
  // Capture
  // ---------------------------------------------------------------------------

  /// Waits for every frame image and pending Google Font to be ready, then
  /// lets two frames pass so the board is fully painted before capture.
  Future<void> _waitForBoardSettled() async {
    final boardCubit = context.read<BoardCubit>();
    final waits = <Future<void>>[GoogleFonts.pendingFonts()];

    for (final frame in boardCubit.state.board.frames) {
      final path = frame.imagePath;
      if (path == null) continue;
      final file = File(path);
      if (file.existsSync()) {
        waits.add(precacheImage(FileImage(file), context));
      }
    }

    await Future.wait(waits);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    // Margin for post-frame layout settling that endOfFrame alone misses.
    await Future.delayed(const Duration(milliseconds: 32));
  }

  /// Captures the whole board once.
  ///
  /// Grid guides and selection chrome are hidden first so they never land in
  /// the exported pixels. Callers own the returned image and must dispose it.
  Future<(ui.Image, double)?> captureBoard() async {
    final editorCubit = context.read<ScreenshotEditorCubit>();
    final boardCubit = context.read<BoardCubit>();

    editorCubit.hideGridForCapture();

    // Selection chrome must be off the canvas for the capture, but the
    // selection itself has to survive it: "export current zone" resolves its
    // target from the selection, so dropping it here silently redirected every
    // export after the first one to zone 1. Restored below like the grid.
    final selectedZoneId = boardCubit.state.selectedZoneId;
    final selectedFrameId = boardCubit.state.selectedFrameId;
    boardCubit.clearSelection();

    try {
      await _waitForBoardSettled();
      if (!mounted) return null;

      final scale = BoardExportService.captureScaleFor(
        boardCubit.state.board.size,
      );
      final image = await screenshotController.captureAsUiImage(
        pixelRatio: scale,
      );
      if (image == null) return null;
      return (image, scale);
    } catch (e, st) {
      AppLogger.error(
        'Board capture failed',
        tag: 'BoardActions',
        error: e,
        stackTrace: st,
      );
      return null;
    } finally {
      if (mounted) {
        editorCubit.restoreGridAfterCapture();
        if (selectedZoneId != null) {
          boardCubit.selectZone(selectedZoneId);
        } else if (selectedFrameId != null) {
          boardCubit.selectFrame(selectedFrameId);
        }
      }
    }
  }

  /// Captures the board and crops [zones] out of it. Returns `null` when the
  /// capture fails; an empty zone list yields an empty result.
  Future<BoardExportResult?> renderZones(List<CropZone> zones) async {
    syncBoardBackground();
    // Read before the capture's async gap — the value is unchanged by capture
    // (hideGridForCapture only touches grid settings and selection).
    final transparent = context
        .read<ScreenshotEditorCubit>()
        .state
        .design
        .transparentBackground;

    final captured = await captureBoard();
    if (captured == null) return null;

    final (image, scale) = captured;
    try {
      return await BoardExportService.cropZones(
        boardImage: image,
        zones: zones,
        captureScale: scale,
        stripAlpha: !transparent,
      );
    } finally {
      image.dispose();
    }
  }

  void _warnIfDownscaled(BuildContext context, BoardExportResult result) {
    if (!result.wasDownscaled) return;
    final board = context.read<BoardCubit>().state.board;
    context.showAppSnackbar(
      context.l10n.boardTooLargeToCapture(
        (board.pixelCount / 1000000).round(),
      ),
      type: AppSnackbarType.info,
    );
  }

  /// A zone whose crop failed is skipped rather than aborting the whole export,
  /// so say so — otherwise the user gets fewer files than zones with no clue
  /// which ones are missing.
  void _warnIfZonesDropped(
    BuildContext context,
    List<CropZone> requested,
    BoardExportResult result,
  ) {
    final dropped = requested.length - result.images.length;
    if (dropped <= 0) return;
    AppLogger.w(
      'Board export produced ${result.images.length} of ${requested.length} '
      'zones — $dropped could not be cropped',
      tag: 'BoardActions',
    );
    context.showAppSnackbar(
      context.l10n.someZonesFailedToExport(dropped, requested.length),
      type: AppSnackbarType.error,
    );
  }

  // ---------------------------------------------------------------------------
  // Export all zones
  // ---------------------------------------------------------------------------

  Future<void> exportAllZones(BuildContext context) async {
    final zones = context.read<BoardCubit>().state.board.exportableZones;
    if (zones.isEmpty) {
      context.showAppSnackbar(
        context.l10n.noCropZonesToExport,
        type: AppSnackbarType.error,
      );
      return;
    }

    setExporting(true);
    try {
      final result = await renderZones(zones);
      if (!mounted || result == null || result.images.isEmpty) {
        if (context.mounted) {
          context.showAppSnackbar(
            context.l10n.failedToExport,
            type: AppSnackbarType.error,
          );
        }
        return;
      }

      if (!context.mounted) return;
      _warnIfDownscaled(context, result);
      _warnIfZonesDropped(context, zones, result);

      if (Platform.isIOS || Platform.isAndroid) {
        final tempDir = await getTemporaryDirectory();
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final xFiles = <XFile>[];
        for (final image in result.images) {
          final file = File('${tempDir.path}/${stamp}_${image.fileName}');
          await file.writeAsBytes(image.bytes);
          xFiles.add(XFile(file.path));
        }
        if (!context.mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: xFiles,
            text: context.l10n.appTitle,
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : Rect.zero,
          ),
        );
        return;
      }

      final dir = await FilePicker.getDirectoryPath(
        dialogTitle: context.mounted ? context.l10n.selectExportFolder : null,
      );
      if (dir == null) return;

      final stamp = DateTime.now().millisecondsSinceEpoch;
      for (final image in result.images) {
        await File('$dir/${stamp}_${image.fileName}').writeAsBytes(image.bytes);
      }

      if (!context.mounted) return;
      context.showAppSnackbar(
        '${context.l10n.exportedSuccessfully} (${result.images.length})',
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to export board zones',
        tag: 'BoardActions',
        error: e,
        stackTrace: st,
      );
      if (!context.mounted) return;
      context.showAppSnackbar(
        '${context.l10n.failedToExport}: $e',
        type: AppSnackbarType.error,
      );
    } finally {
      if (mounted) setExporting(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Export / copy a single zone
  // ---------------------------------------------------------------------------

  /// The zone a single-image action operates on: the selected one, else the
  /// first zone marked for export.
  CropZone? currentZone(BuildContext context) {
    final state = context.read<BoardCubit>().state;
    return state.selectedZone ?? state.board.exportableZones.firstOrNull;
  }

  Future<void> exportCurrentZone(BuildContext context) async {
    final zone = currentZone(context);
    if (zone == null) {
      context.showAppSnackbar(
        context.l10n.noCropZonesToExport,
        type: AppSnackbarType.error,
      );
      return;
    }

    setExporting(true);
    try {
      final result = await renderZones([zone]);
      if (!mounted || result == null || result.images.isEmpty) {
        throw Exception('Failed to capture board');
      }
      final bytes = result.images.first.bytes;
      final fileName = 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';

      if (Platform.isIOS || Platform.isAndroid) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        if (!context.mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'App Screenshot',
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : Rect.zero,
          ),
        );
        return;
      }

      if (!context.mounted) return;
      // saveFile already writes `bytes` to the chosen path on desktop; writing
      // again here would just duplicate the work.
      final path = await FilePicker.saveFile(
        dialogTitle: context.l10n.export,
        fileName: fileName,
        bytes: bytes,
      );
      if (path == null) return;

      if (!context.mounted) return;
      context.showAppSnackbar(context.l10n.exportedSuccessfully);
    } catch (e, st) {
      AppLogger.error(
        'Failed to export zone',
        tag: 'BoardActions',
        error: e,
        stackTrace: st,
      );
      if (!context.mounted) return;
      context.showAppSnackbar(
        '${context.l10n.failedToExport}: $e',
        type: AppSnackbarType.error,
      );
    } finally {
      if (mounted) setExporting(false);
    }
  }

  Future<void> copyCurrentZoneToClipboard(BuildContext context) async {
    final zone = currentZone(context);
    if (zone == null) {
      context.showAppSnackbar(
        context.l10n.noCropZonesToExport,
        type: AppSnackbarType.error,
      );
      return;
    }

    setExporting(true);
    try {
      final result = await renderZones([zone]);
      if (result == null || result.images.isEmpty) {
        throw Exception('Failed to capture board');
      }
      await Pasteboard.writeImage(result.images.first.bytes);
      if (!context.mounted) return;
      context.showAppSnackbar(context.l10n.copiedToClipboard);
    } catch (e, st) {
      AppLogger.error(
        'Failed to copy zone',
        tag: 'BoardActions',
        error: e,
        stackTrace: st,
      );
      if (!context.mounted) return;
      context.showAppSnackbar(
        '${context.l10n.failedToExport}: $e',
        type: AppSnackbarType.error,
      );
    } finally {
      if (mounted) setExporting(false);
    }
  }

  Future<void> pasteImageIntoBoard(BuildContext context) async {
    try {
      final bytes = await Pasteboard.image;
      if (bytes == null) {
        if (!context.mounted) return;
        context.showAppSnackbar(
          context.l10n.noImageInClipboard,
          type: AppSnackbarType.info,
        );
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/clipboard_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      if (!context.mounted) return;
      await context.read<BoardCubit>().importImages([file]);
    } catch (e, st) {
      AppLogger.error(
        'Failed to paste image',
        tag: 'BoardActions',
        error: e,
        stackTrace: st,
      );
      if (!context.mounted) return;
      context.showAppSnackbar(
        '${context.l10n.failedToExport}: $e',
        type: AppSnackbarType.error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Locale rendering (ASC / Play upload)
  // ---------------------------------------------------------------------------

  /// Deletes `board_upload_*` staging directories from earlier sessions.
  ///
  /// A full localized render is one directory of PNGs per locale, so these add
  /// up fast. Only directories older than a day are touched, well clear of any
  /// upload still holding on to the current one. Best-effort — a failure here
  /// must never block an export.
  static Future<void> _pruneOldUploadDirs(Directory tempDir) async {
    const maxAge = Duration(days: 1);
    try {
      final now = DateTime.now();
      await for (final entity in tempDir.list()) {
        if (entity is! Directory) continue;
        if (!p.basename(entity.path).startsWith('board_upload_')) continue;
        final stat = await entity.stat();
        if (now.difference(stat.modified) < maxAge) continue;
        await entity.delete(recursive: true);
      }
    } catch (e) {
      AppLogger.w('Could not prune old board upload dirs: $e',
          tag: 'BoardActions');
    }
  }

  /// Renders every exportable zone for each translated locale and returns a
  /// `Map<locale, List<File>>` of PNGs in a temp directory.
  ///
  /// One board capture per locale — not one per (locale, screenshot) — which
  /// is the whole point of board mode for large localized projects.
  Future<Map<String, List<File>>?> captureAllLocaleScreenshots(
    BuildContext context, {
    Set<String>? selectedLocales,
  }) async {
    final boardCubit = context.read<BoardCubit>();
    final translationCubit = context.read<TranslationCubit>();
    final bundle = translationCubit.state.bundle;

    final zones = boardCubit.state.board.exportableZones;
    if (zones.isEmpty) return null;

    final hasTranslations = bundle != null && bundle.translations.isNotEmpty;
    final sourceLocale = bundle?.sourceLocale ?? 'en-US';
    var allLocales = hasTranslations
        ? [sourceLocale, ...bundle.targetLocales]
        : [sourceLocale];
    if (selectedLocales != null && selectedLocales.isNotEmpty) {
      allLocales = allLocales
          .where((l) => selectedLocales.contains(l))
          .toList();
    }

    setExporting(true);
    try {
      final tempDir = await getTemporaryDirectory();
      await _pruneOldUploadDirs(tempDir);
      final exportDir = Directory(
        '${tempDir.path}/board_upload_${DateTime.now().millisecondsSinceEpoch}',
      );
      await exportDir.create(recursive: true);

      final result = <String, List<File>>{};

      for (final locale in allLocales) {
        if (hasTranslations) {
          translationCubit.setPreviewLocale(
            locale == sourceLocale ? null : locale,
          );
        }

        final rendered = await renderZones(zones);
        if (!mounted) break;
        if (rendered == null || rendered.images.isEmpty) continue;

        final localeDir = Directory('${exportDir.path}/$locale');
        await localeDir.create(recursive: true);

        final files = <File>[];
        for (final image in rendered.images) {
          final file = File('${localeDir.path}/${image.fileName}');
          await file.writeAsBytes(image.bytes);
          files.add(file);
        }
        if (files.isNotEmpty) result[locale] = files;
      }

      if (hasTranslations) translationCubit.setPreviewLocale(null);

      if (result.isNotEmpty && mounted) {
        boardCubit.setLastRenderedAscPath(exportDir.path);
        return result;
      }
      return null;
    } catch (e, st) {
      if (hasTranslations) translationCubit.setPreviewLocale(null);
      AppLogger.error(
        'captureAllLocaleScreenshots failed',
        tag: 'BoardActions',
        error: e,
        stackTrace: st,
      );
      return null;
    } finally {
      if (mounted) setExporting(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Renders a thumbnail for the library: the first exportable zone, falling
  /// back to the first zone of any kind.
  Future<Uint8List?> renderThumbnail() async {
    final board = context.read<BoardCubit>().state.board;
    final zone = board.exportableZones.firstOrNull ?? board.cropZones.firstOrNull;
    if (zone == null) return null;
    final result = await renderZones([zone]);
    return result?.images.firstOrNull?.bytes;
  }

  Future<void> saveBoardToLibrary(
    BuildContext context, {
    bool override = false,
  }) async {
    syncBoardBackground();
    final boardCubit = context.read<BoardCubit>();

    setExporting(true);
    Uint8List? thumbnail;
    try {
      thumbnail = await renderThumbnail();
    } finally {
      if (mounted) setExporting(false);
    }

    if (thumbnail == null) {
      if (!context.mounted) return;
      context.showAppSnackbar(
        context.l10n.failedToExport,
        type: AppSnackbarType.error,
      );
      return;
    }

    if (!context.mounted) return;

    String name;
    if (override && boardCubit.state.savedDesignName != null) {
      name = boardCubit.state.savedDesignName!;
    } else {
      final controller = TextEditingController(text: boardCubit.defaultName());
      final String? result;
      try {
        result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.l10n.saveAs),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: ctx.l10n.designName),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: Text(ctx.l10n.save),
              ),
            ],
          ),
        );
      } finally {
        controller.dispose();
      }
      if (result == null || result.isEmpty) return;
      name = result;
    }

    if (!context.mounted) return;
    await boardCubit.saveDesign(
      name,
      thumbnail,
      override: override,
      translationBundle: context.read<TranslationCubit>().state.bundle,
    );

    if (!context.mounted) return;
    context.showAppSnackbar(context.l10n.savedToLibrary);
  }

  Future<void> shareBoardFile(BuildContext context) async {
    try {
      syncBoardBackground();
      final boardCubit = context.read<BoardCubit>();
      final design = boardCubit.toSavedDesign(
        name: boardCubit.state.savedDesignName ?? boardCubit.defaultName(),
        translationBundle: context.read<TranslationCubit>().state.bundle,
      );
      await DesignShareHelper.shareDesign(context, design);
    } catch (e, st) {
      AppLogger.error(
        'Failed to share board file',
        tag: 'BoardActions',
        error: e,
        stackTrace: st,
      );
      if (!context.mounted) return;
      context.showAppSnackbar(
        '${context.l10n.failedToExport}: $e',
        type: AppSnackbarType.error,
      );
    }
  }

  Future<void> saveBoardToFile(BuildContext context) async {
    try {
      syncBoardBackground();
      final boardCubit = context.read<BoardCubit>();
      final sourceFilePath = boardCubit.state.sourceFilePath;
      if (sourceFilePath == null) return;

      final design = boardCubit.toSavedDesign(
        name: boardCubit.state.savedDesignName ?? boardCubit.defaultName(),
        translationBundle: context.read<TranslationCubit>().state.bundle,
      );
      await DesignShareHelper.saveToFile(design, sourceFilePath);

      if (!context.mounted) return;
      context.showAppSnackbar(context.l10n.savedToFile);
    } catch (e, st) {
      AppLogger.error(
        'Failed to save board to file',
        tag: 'BoardActions',
        error: e,
        stackTrace: st,
      );
      if (!context.mounted) return;
      context.showAppSnackbar(
        '${context.l10n.failedToExport}: $e',
        type: AppSnackbarType.error,
      );
    }
  }
}
