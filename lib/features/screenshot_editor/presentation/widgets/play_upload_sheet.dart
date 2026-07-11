import 'dart:io';

import 'package:app_screenshots/core/extensions/context_extensions.dart';
import 'package:app_screenshots/core/widgets/app_button.dart';
import 'package:app_screenshots/core/widgets/app_card.dart';
import 'package:app_screenshots/features/screenshot_editor/data/services/play_upload_service.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/cubit/play_upload_cubit.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/play_credentials_dialog.dart';
import 'package:app_screenshots/features/screenshot_editor/presentation/widgets/controls/app_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Sheet for uploading screenshots to the Google Play Console.
class PlayUploadSheet extends StatelessWidget {
  final Map<String, List<File>> localeScreenshots;

  const PlayUploadSheet({super.key, required this.localeScreenshots});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayUploadCubit, PlayUploadState>(
      builder: (context, state) {
        // Auto-select all locales the first time the sheet is ready.
        if (state.selectedLocales.isEmpty &&
            state.status == PlayUploadStatus.ready &&
            state.hasCredentials) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<PlayUploadCubit>().setSelectedLocales(
                localeScreenshots.keys.toSet(),
              );
            }
          });
        }

        final isSmall = MediaQuery.sizeOf(context).width < 600;

        return Container(
          constraints: BoxConstraints(
            maxWidth: isSmall ? double.infinity : 520,
            maxHeight: isSmall ? double.infinity : 640,
            minHeight: isSmall ? 0 : 640,
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 16 : 24),
            child: SafeArea(
              top: isSmall,
              bottom: false,
              left: false,
              right: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  Expanded(child: _buildBody(context, state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Symbols.cloud_upload,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.uploadToGooglePlay,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Symbols.close, size: 20),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, PlayUploadState state) {
    if (!state.hasCredentials) {
      return _NoCredentialsPrompt(
        onConfigure: () async {
          final saved = await PlayCredentialsDialog.show(context);
          if (saved && context.mounted) {
            context.read<PlayUploadCubit>().reset();
          }
        },
      );
    }

    switch (state.status) {
      case PlayUploadStatus.initial:
        return const Center(child: CircularProgressIndicator());

      case PlayUploadStatus.ready:
        return SingleChildScrollView(
          child: _ReadyView(
            localeScreenshots: localeScreenshots,
            state: state,
          ),
        );

      case PlayUploadStatus.uploading:
        return Center(
          child: SingleChildScrollView(
            child: _ProgressView(progress: state.progress),
          ),
        );

      case PlayUploadStatus.done:
        return Center(
          child: SingleChildScrollView(
            child: _DoneView(
              result: state.result!,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        );

      case PlayUploadStatus.error:
        final message = switch (state.failure) {
          PlayUploadFailure.autoSubmitRequired =>
            context.l10n.playErrorAutoSubmitRequired,
          PlayUploadFailure.declarationRequired =>
            context.l10n.playErrorDeclarationRequired,
          _ => state.errorMessage ?? context.l10n.unknownError,
        };
        return Center(
          child: _ErrorView(
            message: message,
            onRetry: () => context.read<PlayUploadCubit>().reset(),
          ),
        );
    }
  }
}

// ─── No Credentials Prompt ────────────────────────────────────────────

class _NoCredentialsPrompt extends StatelessWidget {
  final VoidCallback onConfigure;

  const _NoCredentialsPrompt({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Symbols.key_off, size: 28, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noServiceAccountConfigured,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.playSetupHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            onPressed: onConfigure,
            icon: Symbols.key,
            label: context.l10n.configureServiceAccount,
          ),
        ],
      ),
    );
  }
}

// ─── Ready View ───────────────────────────────────────────────────────

class _ReadyView extends StatefulWidget {
  final Map<String, List<File>> localeScreenshots;
  final PlayUploadState state;

  const _ReadyView({required this.localeScreenshots, required this.state});

