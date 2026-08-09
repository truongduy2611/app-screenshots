import 'dart:io';

import 'package:app_screenshots/core/di/service_locator.dart';
import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_dialog.dart';
import 'package:app_screenshots/core/widgets/app_popup_menu.dart';
import 'package:app_screenshots/core/widgets/app_snackbar.dart';
import 'package:app_screenshots/core/widgets/genie_dialog_route.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/asc_app_config.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/board_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/saved_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/screenshot_design.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/screenshot_persistence_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/asc_upload_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/board_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/play_upload_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/screenshot_editor_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/translation_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/board_actions.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/helpers/image_picker_helper.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_app_config_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_credentials_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_locale_picker_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/asc_upload_sheet.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/board_canvas.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/board/board_template_picker_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/board_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/desktop_editor_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/grid_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/mobile_editor_controls.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/dot_grid_painter.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/floating_panel.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/locale_switcher.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/play_credentials_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/play_upload_sheet.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/preset_picker_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/screenshot_capture_provider.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/viewport/canvas_viewport_controller.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/viewport/figma_canvas_viewport.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/viewport/zoom_control_bar.dart';
import 'package:app_screenshots/features/settings/domain/repositories/settings_repository.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'board_page_canvas.dart';
part 'board_page_menus.dart';

/// Menu actions available in the board editor.
enum _BoardMenuAction {
  templates,
  artboardPresets,
  zoomFit,
  addZone,
  addFrame,
  arrangeZones,
  toggleZones,
  importImage,
  pasteImage,
  grid,
  save,
  saveNew,
  saveToFile,
  exportCurrent,
  exportAll,
  copy,
  shareDesign,
  uploadToAsc,
  uploadToGooglePlay,
  ascSettings,
}

/// Board editor — a single large canvas holding many device frames, with
/// crop zones marking the regions that become individual screenshots.
///
/// The multi-artboard editor ([MultiScreenshotPage]) keeps working exactly as
/// before; a design opens here only when [SavedDesign.isBoard] is true.
///
/// Two cubits split the work, mirroring how multi mode splits between
/// [MultiScreenshotCubit] and [ScreenshotEditorCubit]:
///
/// * [BoardCubit] owns the board canvas — frame elements, crop zones, size.
/// * [ScreenshotEditorCubit] owns the background and the decorations, as an
///   ordinary [ScreenshotDesign], so all existing control panels apply
///   unchanged.
class BoardPage extends StatelessWidget {
  const BoardPage({
    super.key,
    this.displayType,
    this.initialSavedDesign,
    this.folderId,
    this.sourceFilePath,
    this.initialZoneCount = 3,
  });

  final String? displayType;
  final SavedDesign? initialSavedDesign;
  final String? folderId;

  /// When set, the board was opened from this `.appshots` file and "Save"
  /// writes back to it.
  final String? sourceFilePath;

  /// Number of crop zones on a brand-new board.
  final int initialZoneCount;

  @override
  Widget build(BuildContext context) {
    final board = initialSavedDesign?.board;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BoardCubit(
            persistenceService: GetIt.I<ScreenshotPersistenceService>(),
            displayType: displayType,
            initialSavedDesign: initialSavedDesign,
            folderId: folderId ?? initialSavedDesign?.folderId,
            sourceFilePath: sourceFilePath,
            initialZoneCount: initialZoneCount,
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
      child: _BoardView(initialBackground: board?.background),
    );
  }
}

// =============================================================================

class _BoardView extends StatefulWidget {
  const _BoardView({this.initialBackground});

  /// Background + overlays loaded from a saved board, pushed into
  /// [ScreenshotEditorCubit] once the cubits exist.
  final ScreenshotDesign? initialBackground;

