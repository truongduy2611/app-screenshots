part of 'multi_screenshot_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared save / export menu items
// ─────────────────────────────────────────────────────────────────────────────

List<AppPopupMenuItem<_MultiMenuAction>> _buildSaveItems(
  BuildContext context,
  MultiScreenshotState multiState,
) {
  final canOverride = multiState.savedDesignId != null;
  final hasSourceFile = multiState.sourceFilePath != null;
  return [
    if (hasSourceFile)
      AppPopupMenuItem(
        value: _MultiMenuAction.saveToFile,
        icon: Symbols.save_rounded,
        title: context.l10n.save,
      ),
    if (canOverride) ...[
      AppPopupMenuItem(
        value: _MultiMenuAction.save,
        icon: Symbols.save_rounded,
        title: hasSourceFile ? context.l10n.saveToLibrary : context.l10n.save,
      ),
      AppPopupMenuItem(
        value: _MultiMenuAction.saveNew,
        icon: Symbols.content_copy_rounded,
        title: context.l10n.saveAs,
      ),
    ] else
      AppPopupMenuItem(
        value: _MultiMenuAction.save,
        icon: Symbols.save_rounded,
        title: hasSourceFile ? context.l10n.saveToLibrary : context.l10n.save,
      ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Save / Export popup menu for multi-screenshot page
// ─────────────────────────────────────────────────────────────────────────────

class _SaveExportMenu extends StatelessWidget {
  final MultiScreenshotState multiState;
  final void Function(_MultiMenuAction) onAction;

  const _SaveExportMenu({required this.multiState, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return AppPopupMenu<_MultiMenuAction>(
      tooltip: '${context.l10n.save} / ${context.l10n.export}',
      onSelected: onAction,
      items: [
        ..._buildSaveItems(context, multiState),
        AppPopupMenuItem(
          value: _MultiMenuAction.exportSingle,
          icon: Symbols.download_rounded,
          title: context.l10n.exportCurrent,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.exportAll,
          icon: Symbols.download_for_offline_rounded,
          title: context.l10n.exportAll,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.copy,
          icon: Symbols.content_copy_rounded,
          title: context.l10n.copyToClipboard,
        ),
        const AppPopupMenuItem.divider(),
        AppPopupMenuItem(
          value: _MultiMenuAction.uploadToAsc,
          icon: Symbols.cloud_upload_rounded,
          title: context.l10n.uploadToAsc,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.uploadExistingToAsc,
          icon: Symbols.folder_zip_rounded,
          title: context.l10n.uploadExistingFolderToAsc,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.shareDesign,
          icon: Symbols.share_rounded,
          title: context.l10n.shareDesignFile,
        ),
        const AppPopupMenuItem.divider(),
        AppPopupMenuItem(
          value: _MultiMenuAction.saveAsTemplate,
          icon: Symbols.bookmark_add_rounded,
          title: context.l10n.saveAsTemplate,
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

class _MobileOverflowMenu extends StatelessWidget {
  final MultiScreenshotState multiState;
  final void Function(_MultiMenuAction) onAction;

  const _MobileOverflowMenu({required this.multiState, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return AppPopupMenu<_MultiMenuAction>(
      tooltip: context.l10n.more,
      onSelected: onAction,
      items: [
        AppPopupMenuItem(
          value: _MultiMenuAction.templates,
          icon: Symbols.style_rounded,
          title: context.l10n.templates,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.zoomFit,
          icon: Symbols.fit_screen_rounded,
          title: context.l10n.zoomToFit,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.addScreenshot,
          icon: Symbols.add_photo_alternate_rounded,
          title: context.l10n.addScreenshot,
          enabled: multiState.canAddMore,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.importImage,
          icon: Symbols.image_rounded,
          title: context.l10n.importImage,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.pasteImage,
          icon: Symbols.content_paste_rounded,
          title: context.l10n.pasteFromClipboard,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.grid,
          icon: Symbols.grid_on_rounded,
          title: context.l10n.grid,
        ),
        const AppPopupMenuItem.divider(),
        ..._buildSaveItems(context, multiState),
        AppPopupMenuItem(
          value: _MultiMenuAction.exportSingle,
          icon: Symbols.download_rounded,
          title: context.l10n.exportCurrent,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.copy,
          icon: Symbols.content_copy_rounded,
          title: context.l10n.copyToClipboard,
        ),
        const AppPopupMenuItem.divider(),
        AppPopupMenuItem(
          value: _MultiMenuAction.shareDesign,
          icon: Symbols.share_rounded,
          title: context.l10n.shareDesignFile,
        ),
        AppPopupMenuItem(
          value: _MultiMenuAction.saveAsTemplate,
          icon: Symbols.bookmark_add_rounded,
          title: context.l10n.saveAsTemplate,
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Symbols.more_vert_rounded),
      ),
    );
  }
}