  @override
  State<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends State<_ReadyView> {
  late final TextEditingController _packageController;

  @override
  void initState() {
    super.initState();
    _packageController = TextEditingController(text: widget.state.packageName);
  }

  @override
  void didUpdateWidget(_ReadyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when the cubit fills in a remembered package.
    if (widget.state.packageName != _packageController.text) {
      _packageController.text = widget.state.packageName;
    }
  }

  @override
  void dispose() {
    _packageController.dispose();
    super.dispose();
  }

  int get _totalSelectedFiles {
    int count = 0;
    for (final entry in widget.localeScreenshots.entries) {
      if (widget.state.selectedLocales.contains(entry.key)) {
        count += entry.value.length;
      }
    }
    return count;
  }

  bool get _allSelected =>
      widget.state.selectedLocales.length == widget.localeScreenshots.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.sizeOf(context).width < 600;
    final cubit = context.read<PlayUploadCubit>();
    final state = widget.state;
    final selectedLocales = state.selectedLocales;
    final totalFiles = _totalSelectedFiles;
    final exceedsLimit = selectedLocales.any(
      (l) =>
          (widget.localeScreenshots[l]?.length ?? 0) >
          kPlayMaxScreenshotsPerType,
    );
    final effectiveImageType = kPlayImageTypes.containsKey(state.imageType)
        ? state.imageType
        : kPlayImageTypes.keys.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Package name ──
        TextField(
          controller: _packageController,
          onChanged: cubit.setPackageName,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: context.l10n.packageName,
            hintText: context.l10n.packageNameHint,
            prefixIcon: const Icon(Symbols.android, size: 20),
            isDense: true,
          ),
        ),
        const SizedBox(height: 14),

        // ── Image type dropdown ──
        DropdownButtonFormField<String>(
          initialValue: effectiveImageType,
          decoration: InputDecoration(labelText: context.l10n.imageType),
          icon: const Icon(Symbols.keyboard_arrow_down_rounded, size: 22),
          borderRadius: BorderRadius.circular(14),
          items: kPlayImageTypes.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (value) {
            if (value != null) cubit.setImageType(value);
          },
        ),
        const SizedBox(height: 14),