  @override
  State<_BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<_BoardView>
    with TickerProviderStateMixin, BoardActions {
  final ScreenshotController _screenshotController = ScreenshotController();
  late final CanvasViewportController _viewportController;
  final _mobileControlsKey = GlobalKey<MobileEditorControlsState>();

  bool _isExporting = false;

  /// Whether the board or the background/overlay editor was edited most
  /// recently. The two keep separate undo histories (the board owns frames and
  /// zones, the editor cubit owns background and decorations), so Undo has to
  /// target whichever changed last to feel like a single timeline.
  bool _boardEditedLast = false;
  int _lastBoardEditSeq = 0;

  late final BoardCubit _boardCubit;
  late final ScreenshotEditorCubit _editorCubit;

  // -- BoardActions interface --
  @override
  ScreenshotController get screenshotController => _screenshotController;

  @override
  void syncBoardBackground() {
    _boardCubit.syncBackground(_editorCubit.state.design);
  }

  @override
  void setExporting(bool value) {
    if (_isExporting == value) return;
    setState(() => _isExporting = value);
  }

  @override
  void initState() {
    super.initState();
    _boardCubit = context.read<BoardCubit>();
    _editorCubit = context.read<ScreenshotEditorCubit>();
    _lastBoardEditSeq = _boardCubit.state.editSeq;

    _viewportController = CanvasViewportController(
      vsync: this,
      minScale: 0.02,
      maxScale: 4.0,
    );

    // Seed the editor cubit with the saved board's background + overlays.
    final background = widget.initialBackground;
    if (background != null) {
      _editorCubit.loadDesignForMultiMode(background);
    } else {
      _editorCubit.loadDesignForMultiMode(_boardCubit.state.board.background);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoomToFit(animate: false);

    });
  }

