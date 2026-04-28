import 'dart:io';

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/design_share_helper.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Top-level function for [compute] – strips alpha channel from a captured PNG
/// unless the design uses a transparent background.
Uint8List processScreenshot((Uint8List, bool) args) {
  final (bytes, isTransparent) = args;
  if (isTransparent) return bytes;
  final image = img.decodePng(bytes);
  if (image == null) return bytes;
  return img.encodePng(image.convert(numChannels: 3));
}

/// Mixin providing export, save, share, and clipboard actions for the
/// multi-screenshot editor.
///
/// The host state must supply [screenshotController], [syncEditorChangesBack],
/// and [setExporting].
mixin MultiScreenshotActions<T extends StatefulWidget> on State<T> {
  ScreenshotController get screenshotController;
  void syncEditorChangesBack();
  void setExporting(bool value);

  // ---------------------------------------------------------------------------
  // Image picking & capture
  // ---------------------------------------------------------------------------

  Future<void> pickImage(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      if (!context.mounted) return;
      context.read<ScreenshotEditorCubit>().updateImageFile(
        File(result.files.single.path!),
      );
    }
  }

  Future<void> pasteImageFromClipboard(BuildContext context) async {
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
      context.read<ScreenshotEditorCubit>().updateImageFile(file);
    } catch (e, st) {
      AppLogger.error(
        'Failed to paste image from clipboard',
        tag: 'MultiActions',
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

  Future<Uint8List?> captureImage() async {
    try {
      final editorCubit = context.read<ScreenshotEditorCubit>();
      editorCubit.hideGridForCapture();
      await Future.delayed(const Duration(milliseconds: 50));

      final bytes = await screenshotController.capture(pixelRatio: 1.0);

      editorCubit.restoreGridAfterCapture();

      if (bytes == null) return null;
      final isTransparent = editorCubit.state.design.transparentBackground;
      return compute(processScreenshot, (bytes, isTransparent));
    } catch (e, st) {
      if (!context.mounted) return null;
      context.read<ScreenshotEditorCubit>().restoreGridAfterCapture();
      AppLogger.error(
        'Capture failed',
        tag: 'MultiActions',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Export single
  // ---------------------------------------------------------------------------

  Future<void> exportSingle(BuildContext context) async {
    try {
      syncEditorChangesBack();
      final bytes = await captureImage();

      if (bytes == null) {
        throw Exception('Failed to capture screenshot');
      }

      final fileName =
          'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';

      if (Platform.isIOS || Platform.isAndroid) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/$fileName').create();
        await file.writeAsBytes(bytes);
        if (!context.mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        final shareOrigin = box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.zero;

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'App Screenshot',
            sharePositionOrigin: shareOrigin,
          ),
        );
        return;
      }

      if (!context.mounted) return;
      final path = await FilePicker.platform.saveFile(
        dialogTitle: context.l10n.export,
        fileName: fileName,
      );

      if (path == null) return;

      final file = File(path);
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;
      context.showAppSnackbar(context.l10n.exportedSuccessfully);
    } catch (e, st) {
      AppLogger.error(
        'Failed to export single',
        tag: 'MultiActions',
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
  // Copy to clipboard
  // ---------------------------------------------------------------------------

  Future<void> copyToClipboard(BuildContext context) async {
    try {
      syncEditorChangesBack();
      final bytes = await captureImage();
      if (bytes == null) {
        throw Exception('Failed to capture screenshot');
      }
      await Pasteboard.writeImage(bytes);
      if (!context.mounted) return;
      context.showAppSnackbar(context.l10n.copiedToClipboard);
    } catch (e, st) {
      AppLogger.error(
        'Failed to copy to clipboard',
        tag: 'MultiActions',
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
  // Share design file
  // ---------------------------------------------------------------------------

  Future<void> shareDesignFile(BuildContext context) async {
    try {
      syncEditorChangesBack();
      final multiState = context.read<MultiScreenshotCubit>().state;
      final translationBundle = context.read<TranslationCubit>().state.bundle;
      final designs = multiState.designs;
      final design = SavedDesign(
        id: multiState.savedDesignId ?? 'unsaved',
        name: multiState.savedDesignName ?? 'Screenshot Design',
        lastModified: DateTime.now(),
        thumbnailPath: '',
        design: designs.first,
        multiDesigns: designs.length > 1 ? designs : null,
        imagePaths: multiState.imageFiles.map((f) => f?.path).toList(),
        translationBundle: translationBundle,
        ascAppConfig: multiState.ascAppConfig,
      );
      await DesignShareHelper.shareDesign(context, design);
    } catch (e, st) {
      AppLogger.error(
        'Failed to share design file',
        tag: 'MultiActions',
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
  // Save to file
  // ---------------------------------------------------------------------------

  Future<void> saveToFile(BuildContext context) async {
    try {
      syncEditorChangesBack();
      final multiState = context.read<MultiScreenshotCubit>().state;
      final sourceFilePath = multiState.sourceFilePath;
      if (sourceFilePath == null) return;

      final translationBundle = context.read<TranslationCubit>().state.bundle;
      final designs = multiState.designs;
      final design = SavedDesign(
        id: multiState.savedDesignId ?? 'unsaved',
        name: multiState.savedDesignName ?? 'Screenshot Design',
        lastModified: DateTime.now(),
        thumbnailPath: '',
        design: designs.first,
        multiDesigns: designs.length > 1 ? designs : null,
        imagePaths: multiState.imageFiles.map((f) => f?.path).toList(),
        translationBundle: translationBundle,
        ascAppConfig: multiState.ascAppConfig,
      );
      await DesignShareHelper.saveToFile(design, sourceFilePath);

      if (!context.mounted) return;
      context.showAppSnackbar(context.l10n.savedToFile);
    } catch (e, st) {
      AppLogger.error(
        'Failed to save to file',
        tag: 'MultiActions',
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
  // Export all
  // ---------------------------------------------------------------------------

  Future<void> exportAll(BuildContext context) async {
    final multiCubit = context.read<MultiScreenshotCubit>();
    final editorCubit = context.read<ScreenshotEditorCubit>();
    final designCount = multiCubit.state.designs.length;

    setExporting(true);

    try {
      syncEditorChangesBack();
      final List<Uint8List> images = [];

      for (int i = 0; i < designCount; i++) {
        multiCubit.setActiveIndex(i);
        editorCubit.loadDesignForMultiMode(
          multiCubit.state.designs[i],
          imageFile: multiCubit.state.imageFiles[i],
        );
        await Future.delayed(const Duration(milliseconds: 200));
        final bytes = await captureImage();
        if (bytes != null) images.add(bytes);
      }

      if (!context.mounted || images.isEmpty) {
        if (context.mounted) {
          context.showAppSnackbar(
            context.l10n.failedToExport,
            type: AppSnackbarType.error,
          );
        }
        return;
      }

      if (Platform.isIOS || Platform.isAndroid) {
        final tempDir = await getTemporaryDirectory();
        final xFiles = <XFile>[];
        for (int i = 0; i < images.length; i++) {
          final file = File(
            '${tempDir.path}/screenshot_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await file.writeAsBytes(images[i]);
          xFiles.add(XFile(file.path));
        }
        if (!context.mounted) return;
        // TECH_DEBT: deprecated Share.shareXFiles — migrate to SharePlus.instance.share
        // ignore: deprecated_member_use
        await Share.shareXFiles(xFiles, text: context.l10n.appTitle);
      } else {
        final dir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: context.l10n.selectExportFolder,
        );
        if (dir == null) return;
        for (int i = 0; i < images.length; i++) {
          final file = File(
            '$dir/screenshot_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await file.writeAsBytes(images[i]);
        }
        if (!context.mounted) return;
        context.showAppSnackbar(
          '${context.l10n.exportedSuccessfully} (${images.length} images)',
        );
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to export all',
        tag: 'MultiActions',
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

  /// Renders all designs for each translated locale and returns
  /// a `Map<locale, List<File>>` of PNG files in a temp directory.
  ///
  /// Uses `previewLocale` on the [TranslationCubit] to swap overlay text
  /// to each locale's translations before capturing.
  ///
  /// If no translations exist, captures the current (source) locale only.
  ///
  /// When [selectedLocales] is provided, only those locales are rendered.
  Future<Map<String, List<File>>?> captureAllLocaleScreenshots(
    BuildContext context, {
    Set<String>? selectedLocales,
  }) async {
    final multiCubit = context.read<MultiScreenshotCubit>();
    final editorCubit = context.read<ScreenshotEditorCubit>();
    final translationCubit = context.read<TranslationCubit>();
    final bundle = translationCubit.state.bundle;

    final designCount = multiCubit.state.designs.length;

    // Determine the locales to capture.
    // If no translations, capture source locale only (no switching needed).
    final hasTranslations = bundle != null && bundle.translations.isNotEmpty;
    final sourceLocale = bundle?.sourceLocale ?? 'en-US';
    var allLocales = hasTranslations
        ? [sourceLocale, ...bundle.targetLocales]
        : [sourceLocale];

    // Filter to only selected locales when provided.
    if (selectedLocales != null && selectedLocales.isNotEmpty) {
      allLocales = allLocales
          .where((l) => selectedLocales.contains(l))
          .toList();
    }

    setExporting(true);

    try {
      syncEditorChangesBack();

      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory(
        '${tempDir.path}/asc_upload_${DateTime.now().millisecondsSinceEpoch}',
      );
      await exportDir.create(recursive: true);

      final result = <String, List<File>>{};

      for (final locale in allLocales) {
        // Set the preview locale so the canvas shows translated text.
        // null = source locale (original text).
        if (hasTranslations) {
          translationCubit.setPreviewLocale(
            locale == sourceLocale ? null : locale,
          );
        }

        final localeDir = Directory('${exportDir.path}/$locale');
        await localeDir.create(recursive: true);

        final files = <File>[];

        for (int i = 0; i < designCount; i++) {
          multiCubit.setActiveIndex(i);
          editorCubit.loadDesignForMultiMode(
            multiCubit.state.designs[i],
            imageFile: multiCubit.state.imageFiles[i],
          );
          // Wait for the UI to rebuild with the new locale text.
          await Future.delayed(const Duration(milliseconds: 300));

          final bytes = await captureImage();
          if (bytes != null) {
            final file = File('${localeDir.path}/screenshot_${i + 1}.png');
            await file.writeAsBytes(bytes);
            files.add(file);
          }
        }

        if (files.isNotEmpty) {
          result[locale] = files;
        }
      }

      // Restore to source locale preview.
      if (hasTranslations) {
        translationCubit.setPreviewLocale(null);
      }

      return result.isNotEmpty ? result : null;
    } catch (e, st) {
      if (hasTranslations) {
        translationCubit.setPreviewLocale(null);
      }
      AppLogger.error(
        'captureAllLocaleScreenshots failed',
        tag: 'MultiActions',
        error: e,
        stackTrace: st,
      );
      return null;
    } finally {
      if (mounted) setExporting(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Save to library
  // ---------------------------------------------------------------------------

  Future<void> saveToLibrary(
    BuildContext context, {
    bool override = false,
  }) async {
    syncEditorChangesBack();
    final bytes = await captureImage();
    if (bytes == null) {
      if (!context.mounted) return;
      context.showAppSnackbar(
        context.l10n.failedToExport,
        type: AppSnackbarType.error,
      );
      return;
    }

    if (!context.mounted) return;

    String name = '';

    if (override) {
      final multiState = context.read<MultiScreenshotCubit>().state;
      name =
          multiState.savedDesignName ??
          ScreenshotUtils.defaultDesignName(
            multiState.activeDesign?.displayType,
          );
    } else {
      final activeDisplayType = context
          .read<MultiScreenshotCubit>()
          .state
          .activeDesign
          ?.displayType;
      final nameController = TextEditingController(
        text: ScreenshotUtils.defaultDesignName(activeDisplayType),
      );
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.saveAs),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: context.l10n.designName),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, nameController.text),
              child: Text(context.l10n.save),
            ),
          ],
        ),
      );

      if (result == null || result.isEmpty) return;
      name = result;
    }

    if (!context.mounted) return;
    final translationBundle = context.read<TranslationCubit>().state.bundle;
    final multiCubit = context.read<MultiScreenshotCubit>();
    await multiCubit.saveDesign(
      name,
      bytes,
      override: override,
      translationBundle: translationBundle,
      ascAppConfig: multiCubit.state.ascAppConfig,
    );

    if (!context.mounted) return;
    context.showAppSnackbar(context.l10n.savedToLibrary);
  }
}
