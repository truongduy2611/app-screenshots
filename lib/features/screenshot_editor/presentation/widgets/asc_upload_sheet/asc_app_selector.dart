part of '../asc_upload_sheet.dart';

// ─── App Selector (with search + icons) ─────────────────────────────

class _AppSelector extends StatefulWidget {
  final List<App> apps;

  const _AppSelector({required this.apps});

  @override
  State<_AppSelector> createState() => _AppSelectorState();
}

class _AppSelectorState extends State<_AppSelector> {
  String _searchQuery = '';

  List<App> get _filteredApps {
    if (_searchQuery.isEmpty) return widget.apps;
    final q = _searchQuery.toLowerCase();
    return widget.apps
        .where(
          (app) =>
              app.name.toLowerCase().contains(q) ||
              app.bundleId.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.apps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.apps,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(context.l10n.noAppsFound, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              context.l10n.checkApiKeyPermissions,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredApps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.selectApp,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: context.l10n.searchApps,
            prefixIcon: Icon(Symbols.search, size: 20),
            isDense: true,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.l10n.noAppsMatchQuery(_searchQuery),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) => _AppTile(app: filtered[index]),
            ),
          ),
      ],
    );
  }
}

/// A single app tile using AppListTile.
class _AppTile extends StatelessWidget {
  final App app;

  const _AppTile({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AppListTile(
        leading: _AppIcon(iconUrl: app.iconUrl),
        title: Text(
          app.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          app.bundleId,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        onTap: () => context.read<AscUploadCubit>().selectApp(app),
      ),
    );
  }
}

/// Displays the app icon. Falls back to a generic icon.
class _AppIcon extends StatelessWidget {
  final String? iconUrl;
  final double size;

  const _AppIcon({this.iconUrl, this.size = 36});

  @override
  Widget build(BuildContext context) {
    if (iconUrl == null) return _fallbackIcon(context);

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Image.network(
        iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackIcon(context),
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        Symbols.apps_rounded,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
