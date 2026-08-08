import 'dart:io';

import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/services/command_server.dart';
import 'package:app_screenshots/core/widgets/app_dialog.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_preset.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/template_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/asc_upload_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/multi_screenshot_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_credentials_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_upload_sheet.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_locale_picker_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/play_upload_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/play_credentials_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/play_upload_sheet.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_app_config_dialog.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/locale_switcher.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/multi_screenshot_actions.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/add_screenshot_placeholder.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/canvas_slot.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/desktop_editor_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/screenshot_capture_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/grid_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/mobile_editor_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/dot_grid_painter.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/floating_panel.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/preset_picker_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/viewport/canvas_viewport_controller.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/viewport/figma_canvas_viewport.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/viewport/zoom_control_bar.dart';
import 'package:app_screenshots/features/screenshot_editor/utils/screenshot_utils.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:screenshot/screenshot.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'multi_page_canvas.dart';
part 'multi_page_menus.dart';

/// Menu actions available in the multi-screenshot editor.
enum _MultiMenuAction {
  templates,
  zoomFit,
  addScreenshot,
  importImage,
  pasteImage,
  grid,
  save,
  saveNew,
  saveToFile,
  saveAsTemplate,
  exportSingle,
  exportAll,
  copy,
  shareDesign,
  uploadToAsc,
  uploadExistingToAsc,
  uploadToGooglePlay,
  uploadExistingToGooglePlay,
  ascSettings,
}

/// Multi-screenshot editor page – horizontal row of artboards.
class MultiScreenshotPage extends StatelessWidget {
  final String? displayType;
  final SavedDesign? initialSavedDesign;
  final String? folderId;

  /// When set, the design was opened from this `.appshots` file.
  /// "Save" will write back to this path.
  final String? sourceFilePath;

  const MultiScreenshotPage({
    super.key,
    this.displayType,
    this.initialSavedDesign,
    this.folderId,
    this.sourceFilePath,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MultiScreenshotCubit(
            persistenceService: GetIt.I<ScreenshotPersistenceService>(),
            displayType: displayType,
            initialSavedDesign: initialSavedDesign,
            folderId: folderId ?? initialSavedDesign?.folderId,
            sourceFilePath: sourceFilePath,
          ),
        ),
        BlocProvider(
          create: (_) => ScreenshotEditorCubit(
            persistenceService: GetIt.I<ScreenshotPersistenceService>(),
            displayType: displayType,
            prefs: GetIt.I<SharedPreferences>(),
          ),
        ),
        BlocProvider(
          create: (_) =>
              GetIt.I<TranslationCubit>()
                ..loadBundle(initialSavedDesign?.translationBundle),
        ),
      ],
      child: const _MultiScreenshotView(),
    );
  }
}

// =============================================================================

class _MultiScreenshotView extends StatefulWidget {
  const _MultiScreenshotView();

  @override
  State<_MultiScreenshotView> createState() => _MultiScreenshotViewState();
}

