import 'dart:io';

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/services/app_logger.dart';
import 'package:app_screenshots/core/services/command_server.dart';
import 'package:app_screenshots/core/services/menu_callbacks.dart';
import 'package:app_screenshots/core/widgets/app_dialog.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/design_share_helper.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/preset_picker_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/desktop_editor_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/grid_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/editor_canvas.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/locale_switcher.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/floating_panel.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/mobile_editor_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/dot_grid_painter.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/screenshot_capture_provider.dart';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:material_symbols_icons/symbols.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ScreenshotEditorPage extends StatelessWidget {
  final String? initialImageUrl;
  final File? initialImageFile;
  final String? displayType;
  final SavedDesign? initialDesign;
  final ValueChanged<String>? onSave;
  final String? folderId;

  /// When set, the design was opened from this `.appshots` file.
  /// "Save" will write back to this path.
  final String? sourceFilePath;

  const ScreenshotEditorPage({
    super.key,
    this.initialImageUrl,
    this.initialImageFile,
    this.displayType,
    this.initialDesign,
    this.onSave,
    this.folderId,
    this.sourceFilePath,
  });

  static Future<void> show(
    BuildContext context, {
    String? imageUrl,
    File? imageFile,
    String? displayType,
    SavedDesign? initialDesign,
    ValueChanged<String>? onSave,
    String? folderId,
    String? sourceFilePath,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScreenshotEditorPage(
          initialImageUrl: imageUrl,
          initialImageFile: imageFile,
          displayType: displayType,
          initialDesign: initialDesign,
          onSave: onSave,
          folderId: folderId,
          sourceFilePath: sourceFilePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ScreenshotEditorCubit(
            persistenceService: GetIt.I<ScreenshotPersistenceService>(),
            imageUrl: initialImageUrl,
            imageFile: initialImageFile,
            displayType: displayType,
            initialDesign: initialDesign,
            prefs: GetIt.I<SharedPreferences>(),
            folderId: folderId,
            sourceFilePath: sourceFilePath,
          ),
        ),
        BlocProvider(create: (_) => GetIt.I<TranslationCubit>()),
      ],
      child: ScreenshotEditorView(onSave: onSave),
    );
  }
}

class ScreenshotEditorView extends StatefulWidget {
  final ValueChanged<String>? onSave;

  const ScreenshotEditorView({super.key, this.onSave});

  @override
  State<ScreenshotEditorView> createState() => _ScreenshotEditorViewState();
}

class _ScreenshotEditorViewState extends State<ScreenshotEditorView> {
  final ScreenshotController _screenshotController = ScreenshotController();
  late final _screenShotCubit = context.read<ScreenshotEditorCubit>();
  bool _isPanning = false;
  final _mobileControlsKey = GlobalKey<MobileEditorControlsState>();