        // ── Replace / Append toggle ──
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: true,
              label: Text(context.l10n.replace),
              icon: isSmall ? null : const Icon(Symbols.delete_sweep, size: 18),
            ),
            ButtonSegment(
              value: false,
              label: Text(context.l10n.append),
              icon: isSmall
                  ? null
                  : const Icon(Symbols.add_photo_alternate, size: 18),
            ),
          ],
          selected: {state.deleteExisting},
          onSelectionChanged: (s) => cubit.setDeleteExisting(s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 14),

        // ── Commit as draft option ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.commitAsDraft,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.commitAsDraftDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AppSwitch(
              value: state.commitAsDraft,
              onChanged: cubit.setCommitAsDraft,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Locales header ──
        Row(
          children: [
            Text(
              context.l10n.localesHeader,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => cubit.setSelectedLocales(
                  _allSelected ? {} : widget.localeScreenshots.keys.toSet(),
                ),
                child: Text(
                  _allSelected
                      ? context.l10n.deselectAll
                      : context.l10n.selectAll,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.localeScreenshots.entries.map((entry) {
              return _LocaleCheckTile(
                locale: entry.key,
                fileCount: entry.value.length,
                isSelected: selectedLocales.contains(entry.key),
                onChanged: () => cubit.toggleLocale(entry.key),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // ── Summary ──
        if (selectedLocales.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Symbols.info_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: context.l10n.nScreenshots(totalFiles),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' ${context.l10n.across} '),
                          TextSpan(
                            text: context.l10n.nLocales(selectedLocales.length),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Screenshot-limit warning ──
        if (exceedsLimit)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Symbols.warning_rounded,
                    size: 18,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.playMaxScreenshotsNote(
                        kPlayMaxScreenshotsPerType,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Upload button ──
        AppButton.primary(
          onPressed:
              (selectedLocales.isNotEmpty && state.packageName.trim().isNotEmpty)
              ? () => cubit.startUpload(widget.localeScreenshots)
              : null,
          icon: Symbols.cloud_upload,
          label: selectedLocales.isEmpty
              ? context.l10n.selectLocalesToUpload
              : context.l10n.uploadNLocales(selectedLocales.length),
          isExpanded: true,
        ),
      ],
    );
  }
}

class _LocaleCheckTile extends StatelessWidget {
  final String locale;
  final int fileCount;
  final bool isSelected;
  final VoidCallback onChanged;

  const _LocaleCheckTile({
    required this.locale,
    required this.fileCount,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onChanged(),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                locale.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Symbols.arrow_right_alt_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.4)
                    : theme.colorScheme.surfaceContainer.withValues(
                        alpha: 0.4,
                      ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.secondary.withValues(alpha: 0.2)
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                PlayUploadService.toPlayLocale(locale),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '$fileCount ${context.l10n.nFiles(fileCount)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress View ────────────────────────────────────────────────────

class _ProgressView extends StatelessWidget {
  final AscUploadProgress? progress;

  const _ProgressView({this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = progress;
    final fraction = p?.fraction ?? 0;
    final localeStatuses = p?.localeStatuses ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: p != null ? fraction : null,
                    strokeWidth: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (p != null)
                  Text(
                    '${(fraction * 100).toInt()}%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (p != null) ...[
            Text(
              context.l10n.uploadingLocale(p.locale),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.nOfTotalScreenshots(p.current, p.total),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.primary,
              ),
            ),
          ] else
            Text(
              context.l10n.preparingUpload,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (localeStatuses.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: localeStatuses.entries
                    .map(
                      (e) => _LocaleStatusRow(
                        locale: e.key,
                        status: e.value,
                        theme: theme,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocaleStatusRow extends StatelessWidget {
  final String locale;
  final LocaleUploadStatus status;
  final ThemeData theme;

  const _LocaleStatusRow({
    required this.locale,
    required this.status,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          _statusIcon(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              locale.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _statusLabel(context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _statusColor(),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon() {
    switch (status) {
      case LocaleUploadStatus.pending:
        return Icon(
          Symbols.circle,
          size: 14,
          color: theme.colorScheme.outlineVariant,
        );
      case LocaleUploadStatus.uploading:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        );
      case LocaleUploadStatus.done:
        return Icon(
          Symbols.check_circle,
          size: 14,
          color: theme.colorScheme.primary,
        );
      case LocaleUploadStatus.failed:
        return Icon(Symbols.cancel, size: 14, color: theme.colorScheme.error);
    }
  }

  String _statusLabel(BuildContext context) {
    switch (status) {
      case LocaleUploadStatus.pending:
        return context.l10n.statusPending;
      case LocaleUploadStatus.uploading:
        return context.l10n.statusUploading;
      case LocaleUploadStatus.done:
        return context.l10n.statusDone;
      case LocaleUploadStatus.failed:
        return context.l10n.statusFailed;
    }
  }

  Color _statusColor() {
    switch (status) {
      case LocaleUploadStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
      case LocaleUploadStatus.uploading:
      case LocaleUploadStatus.done:
        return theme.colorScheme.primary;
      case LocaleUploadStatus.failed:
        return theme.colorScheme.error;
    }
  }
}

// ─── Done View ────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  final AscUploadResult result;
  final VoidCallback onClose;

  const _DoneView({required this.result, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasErrors = result.failureCount > 0;
    final allFailed = result.successCount == 0 && result.failureCount > 0;

    final iconData = allFailed
        ? Symbols.error
        : hasErrors
        ? Symbols.warning
        : Symbols.check_circle;
    final iconColor = allFailed
        ? theme.colorScheme.error
        : hasErrors
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;
    final bgColor = allFailed
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
        : hasErrors
        ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(iconData, size: 28, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            allFailed
                ? context.l10n.uploadFailed
                : hasErrors
                ? context.l10n.completedWithIssues
                : context.l10n.uploadComplete,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (result.localeResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: result.localeResults.values
                    .map((lr) => _LocaleResultRow(localeResult: lr, theme: theme))
                    .toList(),
              ),
            ),
          ],
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Text(
                  result.errors.join('\n'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppButton.primary(
            onPressed: onClose,
            label: context.l10n.statusDone,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}

class _LocaleResultRow extends StatelessWidget {
  final LocaleResult localeResult;
  final ThemeData theme;

  const _LocaleResultRow({required this.localeResult, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isSuccess = localeResult.isSuccess;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isSuccess ? Symbols.check_circle : Symbols.cancel,
            size: 14,
            color: isSuccess ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              localeResult.locale.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          if (localeResult.successCount > 0)
            Text(
              '${localeResult.successCount} ✓',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (localeResult.failureCount > 0) ...[
            if (localeResult.successCount > 0) const SizedBox(width: 8),
            Text(
              '${localeResult.failureCount} ✗',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Symbols.error, size: 28, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.somethingWentWrong,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          AppButton.outlined(
            onPressed: onRetry,
            icon: Symbols.refresh,
            label: context.l10n.retry,
          ),
        ],
      ),
    );
  }
}