class _MultiScreenshotViewState extends State<_MultiScreenshotView>
    with TickerProviderStateMixin, MultiScreenshotActions {
  final ScreenshotController _screenshotController = ScreenshotController();
  late final CanvasViewportController _viewportController;
  bool _isExporting = false;
  final _mobileControlsKey = GlobalKey<MobileEditorControlsState>();

  // Cached references for safe disposal.
  late final ScreenshotEditorCubit _editorCubit;
  late final MultiScreenshotCubit _multiCubit;

  static const _gap = 200.0;

  // -- MultiScreenshotActions interface --
  @override
  ScreenshotController get screenshotController => _screenshotController;
  @override
  void syncEditorChangesBack() => _syncEditorChangesBack();
  @override
  void setExporting(bool value) => setState(() => _isExporting = value);

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
    final editorCubit = context.read<ScreenshotEditorCubit>();

    // ── Modifier shortcuts (Cmd/Ctrl + key) ──────────────────────────────

    if (isCmdOrCtrl) {
      // Cmd+S — save / Cmd+Shift+S — save as
      if (key == LogicalKeyboardKey.keyS) {
        if (isShift) {
          saveToLibrary(context, override: false);
        } else {
          final multiState = context.read<MultiScreenshotCubit>().state;
          final hasSourceFile = multiState.sourceFilePath != null;
          if (hasSourceFile) {
            saveToFile(context);
          } else {
            saveToLibrary(context, override: multiState.savedDesignId != null);
          }
        }
        return KeyEventResult.handled;
      }

      // Cmd+E — export current / Cmd+Shift+E — export all
      if (key == LogicalKeyboardKey.keyE) {
        if (isShift) {
          exportAll(context);
        } else {
          exportSingle(context);
        }
        return KeyEventResult.handled;
      }

      // Cmd+U — upload to ASC
      if (key == LogicalKeyboardKey.keyU) {
        _showUploadSheet(context);
        return KeyEventResult.handled;
      }

      // Cmd+C — copy overlay (if selected) or image to clipboard
      if (key == LogicalKeyboardKey.keyC) {
        if (editorCubit.state.selectedOverlayId != null) {
          editorCubit.copySelectedOverlay();
        } else {
          copyToClipboard(context);
        }
        return KeyEventResult.handled;
      }

      // Cmd+V — paste overlay (if clipboard has one) or image from clipboard
      if (key == LogicalKeyboardKey.keyV) {
        if (editorCubit.hasOverlayClipboard) {
          editorCubit.pasteOverlay();
          _syncEditorChangesBack();
        } else {
          pasteImageFromClipboard(context);
        }
        return KeyEventResult.handled;
      }

      // Cmd+0 — zoom to fit
      if (key == LogicalKeyboardKey.digit0) {
        _zoomToFit();
        return KeyEventResult.handled;
      }

      // Cmd+1 — zoom to 100%
      if (key == LogicalKeyboardKey.digit1) {
        _viewportController.setScale(1.0);
        return KeyEventResult.handled;
      }

      // Cmd+= — zoom in / Cmd+- — zoom out, around the viewport center
      if (key == LogicalKeyboardKey.equal ||
          key == LogicalKeyboardKey.numpadAdd) {
        _viewportController.zoomBy(1.25, animate: true);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.minus ||
          key == LogicalKeyboardKey.numpadSubtract) {
        _viewportController.zoomBy(0.8, animate: true);
        return KeyEventResult.handled;
      }

      // Cmd+Z — undo / Cmd+Shift+Z — redo
      if (key == LogicalKeyboardKey.keyZ) {
        if (isShift) {
          editorCubit.redo();
        } else {
          editorCubit.undo();
        }
        _syncEditorChangesBack();
        return KeyEventResult.handled;
      }

      // Cmd+D — deselect overlay
      if (key == LogicalKeyboardKey.keyD) {
        editorCubit.deselectOverlay();
        _syncEditorChangesBack();
        return KeyEventResult.handled;
      }
    }

    // ── Non-modifier shortcuts ───────────────────────────────────────────

    // Escape — deselect overlay
    if (key == LogicalKeyboardKey.escape) {
      editorCubit.deselectOverlay();
      _syncEditorChangesBack();
      return KeyEventResult.handled;
    }

    // Delete / Backspace — remove selected overlay
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      editorCubit.deleteSelectedOverlay();
      _syncEditorChangesBack();
      return KeyEventResult.handled;
    }

    // Arrow keys — nudge selected overlay
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
      editorCubit.nudgeSelectedOverlay(delta);
      _syncEditorChangesBack();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    _editorCubit = context.read<ScreenshotEditorCubit>();
    _multiCubit = context.read<MultiScreenshotCubit>();
    _viewportController = CanvasViewportController(
      vsync: this,
      minScale: 0.05,
      maxScale: 4.0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncActiveDesign();
      _zoomToFit(animate: false);

      // Register cubits with the CLI command server.
      if (mounted) {
        final server = GetIt.I<CommandServer>();
        server.registerEditor(_editorCubit);
        server.registerTranslation(context.read<TranslationCubit>());
        server.registerMulti(_multiCubit);
        server.registerCapture(
          captureImage: captureImage,
          syncChanges: () => _syncEditorChangesBack(),
        );
      }
    });
  }

  @override
  void dispose() {
    // Unregister cubits from the CLI command server.
    // Use cached references instead of context.read, which is unsafe during dispose.
    final server = GetIt.I<CommandServer>();
    server.unregisterEditor(_editorCubit);
    server.unregisterMulti(_multiCubit);
    server.unregisterCapture();
    _viewportController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Zoom to fit
  // ---------------------------------------------------------------------------

  /// World-space bounding box of the design row's content (matches the
  /// child layout in [_MultiCanvasArea]: `Padding(100) > Row(...)`), plus
  /// the trailing add-placeholder when it will be rendered.
  Rect _contentBounds(MultiScreenshotState multiState) {
    double totalWidth = 0;
    double maxHeight = 0;
    for (final d in multiState.designs) {
      final dims = ScreenshotUtils.getDimensions(
        d.displayType ?? '',
        d.orientation,
      );
      totalWidth += dims.width;
      if (dims.height > maxHeight) maxHeight = dims.height;
    }
    totalWidth += _gap * (multiState.designs.length - 1);

    if (multiState.canAddMore) {
      final lastDims = ScreenshotUtils.getDimensions(
        multiState.designs.last.displayType ?? '',
        multiState.designs.last.orientation,
      );
      totalWidth += _gap + lastDims.width;
    }

    return Rect.fromLTWH(0, 0, totalWidth, maxHeight);
  }

  void _zoomToFit({bool animate = true}) {
    final multiState = context.read<MultiScreenshotCubit>().state;
    if (multiState.designs.isEmpty) return;
    _viewportController.zoomToRect(
      _contentBounds(multiState),
      padding: 200,
      animate: animate,
    );
  }

  /// Zoom / pan so the design at [index] is centred in the viewport.
  void _zoomToActive([int? index]) {
    final multiState = context.read<MultiScreenshotCubit>().state;
    if (multiState.designs.isEmpty) return;

    final targetIdx = index ?? multiState.activeIndex;

    double xOffset = 0;
    double targetW = 0;
    double targetH = 0;
    for (int i = 0; i < multiState.designs.length; i++) {
      final dims = ScreenshotUtils.getDimensions(
        multiState.designs[i].displayType ?? '',
        multiState.designs[i].orientation,
      );
      if (i < targetIdx) xOffset += dims.width + _gap;
      if (i == targetIdx) {
        targetW = dims.width;
        targetH = dims.height;
      }
    }

    const contentPad = 100.0; // Row's own Padding
    _viewportController.zoomToRect(
      Rect.fromLTWH(contentPad + xOffset, contentPad, targetW, targetH),
      padding: 150,
      animate: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Editor ↔ Multi sync
  // ---------------------------------------------------------------------------

  void _syncActiveDesign() {
    final multiState = context.read<MultiScreenshotCubit>().state;
    if (multiState.activeDesign == null) return;
    context.read<ScreenshotEditorCubit>().loadDesignForMultiMode(
      multiState.activeDesign!,
      imageFile: multiState.activeImageFile,
    );
  }

  void _syncEditorChangesBack() {
    final editorState = context.read<ScreenshotEditorCubit>().state;
    final multiCubit = context.read<MultiScreenshotCubit>();
    multiCubit.updateActiveDesign(editorState.design);
    if (editorState.selectedImageFile != null) {
      multiCubit.syncActiveImage(editorState.selectedImageFile!);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return MultiBlocListener(
          listeners: [
            BlocListener<MultiScreenshotCubit, MultiScreenshotState>(
              listenWhen: (p, c) =>
                  p.activeIndex != c.activeIndex ||
                  p.designs.length != c.designs.length,
              listener: (_, _) => _syncActiveDesign(),
            ),
            BlocListener<MultiScreenshotCubit, MultiScreenshotState>(
              listenWhen: (p, c) => p.designs.length != c.designs.length,
              listener: (_, state) {
                // `state` is the new state. We compare the current active
                // index with designs length to detect add vs remove:
                // addDesign sets activeIndex = designs.length-1 (last).
                if (state.activeIndex == state.designs.length - 1 &&
                    state.designs.length > 1) {
                  // Likely an add → centre on the new one.
                  _zoomToActive();
                } else {
                  _zoomToFit();
                }
              },
            ),
            BlocListener<ScreenshotEditorCubit, ScreenshotEditorState>(
              listenWhen: (p, c) =>
                  p.design.orientation != c.design.orientation,
              listener: (_, _) {
                _syncEditorChangesBack();
                _zoomToFit();
              },
            ),
            BlocListener<ScreenshotEditorCubit, ScreenshotEditorState>(
              listenWhen: (p, c) =>
                  !isDesktop &&
                  p.selectedOverlayId != c.selectedOverlayId &&
                  c.selectedOverlayId != null,
              listener: (ctx, _) {
                _mobileControlsKey.currentState?.selectTab(kTextTabIndex);
              },
            ),
          ],
          child:
              BlocSelector<
                MultiScreenshotCubit,
                MultiScreenshotState,
                AscAppConfig?
              >(
                selector: (state) => state.ascAppConfig,
                builder: (context, ascAppConfig) {
                  return ScreenshotCaptureProvider(
                    captureAllLocaleScreenshots: captureAllLocaleScreenshots,
                    ascAppConfig: ascAppConfig,
                    onAscAppConfigChanged: (config) {
                      context.read<MultiScreenshotCubit>().setAscAppConfig(
                        config,
                      );
                    },
                    child: FocusScope(
                      autofocus: true,
                      onKeyEvent: _handleKeyEvent,
                      child: Scaffold(
                        appBar: _buildAppBar(context, isDesktop),
                        body: isDesktop
                            ? _buildDesktopBody(context)
                            : _buildMobileBody(context),
                      ),
                    ),
                  );
                },
              ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDesktop) {
    return AppBar(
      titleSpacing: 0,
      title: BlocBuilder<MultiScreenshotCubit, MultiScreenshotState>(
        builder: (context, s) =>
            Text(context.l10n.screenshotStudioCount(s.count)),
      ),
      leading: BackButton(
        onPressed: () {
          _syncEditorChangesBack();
          Navigator.pop(context);
        },
      ),
      actions: isDesktop
          ? _buildDesktopActions(context)
          : _buildMobileActions(context),
    );
  }

  List<Widget> _buildDesktopActions(BuildContext context) {
    return [
      BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
        builder: (context, state) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Symbols.undo_rounded),
              tooltip: context.l10n.undo,
              onPressed: state.canUndo
                  ? () {
                      context.read<ScreenshotEditorCubit>().undo();
                      _syncEditorChangesBack();
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Symbols.redo_rounded),
              tooltip: context.l10n.redo,
              onPressed: state.canRedo
                  ? () {
                      context.read<ScreenshotEditorCubit>().redo();
                      _syncEditorChangesBack();
                    }
                  : null,
            ),
          ],
        ),
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
        icon: const Icon(Symbols.fit_screen_rounded),
        tooltip: context.l10n.zoomToFit,
        onPressed: _zoomToFit,
      ),
      BlocBuilder<MultiScreenshotCubit, MultiScreenshotState>(
        builder: (context, multiState) => IconButton(
          icon: const Icon(Symbols.add_photo_alternate_rounded),
          tooltip: context.l10n.addScreenshot,
          onPressed: multiState.canAddMore
              ? () {
                  _syncEditorChangesBack();
                  context.read<MultiScreenshotCubit>().addDesign();
                }
              : null,
        ),
      ),
      IconButton(
        icon: const Icon(Symbols.image_rounded),
        tooltip: context.l10n.importImage,
        onPressed: () => pickImage(context),
      ),
      IconButton(
        icon: const Icon(Symbols.content_paste_rounded),
        tooltip: context.l10n.pasteFromClipboard,
        onPressed: () => pasteImageFromClipboard(context),
      ),
      Builder(
        builder: (btnContext) => IconButton(
          icon: const Icon(Symbols.grid_on_rounded),
          tooltip: context.l10n.grid,
          onPressed: () => _showGridDialog(context, btnContext),
        ),
      ),
      BlocBuilder<MultiScreenshotCubit, MultiScreenshotState>(
        builder: (context, multiState) => _SaveExportMenu(
          multiState: multiState,
          onAction: (value) => _handleMenuAction(context, value, multiState),
        ),
      ),
    ];
  }

  List<Widget> _buildMobileActions(BuildContext context) {
    return [
      BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
        builder: (context, state) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Symbols.undo_rounded),
              tooltip: context.l10n.undo,
              onPressed: state.canUndo
                  ? () {
                      context.read<ScreenshotEditorCubit>().undo();
                      _syncEditorChangesBack();
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Symbols.redo_rounded),
              tooltip: context.l10n.redo,
              onPressed: state.canRedo
                  ? () {
                      context.read<ScreenshotEditorCubit>().redo();
                      _syncEditorChangesBack();
                    }
                  : null,
            ),
          ],
        ),
      ),
      // Primary action: Export All
      IconButton(
        icon: const Icon(Symbols.download_for_offline_rounded),
        tooltip: context.l10n.exportAll,
        onPressed: () => exportAll(context),
      ),
      // More menu
      BlocBuilder<MultiScreenshotCubit, MultiScreenshotState>(
        builder: (context, multiState) => _MobileOverflowMenu(
          multiState: multiState,
          onAction: (value) => _handleMenuAction(context, value, multiState),
        ),
      ),
    ];
  }

  void _showPresetPicker(BuildContext context, {Rect? sourceRect}) {
    PresetPickerDialog.show(context, sourceRect: sourceRect).then((
      preset,
    ) async {
      if (preset == null || !context.mounted) return;

      final l10n = context.l10n;
      final multiCubit = context.read<MultiScreenshotCubit>();
      final currentCount = multiCubit.state.designs.length;
      final templateCount = preset.designs.length;
      final willAddMore = templateCount > currentCount;

      final confirmed = await AppDialog.show(
        context,
        title: l10n.applyTemplate,
        maxWidth: 400,
        content: willAddMore
            ? l10n.applyTemplateConfirmExpand(templateCount, currentCount)
            : l10n.applyTemplateConfirm,
        confirmLabel: l10n.apply,
        cancelLabel: l10n.cancel,
        icon: Symbols.style_rounded,
      );

      if (confirmed != true || !context.mounted) return;

      _syncEditorChangesBack();
      multiCubit.applyPreset(preset);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncActiveDesign();
        _zoomToFit();
      });
    });
  }

  void _handleMenuAction(
    BuildContext context,
    _MultiMenuAction value,
    MultiScreenshotState multiState,
  ) {
    final canOverride = multiState.savedDesignId != null;

    switch (value) {
      case _MultiMenuAction.templates:
        _showPresetPicker(context);
      case _MultiMenuAction.zoomFit:
        _zoomToFit();
      case _MultiMenuAction.addScreenshot:
        _syncEditorChangesBack();
        context.read<MultiScreenshotCubit>().addDesign();
      case _MultiMenuAction.importImage:
        pickImage(context);
      case _MultiMenuAction.pasteImage:
        pasteImageFromClipboard(context);
      case _MultiMenuAction.save:
        saveToLibrary(context, override: canOverride);
      case _MultiMenuAction.saveNew:
        saveToLibrary(context, override: false);
      case _MultiMenuAction.saveToFile:
        saveToFile(context);
      case _MultiMenuAction.exportSingle:
        exportSingle(context);
      case _MultiMenuAction.exportAll:
        exportAll(context);
      case _MultiMenuAction.copy:
        copyToClipboard(context);
      case _MultiMenuAction.shareDesign:
        shareDesignFile(context);
      case _MultiMenuAction.uploadToAsc:
        _showUploadSheet(context);
      case _MultiMenuAction.uploadExistingToAsc:
        _uploadExistingFolder(context);
      case _MultiMenuAction.ascSettings:
        _showAscSettings(context);
      case _MultiMenuAction.uploadToGooglePlay:
        _showPlayUploadSheet(context);
      case _MultiMenuAction.uploadExistingToGooglePlay:
        _uploadExistingFolderToPlayStore(context);
      case _MultiMenuAction.saveAsTemplate:
        _saveAsTemplate(context);
      case _MultiMenuAction.grid:
        _showControls(context, const GridControls());
    }
  }

  /// Opens the ASC upload sheet for an existing folder of pre-rendered screenshots.
  /// Skips the rendering step and parses the folder directly.
  Future<void> _uploadExistingFolder(BuildContext context) async {
    // 1) Check credentials — prompt dialog if missing.
    final repo = sl<SettingsRepository>();
    final creds = await repo.getAscCredentials();
    if (creds == null || !creds.isValid) {
      if (!context.mounted) return;
      final saved = await AscCredentialsDialog.show(context);
      if (!saved || !context.mounted) return;
    }

    if (!context.mounted) return;

    // 2) Pick directory or use cached
    final multiState = context.read<MultiScreenshotCubit>().state;
    String? path;

    if (multiState.lastRenderedAscPath != null && Directory(multiState.lastRenderedAscPath!).existsSync()) {
      final useCached = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.uploadCachedFolderTitle),
          content: Text(context.l10n.uploadCachedFolderMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.pickFolder),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.useCached),
            ),
          ],
        ),
      );
      
      if (useCached == null || !context.mounted) return;
      
      if (useCached) {
        path = multiState.lastRenderedAscPath;
      } else {
        path = await FilePicker.getDirectoryPath(
          dialogTitle: context.l10n.uploadExistingFolderToAsc,
        );
      }
    } else {
      path = await FilePicker.getDirectoryPath(
        dialogTitle: context.l10n.uploadExistingFolderToAsc,
      );
    }
    
    if (path == null || !context.mounted) return;

    final dir = Directory(path);
    if (!dir.existsSync()) return;

    // 3) Parse directory
    final localeScreenshots = <String, List<File>>{};

    // Scan subdirectories for locales
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final locale = entity.path.split(Platform.pathSeparator).last;
        final files = entity.listSync().whereType<File>().where((f) {
          final ext = f.path.toLowerCase();
          return ext.endsWith('.png') ||
              ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg');
        }).toList();

        if (files.isNotEmpty) {
          // Sort files alphabetically to maintain order
          files.sort((a, b) => a.path.compareTo(b.path));
          localeScreenshots[locale] = files;
        }
      }
    }

    if (!context.mounted) return;

    if (localeScreenshots.isEmpty) {
      context.showAppSnackbar(
        context.l10n.noImagesFoundInFolder,
        type: AppSnackbarType.error,
      );
      return;
    }

    // 4) Show upload sheet
    final captureProvider = ScreenshotCaptureProvider.of(context);
    final savedConfig = captureProvider?.ascAppConfig;
    final displayType = context.read<MultiScreenshotCubit>().displayType;
    if (!context.mounted) return;

    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;
    showDialog(
      context: context,
      useSafeArea: !isSmallScreen,
      builder: (_) => BlocProvider(
        create: (_) => sl<AscUploadCubit>()
          ..init(savedAppConfig: savedConfig, designDisplayType: displayType),
        child: isSmallScreen
            ? Dialog.fullscreen(
                child: AscUploadSheet(
                  localeScreenshots: localeScreenshots,
                  ascAppConfig: savedConfig,
                  onAppConfigChanged: captureProvider?.onAscAppConfigChanged,
                ),
              )
            : Dialog(
                child: AscUploadSheet(
                  localeScreenshots: localeScreenshots,
                  ascAppConfig: savedConfig,
                  onAppConfigChanged: captureProvider?.onAscAppConfigChanged,
                ),
              ),
      ),
    );
  }

  Future<void> _uploadExistingFolderToPlayStore(BuildContext context) async {
    // 1) Check credentials — prompt dialog if missing.
    final repo = sl<SettingsRepository>();
    final creds = await repo.getPlayCredentials();
    if (creds == null || !creds.isValid) {
      if (!context.mounted) return;
      final saved = await PlayCredentialsDialog.show(context);
      if (!saved || !context.mounted) return;
    }

    if (!context.mounted) return;

    // 2) Pick directory or use cached
    final multiState = context.read<MultiScreenshotCubit>().state;
    String? path;

    if (multiState.lastRenderedAscPath != null && Directory(multiState.lastRenderedAscPath!).existsSync()) {
      final useCached = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.uploadCachedFolderTitle),
          content: Text(context.l10n.uploadCachedFolderMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.pickFolder),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.useCached),
            ),
          ],
        ),
      );
      
      if (useCached == null || !context.mounted) return;
      
      if (useCached) {
        path = multiState.lastRenderedAscPath;
      } else {
        path = await FilePicker.getDirectoryPath(
          dialogTitle: context.l10n.uploadExistingFolderToGooglePlay,
        );
      }
    } else {
      path = await FilePicker.getDirectoryPath(
        dialogTitle: context.l10n.uploadExistingFolderToGooglePlay,
      );
    }
    
    if (path == null || !context.mounted) return;

    final dir = Directory(path);
    if (!dir.existsSync()) return;

    // 3) Parse directory
    final localeScreenshots = <String, List<File>>{};

    // Scan subdirectories for locales
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final locale = entity.path.split(Platform.pathSeparator).last;
        final files = entity.listSync().whereType<File>().where((f) {
          final ext = f.path.toLowerCase();
          return ext.endsWith('.png') ||
              ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg');
        }).toList();

        if (files.isNotEmpty) {
          // Sort files alphabetically to maintain order
          files.sort((a, b) => a.path.compareTo(b.path));
          localeScreenshots[locale] = files;
        }
      }
    }

    if (!context.mounted) return;

    if (localeScreenshots.isEmpty) {
      context.showAppSnackbar(
        context.l10n.noImagesFoundInFolder,
        type: AppSnackbarType.error,
      );
      return;
    }

    // 4) Show upload sheet
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;
    showDialog(
      context: context,
      useSafeArea: !isSmallScreen,
      builder: (_) => BlocProvider(
        create: (_) => sl<PlayUploadCubit>()..init(),
        child: isSmallScreen
            ? Dialog.fullscreen(
                child: PlayUploadSheet(localeScreenshots: localeScreenshots),
              )
            : Dialog(
                child: PlayUploadSheet(localeScreenshots: localeScreenshots),
              ),
      ),
    );
  }

  /// Opens the ASC upload sheet from the export menu.
  ///
  /// Shows a locale picker first so the user can choose which locales
  /// to render, then captures only those locales before opening the
  /// upload sheet.
  Future<void> _showUploadSheet(BuildContext context) async {
    // 1) Check credentials — prompt dialog if missing.
    final repo = sl<SettingsRepository>();
    final creds = await repo.getAscCredentials();
    if (creds == null || !creds.isValid) {
      if (!context.mounted) return;
      final saved = await AscCredentialsDialog.show(context);
      if (!saved || !context.mounted) return;
    }

    // 2) Show locale picker — let user choose which locales to render.
    if (!context.mounted) return;
    final translationCubit = context.read<TranslationCubit>();
    final bundle = translationCubit.state.bundle;
    final hasTranslations = bundle != null && bundle.translations.isNotEmpty;
    final sourceLocale = bundle?.sourceLocale ?? 'en-US';
    final allLocales = hasTranslations
        ? [sourceLocale, ...bundle.targetLocales]
        : [sourceLocale];

    Set<String>? selectedLocales;
    // Only show picker when there are multiple locales.
    if (allLocales.length > 1) {
      selectedLocales = await AscLocalePickerDialog.show(
        context: context,
        allLocales: allLocales,
        sourceLocale: sourceLocale,
      );
      if (selectedLocales == null || !context.mounted) return;
    }

    // 3) Capture locale screenshots (only selected locales).
    final captureProvider = ScreenshotCaptureProvider.of(context);
    if (captureProvider == null) return;

    final localeScreenshots = await captureProvider.captureAllLocaleScreenshots(
      context,
      selectedLocales: selectedLocales,
    );

    if (!context.mounted) return;

    if (localeScreenshots == null || localeScreenshots.isEmpty) {
      context.showAppSnackbar(
        'Failed to capture locale screenshots',
        type: AppSnackbarType.error,
      );
      return;
    }

    // 4) Show upload sheet — pass saved app config for auto-selection.
    final savedConfig = captureProvider.ascAppConfig;
    final displayType = context.read<MultiScreenshotCubit>().displayType;
    if (!context.mounted) return;

    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;
    showDialog(
      context: context,
      useSafeArea: !isSmallScreen,
      builder: (_) => BlocProvider(
        create: (_) => sl<AscUploadCubit>()
          ..init(savedAppConfig: savedConfig, designDisplayType: displayType),
        child: isSmallScreen
            ? Dialog.fullscreen(
                child: AscUploadSheet(
                  localeScreenshots: localeScreenshots,
                  ascAppConfig: savedConfig,
                  onAppConfigChanged: captureProvider.onAscAppConfigChanged,
                ),
              )
            : Dialog(
                child: AscUploadSheet(
                  localeScreenshots: localeScreenshots,
                  ascAppConfig: savedConfig,
                  onAppConfigChanged: captureProvider.onAscAppConfigChanged,
                ),
              ),
      ),
    );
  }

  Future<void> _showAscSettings(BuildContext context) async {
    final cubit = context.read<MultiScreenshotCubit>();
    final initialConfig = cubit.state.ascAppConfig;
    final result = await AscAppConfigDialog.show(
      context,
      initialConfig: initialConfig,
    );
    if (result != null && result.didSave && context.mounted) {
      cubit.setAscAppConfig(result.config);
      context.showAppSnackbar(
        result.config == null ? context.l10n.ascAppConfigCleared : context.l10n.ascAppConfigSaved,
        type: AppSnackbarType.success,
      );
    }
  }

  /// Opens the Google Play upload sheet from the export menu.
  ///
  /// Mirrors [_showUploadSheet]: ensures a service account is configured,
  /// lets the user pick locales, captures them, then opens the sheet.
  Future<void> _showPlayUploadSheet(BuildContext context) async {
    // 1) Check credentials — prompt for the service account JSON if missing.
    final repo = sl<SettingsRepository>();
    final creds = await repo.getPlayCredentials();
    if (creds == null || !creds.isValid) {
      if (!context.mounted) return;
      final saved = await PlayCredentialsDialog.show(context);
      if (!saved || !context.mounted) return;
    }

    // 2) Show locale picker — let the user choose which locales to render.
    if (!context.mounted) return;
    final translationCubit = context.read<TranslationCubit>();
    final bundle = translationCubit.state.bundle;
    final hasTranslations = bundle != null && bundle.translations.isNotEmpty;
    final sourceLocale = bundle?.sourceLocale ?? 'en-US';
    final allLocales = hasTranslations
        ? [sourceLocale, ...bundle.targetLocales]
        : [sourceLocale];

    Set<String>? selectedLocales;
    if (allLocales.length > 1) {
      selectedLocales = await AscLocalePickerDialog.show(
        context: context,
        allLocales: allLocales,
        sourceLocale: sourceLocale,
      );
      if (selectedLocales == null || !context.mounted) return;
    }

    // 3) Capture locale screenshots (only the selected locales).
    final captureProvider = ScreenshotCaptureProvider.of(context);
    if (captureProvider == null) return;

    final localeScreenshots = await captureProvider.captureAllLocaleScreenshots(
      context,
      selectedLocales: selectedLocales,
    );

    if (!context.mounted) return;

    if (localeScreenshots == null || localeScreenshots.isEmpty) {
      context.showAppSnackbar(
        'Failed to capture locale screenshots',
        type: AppSnackbarType.error,
      );
      return;
    }

    // 4) Show the upload sheet.
    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;
    showDialog(
      context: context,
      useSafeArea: !isSmallScreen,
      builder: (_) => BlocProvider(
        create: (_) => sl<PlayUploadCubit>()..init(),
        child: isSmallScreen
            ? Dialog.fullscreen(
                child: PlayUploadSheet(localeScreenshots: localeScreenshots),
              )
            : Dialog(
                child: PlayUploadSheet(localeScreenshots: localeScreenshots),
              ),
      ),
    );
  }

  Future<void> _saveAsTemplate(BuildContext context) async {
    final multiState = context.read<MultiScreenshotCubit>().state;
    _syncEditorChangesBack();

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., App Store Default',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final description = descriptionController.text.trim();

    final designs = multiState.designs;
    if (designs.isEmpty) return;

    // Strip runtime-specific fields so the template only stores visual styling.
    // deviceFrame, displayType, orientation, imageOverlays, magnifierOverlays,
    // gridSettings, doodleSettings, transparentBackground, and meshGradient
    // are all editor-session state that should NOT be baked into a template.
    final cleanDesigns = designs
        .map(
          (d) => ScreenshotDesign(
            backgroundColor: d.backgroundColor,
            backgroundGradient: d.backgroundGradient,
            overlays: d.overlays,
            iconOverlays: d.iconOverlays,
            padding: d.padding,
            imagePosition: d.imagePosition,
            frameRotation: d.frameRotation,
            frameRotationX: d.frameRotationX,
            frameRotationY: d.frameRotationY,
            cornerRadius: d.cornerRadius,
          ),
        )
        .toList();

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final colors = designs.first.backgroundGradient != null
        ? designs.first.backgroundGradient!.colors
        : [designs.first.backgroundColor];

    final template = ScreenshotPreset(
      id: id,
      name: name,
      description: description,
      thumbnailColors: colors,
      titleFont: 'Inter',
      designs: cleanDesigns,
    );

    try {
      await sl<TemplatePersistenceService>().saveTemplate(template);
      if (context.mounted) {
        context.showAppSnackbar(
          'Template saved successfully',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        context.showAppSnackbar(
          'Failed to save template',
          type: AppSnackbarType.error,
        );
      }
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

  Widget _buildDesktopBody(BuildContext context) {
    return Column(
      children: [
        const LocaleSwitcher(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bodyConstraints) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: _MultiCanvasArea(
                      screenshotController: _screenshotController,
                      viewportController: _viewportController,
                      onSyncBack: _syncEditorChangesBack,
                      onSyncActiveDesign: _syncActiveDesign,
                      onZoomToFit: _zoomToFit,
                    ),
                  ),
                  if (_isExporting) const _ExportOverlay(),
                  FloatingPanel(
                    constraints: bodyConstraints,
                    child: const DesktopEditorControls(),
                  ),
                  ZoomControlBar(
                    constraints: bodyConstraints,
                    controller: _viewportController,
                    onZoomToFit: _zoomToFit,
                    onZoomToSelection: () => _zoomToActive(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder<double>(
          valueListenable:
              _mobileControlsKey.currentState?.panelHeightNotifier ??
              ValueNotifier(kMobileControlsCollapsedHeight),
          builder: (context, panelHeight, _) {
            return Padding(
              padding: EdgeInsets.only(bottom: panelHeight),
              child: Column(
                children: [
                  const LocaleSwitcher(),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _MultiCanvasArea(
                            screenshotController: _screenshotController,
                            viewportController: _viewportController,
                            onSyncBack: _syncEditorChangesBack,
                            onSyncActiveDesign: _syncActiveDesign,
                            onZoomToFit: _zoomToFit,
                          ),
                        ),
                        if (_isExporting) const _ExportOverlay(),
                      ],
                    ),
                  ),
                ],
              ),
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
}
