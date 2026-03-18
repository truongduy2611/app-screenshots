import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/features/screenshot_editor/data/models/design_folder.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Dialog that lets the user pick a destination folder (or root) for a design.
class MoveToFolderDialog extends StatelessWidget {
  final List<DesignFolder> folders;
  final String? currentFolderId;
  final Set<String> excludeFolderIds;

  const MoveToFolderDialog({
    super.key,
    required this.folders,
    this.currentFolderId,
    this.excludeFolderIds = const {},
  });

  /// Shows the dialog and returns the selected folder ID.
  /// Returns `'__root__'` to move to root, a folder ID string for a folder,
  /// or `null` if the user cancelled / dismissed.
  static Future<String?> show(
    BuildContext context, {
    required List<DesignFolder> folders,
    String? currentFolderId,
    Set<String> excludeFolderIds = const {},
  }) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => MoveToFolderDialog(
        folders: folders,
        currentFolderId: currentFolderId,
        excludeFolderIds: excludeFolderIds,
      ),
    );
    // null = tapped outside, '__cancelled__' = cancel button
    if (result == null || result == '__cancelled__') return null;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return AlertDialog(
      title: Text(context.l10n.moveToFolder),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "No Folder" (root) option
            _FolderOption(
              icon: Symbols.home_rounded,
              label: context.l10n.noFolder,
              isSelected: currentFolderId == null,
              primary: primary,
              isDark: isDark,
              onTap: () => Navigator.pop(context, '__root__'),
            ),
            const Divider(height: 1),
            // Folder list (exclude any folders being moved)
            Builder(
              builder: (context) {
                final visibleFolders = excludeFolderIds.isEmpty
                    ? folders
                    : folders
                          .where((f) => !excludeFolderIds.contains(f.id))
                          .toList();
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: visibleFolders.length,
                    itemBuilder: (context, index) {
                      final folder = visibleFolders[index];
                      final isCurrentFolder = folder.id == currentFolderId;
                      return _FolderOption(
                        icon: Symbols.folder_rounded,
                        label: folder.name,
                        isSelected: isCurrentFolder,
                        primary: primary,
                        isDark: isDark,
                        onTap: isCurrentFolder
                            ? null
                            : () => Navigator.pop(context, folder.id),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, '__cancelled__'),
          child: Text(context.l10n.cancel),
        ),
      ],
    );
  }
}

class _FolderOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color primary;
  final bool isDark;
  final VoidCallback? onTap;

  const _FolderOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Symbols.check_rounded, color: primary, size: 20)
          : null,
      onTap: onTap,
      enabled: !isSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