  @override
  void initState() {
    super.initState();
    // Register undo/redo for the macOS Edit menu
    MenuCallbacks.onUndo = () => _screenShotCubit.undo();
    MenuCallbacks.onRedo = () => _screenShotCubit.redo();

    // Register cubits with the CLI command server.
    final server = GetIt.I<CommandServer>();
    server.registerEditor(_screenShotCubit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        server.registerTranslation(context.read<TranslationCubit>());
      }
    });
  }

  @override
  void dispose() {
    // Unregister so stale callbacks don't fire
    MenuCallbacks.onUndo = null;
    MenuCallbacks.onRedo = null;

    // Unregister cubits from the CLI command server.
    final server = GetIt.I<CommandServer>();
    server.unregisterEditor(_screenShotCubit);
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // If a text field has focus, let it handle its own key events.
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null &&
        primaryFocus.context != null &&
        primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() !=
            null) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isCmdOrCtrl =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // ── Modifier shortcuts (Cmd/Ctrl + key) ──────────────────────────────

    if (isCmdOrCtrl) {
      // Cmd+Z — undo / Cmd+Shift+Z — redo
      if (key == LogicalKeyboardKey.keyZ) {
        if (isShift) {
          _screenShotCubit.redo();
        } else {
          _screenShotCubit.undo();
        }
        return KeyEventResult.handled;
      }

      // Cmd+S — save / Cmd+Shift+S — save as
      if (key == LogicalKeyboardKey.keyS) {
        if (isShift) {
          _saveToLibrary(context, override: false);
        } else {
          final state = _screenShotCubit.state;
          final hasSourceFile = state.sourceFilePath != null;
          if (hasSourceFile) {
            _saveToFile(context);
          } else {
            _saveToLibrary(context, override: state.savedDesignId != null);
          }
        }
        return KeyEventResult.handled;
      }

      // Cmd+E — export
      if (key == LogicalKeyboardKey.keyE) {
        _exportImage(context);
        return KeyEventResult.handled;
      }

      // Cmd+C — copy to clipboard
      if (key == LogicalKeyboardKey.keyC) {
        _copyToClipboard(context);
        return KeyEventResult.handled;
      }

      // Cmd+V — paste image from clipboard
      if (key == LogicalKeyboardKey.keyV) {
        _pasteImageFromClipboard(context);
        return KeyEventResult.handled;
      }

      // Cmd+D — deselect overlay
      if (key == LogicalKeyboardKey.keyD) {
        _screenShotCubit.deselectOverlay();
        return KeyEventResult.handled;
      }
    }

    // ── Non-modifier shortcuts ───────────────────────────────────────────

    // Escape — deselect overlay
    if (key == LogicalKeyboardKey.escape) {
      _screenShotCubit.deselectOverlay();
      return KeyEventResult.handled;
    }

    // Delete / Backspace — remove selected overlay
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      _screenShotCubit.deleteSelectedOverlay();
      return KeyEventResult.handled;
    }

    // Arrow keys — nudge selected overlay (or image if none selected)
    final nudge = isShift ? 10.0 : 1.0;

    Offset? delta;
    if (key == LogicalKeyboardKey.arrowUp) {
      delta = Offset(0, -nudge);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      delta = Offset(0, nudge);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      delta = Offset(-nudge, 0);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      delta = Offset(nudge, 0);
    }

    if (delta != null) {
      _screenShotCubit.moveSelectedOverlay(delta);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<Uint8List?> _captureImage() async {
    try {
      // Hide grid/center lines before capture
      _screenShotCubit.hideGridForCapture();
      await Future.delayed(const Duration(milliseconds: 50));

      final bytes = await _screenshotController.capture(pixelRatio: 1.0);

      // Restore grid settings
      _screenShotCubit.restoreGridAfterCapture();

      if (bytes == null) return null;

      // When transparent background is enabled, keep the alpha channel.
      if (_screenShotCubit.state.design.transparentBackground) {
        return bytes;
      }

      final image = img.decodePng(bytes);
      if (image == null) return bytes;

      final noAlphaImage = image.convert(numChannels: 3);
      return img.encodePng(noAlphaImage);
    } catch (e, st) {
      // Ensure grid is restored even on error
      _screenShotCubit.restoreGridAfterCapture();
      AppLogger.error(
        'Capture failed',
        tag: 'EditorPage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      if (!context.mounted) return;
      _screenShotCubit.updateImageFile(File(result.files.single.path!));
    }
  }

  Future<void> _pasteImageFromClipboard(BuildContext context) async {
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
      _screenShotCubit.updateImageFile(file);
    } catch (e, st) {
      AppLogger.error(
        'Failed to paste from clipboard',
        tag: 'EditorPage',
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

  Future<void> _saveToLibrary(
    BuildContext context, {
    bool override = false,
  }) async {
    final bytes = await _captureImage();
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
      final state = context.read<ScreenshotEditorCubit>().state;
      name =
          state.savedDesignName ??
          ScreenshotUtils.defaultDesignName(state.design.displayType);
    } else {
      final displayType = context
          .read<ScreenshotEditorCubit>()
          .state
          .design
          .displayType;
      final nameController = TextEditingController(
        text: ScreenshotUtils.defaultDesignName(displayType),
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
    await context.read<ScreenshotEditorCubit>().saveDesign(
      name,
      bytes,
      override: override,
    );

    if (!context.mounted) return;
    context.showAppSnackbar(context.l10n.savedToLibrary);
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    try {
      final bytes = await _captureImage();
      if (bytes == null) {
        throw Exception('Failed to capture screenshot');
      }
      await Pasteboard.writeImage(bytes);
      if (!context.mounted) return;
      context.showAppSnackbar(context.l10n.copiedToClipboard);
    } catch (e, st) {
      AppLogger.error(
        'Failed to copy to clipboard',
        tag: 'EditorPage',
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

  Future<void> _exportImage(BuildContext context) async {
    try {
      final bytes = await _captureImage();

      if (bytes == null) {
        throw Exception('Failed to capture screenshot');
      }

      final fileName =
          'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';

      String? filePath;

      if (widget.onSave != null) {
        final tempDir = await getTemporaryDirectory();
        filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (!context.mounted) return;
        widget.onSave!(filePath);
        Navigator.pop(context);
        return;
      }

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
        'Failed to export image',
        tag: 'EditorPage',
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

  Future<void> _shareDesignFile(BuildContext context) async {
    try {
      final state = context.read<ScreenshotEditorCubit>().state;
      // Build a SavedDesign from the current editor state
      final design = SavedDesign(
        id: state.savedDesignId ?? 'unsaved',
        name: state.savedDesignName ?? 'Screenshot Design',
        lastModified: DateTime.now(),
        thumbnailPath: '',
        design: state.design,
      );
      await DesignShareHelper.shareDesign(context, design);
    } catch (e, st) {
      AppLogger.error(
        'Failed to share design file',
        tag: 'EditorPage',
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

  Future<void> _saveToFile(BuildContext context) async {
    try {
      final state = context.read<ScreenshotEditorCubit>().state;
      final sourceFilePath = state.sourceFilePath;
      if (sourceFilePath == null) return;

      final design = SavedDesign(
        id: state.savedDesignId ?? 'unsaved',
        name: state.savedDesignName ?? 'Screenshot Design',
        lastModified: DateTime.now(),
        thumbnailPath: '',
        design: state.design,
      );
      await DesignShareHelper.saveToFile(design, sourceFilePath);

      if (!context.mounted) return;
      context.showAppSnackbar(context.l10n.savedToFile);
    } catch (e, st) {
      AppLogger.error(
        'Failed to save to file',
        tag: 'EditorPage',
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

  /// Captures the single design for each translated locale.
  ///
  /// Returns `Map<locale, [File]>` — one screenshot per locale.
  /// When no translations exist, captures the source locale only.
  Future<Map<String, List<File>>?> _captureAllLocaleScreenshots(
    BuildContext context,
  ) async {
    final translationCubit = context.read<TranslationCubit>();
    final bundle = translationCubit.state.bundle;

    final hasTranslations = bundle != null && bundle.translations.isNotEmpty;
    final sourceLocale = bundle?.sourceLocale ?? 'en-US';
    final allLocales = hasTranslations
        ? [sourceLocale, ...bundle.targetLocales]
        : [sourceLocale];

    try {
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory(
        '${tempDir.path}/asc_upload_${DateTime.now().millisecondsSinceEpoch}',
      );
      await exportDir.create(recursive: true);

      final result = <String, List<File>>{};

      for (final locale in allLocales) {
        // Set preview locale so the canvas shows translated text.
        if (hasTranslations) {
          translationCubit.setPreviewLocale(
            locale == sourceLocale ? null : locale,
          );
        }

        // Wait for the UI to rebuild with the new locale text.
        await Future.delayed(const Duration(milliseconds: 300));

        final bytes = await _captureImage();
        if (bytes != null) {
          final localeDir = Directory('${exportDir.path}/$locale');
          await localeDir.create(recursive: true);
          final file = File('${localeDir.path}/screenshot_1.png');
          await file.writeAsBytes(bytes);
          result[locale] = [file];
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
        tag: 'EditorPage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  void _showPresetPicker(BuildContext context, {Rect? sourceRect}) {
    PresetPickerDialog.show(context, sourceRect: sourceRect).then((
      preset,
    ) async {
      if (preset == null || !context.mounted) return;

      final l10n = context.l10n;
      final confirmed = await AppDialog.show(
        context,
        title: l10n.applyTemplate,
        content: l10n.applyTemplateConfirm,
        confirmLabel: l10n.apply,
        cancelLabel: l10n.cancel,
        icon: Symbols.style_rounded,
      );

      if (confirmed != true || !context.mounted) return;
      context.read<ScreenshotEditorCubit>().applyPreset(preset);
    });
  }

  // ---------------------------------------------------------------------------
  // AppBar actions
  // ---------------------------------------------------------------------------

  List<Widget> _buildDesktopActions(BuildContext context) {
    return [
      BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
        buildWhen: (prev, curr) =>
            prev.canUndo != curr.canUndo || prev.canRedo != curr.canRedo,
        builder: (context, state) {
          // Hide undo/redo when neither is available
          if (!state.canUndo && !state.canRedo) {
            return const SizedBox.shrink();
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Symbols.undo_rounded, size: 20),
                tooltip: context.l10n.undo,
                onPressed: state.canUndo
                    ? () => context.read<ScreenshotEditorCubit>().undo()
                    : null,
                visualDensity: VisualDensity.compact,
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Symbols.redo_rounded, size: 20),
                tooltip: context.l10n.redo,
                onPressed: state.canRedo
                    ? () => context.read<ScreenshotEditorCubit>().redo()
                    : null,
                visualDensity: VisualDensity.compact,
                iconSize: 20,
              ),
            ],
          );
        },
      ),
      Builder(
        builder: (btnContext) => IconButton(
          icon: const Icon(Symbols.style_rounded),
          tooltip: context.l10n.templates,
          onPressed: () => _showPresetPicker(
            context,
            sourceRect: rectFromContext(btnContext),
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Symbols.image_rounded),
        tooltip: context.l10n.importImage,
        onPressed: () => _pickImage(context),
      ),
      IconButton(
        icon: const Icon(Symbols.content_paste_rounded),
        tooltip: context.l10n.pasteFromClipboard,
        onPressed: () => _pasteImageFromClipboard(context),
      ),
      Builder(
        builder: (btnContext) => IconButton(
          icon: const Icon(Symbols.grid_on_rounded),
          tooltip: context.l10n.grid,
          onPressed: () => _showGridDialog(context, btnContext),
        ),
      ),
      BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
        builder: (context, state) => _buildSaveExportMenu(context, state),
      ),
    ];
  }

  List<Widget> _buildMobileActions(BuildContext context) {
    return [
      // Undo/Redo – auto-hide when no history
      BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
        buildWhen: (prev, curr) =>
            prev.canUndo != curr.canUndo || prev.canRedo != curr.canRedo,
        builder: (context, state) {
          if (!state.canUndo && !state.canRedo) {
            return const SizedBox.shrink();
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Symbols.undo_rounded, size: 20),
                tooltip: context.l10n.undo,
                onPressed: state.canUndo
                    ? () => context.read<ScreenshotEditorCubit>().undo()
                    : null,
                visualDensity: VisualDensity.compact,
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Symbols.redo_rounded, size: 20),
                tooltip: context.l10n.redo,
                onPressed: state.canRedo
                    ? () => context.read<ScreenshotEditorCubit>().redo()
                    : null,
                visualDensity: VisualDensity.compact,
                iconSize: 20,
              ),
            ],
          );
        },
      ),
      // Primary action: Export
      IconButton(
        icon: const Icon(Symbols.download_rounded),
        tooltip: context.l10n.export,
        onPressed: () => _exportImage(context),
      ),
      // More menu
      BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
        builder: (context, state) {
          final canOverride = state.savedDesignId != null;
          return AppPopupMenu<String>(
            tooltip: context.l10n.more,
            onSelected: (value) => _handleMenuAction(context, value),
            items: [
              AppPopupMenuItem(
                value: 'templates',
                icon: Symbols.style_rounded,
                title: context.l10n.templates,
              ),
              AppPopupMenuItem(
                value: 'import',
                icon: Symbols.image_rounded,
                title: context.l10n.importImage,
              ),
              AppPopupMenuItem(
                value: 'paste',
                icon: Symbols.content_paste_rounded,
                title: context.l10n.pasteFromClipboard,
              ),
              AppPopupMenuItem(
                value: 'grid',
                icon: Symbols.grid_on_rounded,
                title: context.l10n.grid,
              ),
              const AppPopupMenuItem.divider(),
              if (canOverride) ...[
                AppPopupMenuItem(
                  value: 'save',
                  icon: Symbols.save_rounded,
                  title: context.l10n.save,
                ),
                AppPopupMenuItem(
                  value: 'save_new',
                  icon: Symbols.content_copy_rounded,
                  title: context.l10n.saveAs,
                ),
              ] else
                AppPopupMenuItem(
                  value: 'save',
                  icon: Symbols.save_rounded,
                  title: context.l10n.save,
                ),
              AppPopupMenuItem(
                value: 'copy',
                icon: Symbols.content_copy_rounded,
                title: context.l10n.copyToClipboard,
              ),
              const AppPopupMenuItem.divider(),
              AppPopupMenuItem(
                value: 'share_design',
                icon: Symbols.share_rounded,
                title: context.l10n.shareDesignFile,
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Symbols.more_vert_rounded),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildSaveExportMenu(
    BuildContext context,
    ScreenshotEditorState state,
  ) {
    final canOverride = state.savedDesignId != null;
    final hasSourceFile = state.sourceFilePath != null;
    return AppPopupMenu<String>(
      tooltip: '${context.l10n.save} / ${context.l10n.export}',
      onSelected: (value) => _handleMenuAction(context, value),
      items: [
        if (hasSourceFile)
          AppPopupMenuItem(
            value: 'save_to_file',
            icon: Symbols.save_rounded,
            title: context.l10n.save,
          ),
        if (canOverride) ...[
          AppPopupMenuItem(
            value: 'save',
            icon: Symbols.save_rounded,
            title: hasSourceFile
                ? context.l10n.saveToLibrary
                : context.l10n.save,
          ),
          AppPopupMenuItem(
            value: 'save_new',
            icon: Symbols.content_copy_rounded,
            title: context.l10n.saveAs,
          ),
        ] else
          AppPopupMenuItem(
            value: 'save',
            icon: Symbols.save_rounded,
            title: hasSourceFile
                ? context.l10n.saveToLibrary
                : context.l10n.save,
          ),
        AppPopupMenuItem(
          value: 'export',
          icon: Symbols.download_rounded,
          title: context.l10n.export,
        ),
        AppPopupMenuItem(
          value: 'copy',
          icon: Symbols.content_copy_rounded,
          title: context.l10n.copyToClipboard,
        ),
        const AppPopupMenuItem.divider(),
        AppPopupMenuItem(
          value: 'share_design',
          icon: Symbols.share_rounded,
          title: context.l10n.shareDesignFile,
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Symbols.save_rounded),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String value) {
    final state = context.read<ScreenshotEditorCubit>().state;
    final canOverride = state.savedDesignId != null;

    switch (value) {
      case 'templates':
        _showPresetPicker(context);
      case 'import':
        _pickImage(context);
      case 'paste':
        _pasteImageFromClipboard(context);
      case 'save':
        _saveToLibrary(context, override: canOverride);
      case 'save_new':
        _saveToLibrary(context, override: false);
      case 'save_to_file':
        _saveToFile(context);
      case 'export':
        _exportImage(context);
      case 'copy':
        _copyToClipboard(context);
      case 'share_design':
        _shareDesignFile(context);
      case 'grid':
        _showControls(context, const GridControls());
    }
  }

  void _showGridDialog(BuildContext context, BuildContext btnContext) {
    final sourceRect = rectFromContext(btnContext);
    if (sourceRect == null) return;
    showGenieDialog(
      context: context,
      sourceRect: sourceRect,
      builder: (_) => BlocProvider.value(
        value: context.read<ScreenshotEditorCubit>(),
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: const GridControls(),
          ),
        ),
      ),
    );
  }

  Future<void> _showControls(BuildContext context, Widget controls) {
    return showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ScreenshotEditorCubit>(),
        child: controls,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return BlocListener<ScreenshotEditorCubit, ScreenshotEditorState>(
          listenWhen: (previous, current) {
            return !isDesktop &&
                previous.selectedOverlayId != current.selectedOverlayId &&
                current.selectedOverlayId != null;
          },
          listener: (context, state) {
            _mobileControlsKey.currentState?.selectTab(kTextTabIndex);
          },
          child: ScreenshotCaptureProvider(
            captureAllLocaleScreenshots: _captureAllLocaleScreenshots,
            child: FocusScope(
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: Scaffold(
                appBar: AppBar(
                  titleSpacing: 0,
                  title: Text(context.l10n.screenshotStudio),
                  leading: BackButton(onPressed: () => Navigator.pop(context)),
                  actions: isDesktop
                      ? _buildDesktopActions(context)
                      : _buildMobileActions(context),
                ),
                body: isDesktop
                    ? _buildDesktopBody(context)
                    : _buildMobileBody(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _buildCanvasArea(context),
            FloatingPanel(
              constraints: constraints,
              child: const DesktopEditorControls(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    return Stack(
      children: [
        // Canvas fills the entire area but adds bottom padding matching
        // the controls panel height so content avoids being hidden.
        ValueListenableBuilder<double>(
          valueListenable:
              _mobileControlsKey.currentState?.panelHeightNotifier ??
              ValueNotifier(kMobileControlsCollapsedHeight),
          builder: (context, panelHeight, _) {
            return Padding(
              padding: EdgeInsets.only(bottom: panelHeight),
              child: _buildCanvasArea(context),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MobileEditorControls(key: _mobileControlsKey),
        ),
      ],
    );
  }

  Widget _buildCanvasArea(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const LocaleSwitcher(),
        Expanded(
          child: DropTarget(
            onDragDone: (details) {
              if (details.files.isNotEmpty) {
                context.read<ScreenshotEditorCubit>().updateImageFile(
                  File(details.files.first.path),
                );
              }
            },
            child: BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
              buildWhen: (prev, curr) =>
                  prev.design.gridSettings.showDotGrid !=
                  curr.design.gridSettings.showDotGrid,
              builder: (context, state) {
                final bgColor = theme.colorScheme.surfaceContainerLowest;
                final showDots = state.design.gridSettings.showDotGrid;

                return Stack(
                  children: [
                    if (showDots)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DotGridPainter(
                            dotColor: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.2),
                            backgroundColor: bgColor,
                          ),
                        ),
                      )
                    else
                      Positioned.fill(child: ColoredBox(color: bgColor)),
                    MouseRegion(
                      cursor: _isPanning
                          ? SystemMouseCursors.grabbing
                          : SystemMouseCursors.grab,
                      child: Listener(
                        onPointerDown: (_) => setState(() => _isPanning = true),
                        onPointerUp: (_) => setState(() => _isPanning = false),
                        onPointerCancel: (_) =>
                            setState(() => _isPanning = false),
                        child: InteractiveViewer(
                          boundaryMargin: const EdgeInsets.all(8000),
                          minScale: 0.1,
                          maxScale: 4.0,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(
                                MediaQuery.sizeOf(context).width < 600
                                    ? 12
                                    : 24,
                              ),
                              child: EditorCanvas(
                                screenshotController: _screenshotController,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