  @override
  void dispose() {
    _viewportController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Zoom
  // ---------------------------------------------------------------------------

  /// World-space origin of the board inside the viewport. Matches the
  /// [_BoardCanvasArea] padding that leaves room for crop zone labels.
  static const _boardOrigin = Offset(
    _BoardCanvasArea.canvasPadding,
    _BoardCanvasArea.canvasPadding,
  );

  void _zoomToFit({bool animate = true}) {
    final board = _boardCubit.state.board;
    _viewportController.zoomToRect(
      _boardOrigin & board.size,
      padding: 200,
      animate: animate,
    );
  }

  /// Frames the selected zone (or frame), falling back to the whole board.
  void _zoomToSelection() {
    final state = _boardCubit.state;
    final rect =
        state.selectedZone?.rect ??
        state.selectedFrame?.rect ??
        state.board.exportableZones.firstOrNull?.rect;
    if (rect == null) {
      _zoomToFit();
      return;
    }
    _viewportController.zoomToRect(
      rect.shift(_boardOrigin),
      padding: 150,
      animate: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Undo / redo across the two histories
  // ---------------------------------------------------------------------------

  bool get _canUndo => _boardEditedLast
      ? _boardCubit.state.canUndo
      : _editorCubit.state.canUndo;

  bool get _canRedo => _boardEditedLast
      ? _boardCubit.state.canRedo
      : _editorCubit.state.canRedo;

  void _undo() {
    if (_boardEditedLast) {
      _boardCubit.undo();
    } else {
      _editorCubit.undo();
      syncBoardBackground();
    }
  }

  void _redo() {
    if (_boardEditedLast) {
      _boardCubit.redo();
    } else {
      _editorCubit.redo();
      syncBoardBackground();
    }
  }

  // ---------------------------------------------------------------------------
  // Keyboard
  // ---------------------------------------------------------------------------

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Let focused text fields handle their own keys.
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() !=
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

    if (isCmdOrCtrl) {
      if (key == LogicalKeyboardKey.keyS) {
        if (isShift) {
          saveBoardToLibrary(context, override: false);
        } else if (_boardCubit.state.sourceFilePath != null) {
          saveBoardToFile(context);
        } else {
          saveBoardToLibrary(
            context,
            override: _boardCubit.state.savedDesignId != null,
          );
        }
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.keyE) {
        if (isShift) {
          exportAllZones(context);
        } else {
          exportCurrentZone(context);
        }
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.keyU) {
        _showUploadSheet(context);
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.keyC) {
        if (_editorCubit.state.selectedOverlayId != null) {
          _editorCubit.copySelectedOverlay();
        } else {
          copyCurrentZoneToClipboard(context);
        }
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.keyV) {
        if (_editorCubit.hasOverlayClipboard) {
          _editorCubit.pasteOverlay();
          syncBoardBackground();
        } else {
          pasteImageIntoBoard(context);
        }
        return KeyEventResult.handled;
      }

      // Cmd+' — toggle crop zone outlines.
      if (key == LogicalKeyboardKey.quoteSingle) {
        _boardCubit.toggleCropZones();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.digit0) {
        _zoomToFit();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.digit1) {
        _viewportController.setScale(1.0);
        return KeyEventResult.handled;
      }
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

      if (key == LogicalKeyboardKey.keyZ) {
        if (isShift) {
          _redo();
        } else {
          _undo();
        }
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.keyD) {
        _editorCubit.deselectOverlay();
        _boardCubit.clearSelection();
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.escape) {
      _editorCubit.deselectOverlay();
      _boardCubit.clearSelection();
      return KeyEventResult.handled;
    }

    // Delete removes whichever element is selected: a board frame or zone
    // takes priority over an overlay, matching what the user last clicked.
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      final boardState = _boardCubit.state;
      if (boardState.selectedFrameId != null) {
        _boardCubit.removeFrame(boardState.selectedFrameId!);
      } else if (boardState.selectedZoneId != null) {
        _boardCubit.removeZone(boardState.selectedZoneId!);
      } else {
        _editorCubit.deleteSelectedOverlay();
        syncBoardBackground();
      }
      return KeyEventResult.handled;
    }

    // Arrow keys nudge the selected element.
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
      final boardState = _boardCubit.state;
      if (boardState.selectedFrameId != null) {
        _boardCubit.moveFrame(boardState.selectedFrameId!, delta);
      } else if (boardState.selectedZoneId != null) {
        _boardCubit.moveZone(boardState.selectedZoneId!, delta);
      } else {
        _editorCubit.nudgeSelectedOverlay(delta);
        syncBoardBackground();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
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
            // Track which history Undo should target.
            BlocListener<BoardCubit, BoardState>(
              listenWhen: (p, c) => p.editSeq != c.editSeq,
              listener: (_, state) {
                _lastBoardEditSeq = state.editSeq;
                setState(() => _boardEditedLast = true);
              },
            ),
            BlocListener<ScreenshotEditorCubit, ScreenshotEditorState>(
              listenWhen: (p, c) => !identical(p.design, c.design),
              listener: (_, _) {
                syncBoardBackground();
                if (_boardEditedLast &&
                    _boardCubit.state.editSeq == _lastBoardEditSeq) {
                  setState(() => _boardEditedLast = false);
                }
              },
            ),
            BlocListener<ScreenshotEditorCubit, ScreenshotEditorState>(
              listenWhen: (p, c) =>
                  !isDesktop &&
                  p.selectedOverlayId != c.selectedOverlayId &&
                  c.selectedOverlayId != null,
              listener: (_, _) {
                _mobileControlsKey.currentState?.selectTab(kTextTabIndex);
              },
            ),
          ],
          child: BlocSelector<BoardCubit, BoardState, AscAppConfig?>(
            selector: (state) => state.ascAppConfig,
            builder: (context, ascAppConfig) {
              return ScreenshotCaptureProvider(
                captureAllLocaleScreenshots: captureAllLocaleScreenshots,
                ascAppConfig: ascAppConfig,
                onAscAppConfigChanged: (config) =>
                    context.read<BoardCubit>().setAscAppConfig(config),
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

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDesktop) {
    return AppBar(
      titleSpacing: 0,
      title: BlocBuilder<BoardCubit, BoardState>(
        buildWhen: (p, c) => p.exportCount != c.exportCount,
        builder: (context, state) => Text(
          '${context.l10n.board} · '
          '${context.l10n.screenshotStudioCount(state.exportCount)}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      leading: BackButton(
        onPressed: () {
          syncBoardBackground();
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
      _buildUndoRedo(context),
      IconButton(
        icon: const Icon(Symbols.dashboard_customize_rounded),
        tooltip: context.l10n.boardTemplates,
        onPressed: () => _showBoardTemplatePicker(context),
      ),
      Builder(
        builder: (btnContext) => IconButton(
          icon: const Icon(Symbols.style_rounded),
          tooltip: context.l10n.artboardPresets,
          onPressed: () => _showArtboardPresetPicker(
            context,
            sourceRect: rectFromContext(btnContext),
          ),
        ),
      ),
      BlocBuilder<BoardCubit, BoardState>(
        buildWhen: (p, c) => p.showCropZones != c.showCropZones,
        builder: (context, state) => IconButton(
          icon: Icon(
            state.showCropZones
                ? Symbols.crop_rounded
                : Symbols.crop_free_rounded,
          ),
          tooltip: state.showCropZones
              ? context.l10n.hideCropZones
              : context.l10n.showCropZones,
          onPressed: () => context.read<BoardCubit>().toggleCropZones(),
        ),
      ),
      BlocBuilder<BoardCubit, BoardState>(
        buildWhen: (p, c) => p.board.canAddZone != c.board.canAddZone,
        builder: (context, state) => IconButton(
          icon: const Icon(Symbols.add_box_rounded),
          tooltip: state.board.canAddZone
              ? context.l10n.addCropZone
              : context.l10n.zoneLimitReached(BoardDesign.maxZones),
          onPressed: state.board.canAddZone
              ? () => context.read<BoardCubit>().addZone()
              : null,
        ),
      ),
      IconButton(
        icon: const Icon(Symbols.add_photo_alternate_rounded),
        tooltip: context.l10n.addFrame,
        onPressed: () => context.read<BoardCubit>().addFrame(
          nearZone: context.read<BoardCubit>().state.selectedZone,
        ),
      ),
      IconButton(
        icon: const Icon(Symbols.fit_screen_rounded),
        tooltip: context.l10n.zoomToFit,
        onPressed: _zoomToFit,
      ),
      IconButton(
        icon: const Icon(Symbols.image_rounded),
        tooltip: context.l10n.importImage,
        onPressed: () => _importImages(context),
      ),
      IconButton(
        icon: const Icon(Symbols.content_paste_rounded),
        tooltip: context.l10n.pasteFromClipboard,
        onPressed: () => pasteImageIntoBoard(context),
      ),
      Builder(
        builder: (btnContext) => IconButton(
          icon: const Icon(Symbols.grid_on_rounded),
          tooltip: context.l10n.grid,
          onPressed: () => _showGridDialog(context, btnContext),
        ),
      ),
      BlocBuilder<BoardCubit, BoardState>(
        builder: (context, state) => _BoardSaveExportMenu(
          state: state,
          onAction: (value) => _handleMenuAction(context, value),
        ),
      ),
    ];
  }

  List<Widget> _buildMobileActions(BuildContext context) {
    return [
      _buildUndoRedo(context),
      IconButton(
        icon: const Icon(Symbols.download_for_offline_rounded),
        tooltip: context.l10n.exportAll,
        onPressed: () => exportAllZones(context),
      ),
      BlocBuilder<BoardCubit, BoardState>(
        builder: (context, state) => _BoardMobileOverflowMenu(
          state: state,
          onAction: (value) => _handleMenuAction(context, value),
        ),
      ),
    ];
  }

  Widget _buildUndoRedo(BuildContext context) {
    // Rebuilds on either history changing, since Undo targets whichever was
    // touched last.
    return BlocBuilder<BoardCubit, BoardState>(
      buildWhen: (p, c) => p.canUndo != c.canUndo || p.canRedo != c.canRedo,
      builder: (context, _) {
        return BlocBuilder<ScreenshotEditorCubit, ScreenshotEditorState>(
          buildWhen: (p, c) => p.canUndo != c.canUndo || p.canRedo != c.canRedo,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Symbols.undo_rounded),
                tooltip: context.l10n.undo,
                onPressed: _canUndo ? _undo : null,
              ),
              IconButton(
                icon: const Icon(Symbols.redo_rounded),
                tooltip: context.l10n.redo,
                onPressed: _canRedo ? _redo : null,
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _importImages(BuildContext context) async {
    final cubit = context.read<BoardCubit>();
    final files = await ImagePickerHelper.pickImage(
      context: context,
      allowMultiple: true,
    );
    if (files.isEmpty) return;
    await cubit.importImages(files);
  }

  void _handleMenuAction(BuildContext context, _BoardMenuAction value) {
    final state = context.read<BoardCubit>().state;
    final canOverride = state.savedDesignId != null;

    switch (value) {
      case _BoardMenuAction.templates:
        _showBoardTemplatePicker(context);
      case _BoardMenuAction.artboardPresets:
        _showArtboardPresetPicker(context);
      case _BoardMenuAction.zoomFit:
        _zoomToFit();
      case _BoardMenuAction.addZone:
        context.read<BoardCubit>().addZone();
      case _BoardMenuAction.addFrame:
        context.read<BoardCubit>().addFrame(nearZone: state.selectedZone);
      case _BoardMenuAction.arrangeZones:
        context.read<BoardCubit>().autoArrangeZones();
      case _BoardMenuAction.toggleZones:
        context.read<BoardCubit>().toggleCropZones();
      case _BoardMenuAction.importImage:
        _importImages(context);
      case _BoardMenuAction.pasteImage:
        pasteImageIntoBoard(context);
      case _BoardMenuAction.grid:
        _showControls(context, const GridControls());
      case _BoardMenuAction.save:
        saveBoardToLibrary(context, override: canOverride);
      case _BoardMenuAction.saveNew:
        saveBoardToLibrary(context, override: false);
      case _BoardMenuAction.saveToFile:
        saveBoardToFile(context);
      case _BoardMenuAction.exportCurrent:
        exportCurrentZone(context);
      case _BoardMenuAction.exportAll:
        exportAllZones(context);
      case _BoardMenuAction.copy:
        copyCurrentZoneToClipboard(context);
      case _BoardMenuAction.shareDesign:
        shareBoardFile(context);
      case _BoardMenuAction.uploadToAsc:
        _showUploadSheet(context);
      case _BoardMenuAction.uploadToGooglePlay:
        _showPlayUploadSheet(context);
      case _BoardMenuAction.ascSettings:
        _showAscSettings(context);
    }
  }

  /// Applies a preset's styling to the board background and decorations.
  ///
  /// A preset stores per-artboard styling; on a board the first template drives
  /// the background and its overlays are laid out across the crop zones, so a
  /// template designed for N artboards still reads correctly.
  /// Board layouts — background *and* frame placement. Artboard presets remain
  /// reachable via [_showArtboardPresetPicker] for their text styling.
  Future<void> _showBoardTemplatePicker(BuildContext context) async {
    final template = await BoardTemplatePickerDialog.show(context);
    if (template == null || !context.mounted) return;

    final confirmed = await AppDialog.show(
      context,
      title: context.l10n.applyTemplate,
      maxWidth: 400,
      content: context.l10n.applyBoardTemplateConfirm,
      confirmLabel: context.l10n.apply,
      cancelLabel: context.l10n.cancel,
      icon: Symbols.dashboard_customize_rounded,
    );
    if (confirmed != true || !context.mounted) return;

    final boardCubit = context.read<BoardCubit>();
    final editorCubit = context.read<ScreenshotEditorCubit>();

    // Frames and background are owned by different cubits, so both halves are
    // applied here, then synced so a save/export sees the finished board.
    boardCubit.applyTemplate(template);
    editorCubit.applyBoardTemplateBackground(template);
    syncBoardBackground();
  }

  void _showArtboardPresetPicker(BuildContext context, {Rect? sourceRect}) {
    PresetPickerDialog.show(context, sourceRect: sourceRect).then((
      preset,
    ) async {
      if (preset == null || !context.mounted) return;

      final confirmed = await AppDialog.show(
        context,
        title: context.l10n.applyTemplate,
        maxWidth: 400,
        content: context.l10n.applyTemplateConfirm,
        confirmLabel: context.l10n.apply,
        cancelLabel: context.l10n.cancel,
        icon: Symbols.style_rounded,
      );
      if (confirmed != true || !context.mounted) return;

      final boardCubit = context.read<BoardCubit>();
      final editorCubit = context.read<ScreenshotEditorCubit>();
      editorCubit.applyBoardPreset(
        preset,
        zones: boardCubit.state.board.cropZones,
      );
      syncBoardBackground();
    });
  }

  Future<void> _showAscSettings(BuildContext context) async {
    final cubit = context.read<BoardCubit>();
    final result = await AscAppConfigDialog.show(
      context,
      initialConfig: cubit.state.ascAppConfig,
    );
    if (result != null && result.didSave && context.mounted) {
      cubit.setAscAppConfig(result.config);
      context.showAppSnackbar(
        result.config == null
            ? context.l10n.ascAppConfigCleared
            : context.l10n.ascAppConfigSaved,
        type: AppSnackbarType.success,
      );
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

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  /// Locales the user wants rendered, or `null` when they cancelled.
  /// Returns an empty set when there is only the source locale to render.
  Future<Set<String>?> _pickLocales(BuildContext context) async {
    final bundle = context.read<TranslationCubit>().state.bundle;
    final hasTranslations = bundle != null && bundle.translations.isNotEmpty;
    final sourceLocale = bundle?.sourceLocale ?? 'en-US';
    final allLocales = hasTranslations
        ? [sourceLocale, ...bundle.targetLocales]
        : [sourceLocale];

    if (allLocales.length <= 1) return <String>{};

    return AscLocalePickerDialog.show(
      context: context,
      allLocales: allLocales,
      sourceLocale: sourceLocale,
    );
  }

  Future<void> _showUploadSheet(BuildContext context) async {
    final repo = sl<SettingsRepository>();
    final creds = await repo.getAscCredentials();
    if (creds == null || !creds.isValid) {
      if (!context.mounted) return;
      final saved = await AscCredentialsDialog.show(context);
      if (!saved || !context.mounted) return;
    }

    if (!context.mounted) return;
    final selectedLocales = await _pickLocales(context);
    if (selectedLocales == null || !context.mounted) return;

    final captureProvider = ScreenshotCaptureProvider.of(context);
    if (captureProvider == null) return;

    final localeScreenshots = await captureProvider.captureAllLocaleScreenshots(
      context,
      selectedLocales: selectedLocales.isEmpty ? null : selectedLocales,
    );

    if (!context.mounted) return;
    if (localeScreenshots == null || localeScreenshots.isEmpty) {
      context.showAppSnackbar(
        context.l10n.failedToExport,
        type: AppSnackbarType.error,
      );
      return;
    }

    final savedConfig = captureProvider.ascAppConfig;
    // A board's zones can target different formats; the first exported zone's
    // format is the sensible default for the upload sheet's app selection.
    final displayType = context
        .read<BoardCubit>()
        .state
        .board
        .exportableZones
        .firstOrNull
        ?.displayType;

    final isSmallScreen = MediaQuery.sizeOf(context).width < 600;
    if (!context.mounted) return;
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

  Future<void> _showPlayUploadSheet(BuildContext context) async {
    // Play's limit is lower than Apple's, so a board built for the App Store
    // can legitimately be over it. Confirm before uploading rather than
    // letting the extra screenshots fail at the far end.
    final board = _boardCubit.state.board;
    if (board.exceedsPlayLimit) {
      final proceed = await AppDialog.show(
        context,
        title: context.l10n.uploadToGooglePlay,
        maxWidth: 420,
        content: context.l10n.playLimitWarning(
          BoardDesign.maxPlayZones,
          board.exportableZones.length - BoardDesign.maxPlayZones,
        ),
        confirmLabel: context.l10n.confirm,
        cancelLabel: context.l10n.cancel,
        icon: Symbols.warning_rounded,
      );
      if (proceed != true || !context.mounted) return;
    }

    final repo = sl<SettingsRepository>();
    final creds = await repo.getPlayCredentials();
    if (creds == null || !creds.isValid) {
      if (!context.mounted) return;
      final saved = await PlayCredentialsDialog.show(context);
      if (!saved || !context.mounted) return;
    }

    if (!context.mounted) return;
    final selectedLocales = await _pickLocales(context);
    if (selectedLocales == null || !context.mounted) return;

    final captureProvider = ScreenshotCaptureProvider.of(context);
    if (captureProvider == null) return;

    final localeScreenshots = await captureProvider.captureAllLocaleScreenshots(
      context,
      selectedLocales: selectedLocales.isEmpty ? null : selectedLocales,
    );

    if (!context.mounted) return;
    if (localeScreenshots == null || localeScreenshots.isEmpty) {
      context.showAppSnackbar(
        context.l10n.failedToExport,
        type: AppSnackbarType.error,
      );
      return;
    }

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

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

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
                    child: _BoardCanvasArea(
                      screenshotController: _screenshotController,
                      viewportController: _viewportController,
                      isExporting: _isExporting,
                    ),
                  ),
                  if (_isExporting) const _BoardExportOverlay(),
                  FloatingPanel(
                    constraints: bodyConstraints,
                    child: DesktopEditorControls(
                      frameTab: const BoardControls(),
                      frameTabIcon: Symbols.dashboard_customize_rounded,
                      frameTabLabel: context.l10n.board,
                    ),
                  ),
                  ZoomControlBar(
                    constraints: bodyConstraints,
                    controller: _viewportController,
                    onZoomToFit: _zoomToFit,
                    onZoomToSelection: _zoomToSelection,
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
                          child: _BoardCanvasArea(
                            screenshotController: _screenshotController,
                            viewportController: _viewportController,
                            isExporting: _isExporting,
                          ),
                        ),
                        if (_isExporting) const _BoardExportOverlay(),
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
          child: MobileEditorControls(
            key: _mobileControlsKey,
            frameTab: const BoardControls(),
            frameTabIcon: Symbols.dashboard_customize_rounded,
            frameTabLabel: context.l10n.board,
          ),
        ),
      ],
    );
  }
}
