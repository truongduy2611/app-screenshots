part of 'board_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared save items
// ─────────────────────────────────────────────────────────────────────────────

List<AppPopupMenuItem<_BoardMenuAction>> _buildBoardSaveItems(
  BuildContext context,
  BoardState state,
) {
  final canOverride = state.savedDesignId != null;
  final hasSourceFile = state.sourceFilePath != null;

  return [
    if (hasSourceFile)
      AppPopupMenuItem(
        value: _BoardMenuAction.saveToFile,
        icon: Symbols.save_rounded,
        title: context.l10n.save,
      ),
    AppPopupMenuItem(
      value: _BoardMenuAction.save,
      icon: Symbols.save_rounded,
      title: hasSourceFile ? context.l10n.saveToLibrary : context.l10n.save,
    ),
    if (canOverride)
      AppPopupMenuItem(
        value: _BoardMenuAction.saveNew,
        icon: Symbols.content_copy_rounded,
        title: context.l10n.saveAs,
      ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Save / export menu
// ─────────────────────────────────────────────────────────────────────────────

class _BoardSaveExportMenu extends StatelessWidget {
  const _BoardSaveExportMenu({required this.state, required this.onAction});

  final BoardState state;
  final void Function(_BoardMenuAction) onAction;

  @override
  Widget build(BuildContext context) {
    final hasZones = state.exportCount > 0;

    return AppPopupMenu<_BoardMenuAction>(
      tooltip: '${context.l10n.save} / ${context.l10n.export}',
      onSelected: onAction,
      items: [
        ..._buildBoardSaveItems(context, state),
        AppPopupMenuItem(
          value: _BoardMenuAction.exportCurrent,
          icon: Symbols.download_rounded,
          title: context.l10n.exportCurrent,
          enabled: hasZones,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.exportAll,
          icon: Symbols.download_for_offline_rounded,
          title: context.l10n.exportAll,
          enabled: hasZones,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.copy,
          icon: Symbols.content_copy_rounded,
          title: context.l10n.copyToClipboard,
          enabled: hasZones,
        ),
        const AppPopupMenuItem.divider(),
        AppPopupMenuItem(
          value: _BoardMenuAction.uploadToAsc,
          icon: Symbols.cloud_upload_rounded,
          title: context.l10n.uploadToAsc,
          enabled: hasZones,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.ascSettings,
          icon: Symbols.settings_suggest_rounded,
          title: context.l10n.ascAppConfigSettings,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.uploadToGooglePlay,
          icon: Symbols.android_rounded,
          title: context.l10n.uploadToGooglePlay,
          enabled: hasZones,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.shareDesign,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile overflow menu
// ─────────────────────────────────────────────────────────────────────────────

class _BoardMobileOverflowMenu extends StatelessWidget {
  const _BoardMobileOverflowMenu({
    required this.state,
    required this.onAction,
  });

  final BoardState state;
  final void Function(_BoardMenuAction) onAction;

  @override
  Widget build(BuildContext context) {
    final hasZones = state.exportCount > 0;

    return AppPopupMenu<_BoardMenuAction>(
      tooltip: context.l10n.more,
      onSelected: onAction,
      items: [
        AppPopupMenuItem(
          value: _BoardMenuAction.templates,
          icon: Symbols.dashboard_customize_rounded,
          title: context.l10n.boardTemplates,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.artboardPresets,
          icon: Symbols.style_rounded,
          title: context.l10n.artboardPresets,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.zoomFit,
          icon: Symbols.fit_screen_rounded,
          title: context.l10n.zoomToFit,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.addZone,
          icon: Symbols.add_box_rounded,
          title: context.l10n.addCropZone,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.addFrame,
          icon: Symbols.add_photo_alternate_rounded,
          title: context.l10n.addFrame,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.arrangeZones,
          icon: Symbols.view_column_rounded,
          title: context.l10n.arrangeZones,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.toggleZones,
          icon: state.showCropZones
              ? Symbols.crop_free_rounded
              : Symbols.crop_rounded,
          title: state.showCropZones
              ? context.l10n.hideCropZones
              : context.l10n.showCropZones,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.importImage,
          icon: Symbols.image_rounded,
          title: context.l10n.importImage,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.pasteImage,
          icon: Symbols.content_paste_rounded,
          title: context.l10n.pasteFromClipboard,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.grid,
          icon: Symbols.grid_on_rounded,
          title: context.l10n.grid,
        ),
        const AppPopupMenuItem.divider(),
        ..._buildBoardSaveItems(context, state),
        AppPopupMenuItem(
          value: _BoardMenuAction.exportCurrent,
          icon: Symbols.download_rounded,
          title: context.l10n.exportCurrent,
          enabled: hasZones,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.copy,
          icon: Symbols.content_copy_rounded,
          title: context.l10n.copyToClipboard,
          enabled: hasZones,
        ),
        const AppPopupMenuItem.divider(),
        AppPopupMenuItem(
          value: _BoardMenuAction.uploadToAsc,
          icon: Symbols.cloud_upload_rounded,
          title: context.l10n.uploadToAsc,
          enabled: hasZones,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.uploadToGooglePlay,
          icon: Symbols.android_rounded,
          title: context.l10n.uploadToGooglePlay,
          enabled: hasZones,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.ascSettings,
          icon: Symbols.settings_suggest_rounded,
          title: context.l10n.ascAppConfigSettings,
        ),
        AppPopupMenuItem(
          value: _BoardMenuAction.shareDesign,
          icon: Symbols.share_rounded,
          title: context.l10n.shareDesignFile,
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Symbols.more_vert_rounded),
      ),
    );
  }
}
