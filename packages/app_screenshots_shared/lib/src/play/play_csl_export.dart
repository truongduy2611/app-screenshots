import 'dart:io';

import 'play_metadata.dart';

/// One custom store listing's worth of screenshots, ready to be laid out on
/// disk for a manual Play Console upload.
class PlayCslListing {
  /// Human-readable listing name, as it will be typed into Play Console.
  final String name;

  /// Optional reminder of how this listing is targeted (country, keyword,
  /// user state, ad group…). Echoed into the generated instructions.
  final String? targetingNote;

  /// Google Play `imageType` → app/translation locale → ordered files.
  final Map<String, Map<String, List<File>>> assets;

  const PlayCslListing({
    required this.name,
    required this.assets,
    this.targetingNote,
  });

  /// Convenience for the common case of exporting a single image type.
  PlayCslListing.singleType({
    required this.name,
    required String imageType,
    required Map<String, List<File>> localeScreenshots,
    this.targetingNote,
  }) : assets = {imageType: localeScreenshots};
}

/// Per-locale outcome inside one exported listing.
class PlayCslLocaleResult {
  /// The locale as Google Play names it (the folder name).
  final String playLocale;

  /// The app/translation locale it came from.
  final String sourceLocale;

  /// Files written, keyed by Google Play `imageType`.
  final Map<String, int> filesByImageType;

  const PlayCslLocaleResult({
    required this.playLocale,
    required this.sourceLocale,
    required this.filesByImageType,
  });

  int get fileCount =>
      filesByImageType.values.fold(0, (sum, count) => sum + count);
}

/// Outcome of exporting one custom store listing.
class PlayCslListingResult {
  final String name;

  /// Slugified [name] — the folder name, and a valid `&listing=` URL
  /// parameter for the custom store listing URL.
  final String slug;

  final String directoryPath;
  final List<PlayCslLocaleResult> locales;
  final List<String> warnings;

  const PlayCslListingResult({
    required this.name,
    required this.slug,
    required this.directoryPath,
    required this.locales,
    required this.warnings,
  });

  int get fileCount =>
      locales.fold(0, (sum, locale) => sum + locale.fileCount);
}

/// Outcome of a full export run.
class PlayCslExportResult {
  final String outputDirectory;

  /// Path of the generated `UPLOAD.md` walkthrough.
  final String instructionsPath;

  final List<PlayCslListingResult> listings;

  const PlayCslExportResult({
    required this.outputDirectory,
    required this.instructionsPath,
    required this.listings,
  });

  int get fileCount =>
      listings.fold(0, (sum, listing) => sum + listing.fileCount);

  List<String> get warnings => [
    for (final listing in listings)
      for (final warning in listing.warnings) '${listing.name}: $warning',
  ];
}

/// Lays screenshots out on disk in a shape that maps 1:1 onto Play Console's
/// custom store listing form.
///
/// The Android Publisher API has no custom store listing surface — `edits`
/// only addresses the default listing, keyed by language and image type — so
/// there is nothing to upload against. This exporter produces the next best
/// thing: a per-listing, per-locale, per-image-type tree plus an `UPLOAD.md`
/// that says which folder goes in which Console field.
///
/// Output structure:
/// ```
/// outputDirectory/
/// ├── UPLOAD.md
/// └── fitness-keyword/
///     ├── en-US/
///     │   └── phoneScreenshots/
///     │       ├── 01.png
///     │       └── 02.png
///     └── de-DE/
///         └── phoneScreenshots/
///             └── 01.png
/// ```
class PlayCslExporter {
  /// Writes [listings] under [outputDirectory] and generates `UPLOAD.md`.
  ///
  /// [packageName] is only used to build the example custom store listing
  /// URLs in the instructions. When [clean] is true each listing's folder is
  /// removed first, so a re-export never leaves stale screenshots behind;
  /// otherwise new image types are added alongside existing ones.
  Future<PlayCslExportResult> export({
    required String outputDirectory,
    required List<PlayCslListing> listings,
    String? packageName,
    bool clean = true,
  }) async {
    if (listings.isEmpty) {
      throw ArgumentError('Export at least one custom store listing.');
    }

    final root = Directory(outputDirectory);
    await root.create(recursive: true);

    final results = <PlayCslListingResult>[];
    final usedSlugs = <String>{};

    for (final listing in listings) {
      final slug = _uniqueSlug(listing.name, usedSlugs);
      usedSlugs.add(slug);

      final listingDir = Directory('${root.path}${Platform.pathSeparator}$slug');
      if (clean && await listingDir.exists()) {
        await listingDir.delete(recursive: true);
      }
      await listingDir.create(recursive: true);

      final warnings = <String>[];

      // Group by locale so each locale folder holds every image type, which
      // is the order the Console form asks for them in.
      final byLocale = <String, Map<String, List<File>>>{};
      for (final typeEntry in listing.assets.entries) {
        for (final localeEntry in typeEntry.value.entries) {
          if (localeEntry.value.isEmpty) continue;
          byLocale
              .putIfAbsent(localeEntry.key, () => <String, List<File>>{})
              .putIfAbsent(typeEntry.key, () => <File>[])
              .addAll(localeEntry.value);
        }
      }

      final localeResults = <PlayCslLocaleResult>[];
      final sourceLocales = byLocale.keys.toList()..sort();

      for (final sourceLocale in sourceLocales) {
        final playLocale = playLocaleFor(sourceLocale);
        final localeDir = Directory(
          '${listingDir.path}${Platform.pathSeparator}$playLocale',
        );
        await localeDir.create(recursive: true);

        final filesByImageType = <String, int>{};
        final imageTypes = byLocale[sourceLocale]!.keys.toList()..sort();

        for (final imageType in imageTypes) {
          final files = byLocale[sourceLocale]![imageType]!;
          final typeDir = Directory(
            '${localeDir.path}${Platform.pathSeparator}$imageType',
          );
          await typeDir.create(recursive: true);

          // Play caps each image type at kPlayMaxScreenshotsPerType per
          // locale; drop the overflow here rather than letting Console
          // reject the upload halfway through.
          final toWrite = files.take(kPlayMaxScreenshotsPerType).toList();
          final skipped = files.length - toWrite.length;
          if (skipped > 0) {
            final label = kPlayImageTypes[imageType] ?? imageType;
            warnings.add(
              '$playLocale — skipped $skipped $label screenshot(s); Google '
              'Play allows at most $kPlayMaxScreenshotsPerType per locale.',
            );
          }

          var index = 1;
          for (final file in toWrite) {
            final extension = _extensionOf(file.path);
            final target = File(
              '${typeDir.path}${Platform.pathSeparator}'
              '${index.toString().padLeft(2, '0')}$extension',
            );
            await file.copy(target.path);
            index++;
          }
          filesByImageType[imageType] = toWrite.length;
        }

        localeResults.add(
          PlayCslLocaleResult(
            playLocale: playLocale,
            sourceLocale: sourceLocale,
            filesByImageType: filesByImageType,
          ),
        );
      }

      results.add(
        PlayCslListingResult(
          name: listing.name,
          slug: slug,
          directoryPath: listingDir.path,
          locales: localeResults,
          warnings: warnings,
        ),
      );
    }

    final instructions = File(
      '${root.path}${Platform.pathSeparator}UPLOAD.md',
    );
    await instructions.writeAsString(
      _buildInstructions(
        listings: listings,
        results: results,
        packageName: packageName,
      ),
    );

    return PlayCslExportResult(
      outputDirectory: root.path,
      instructionsPath: instructions.path,
      listings: results,
    );
  }

  String _buildInstructions({
    required List<PlayCslListing> listings,
    required List<PlayCslListingResult> results,
    String? packageName,
  }) {
    final notesByName = {
      for (final listing in listings) listing.name: listing.targetingNote,
    };
    final pkg = (packageName == null || packageName.isEmpty)
        ? 'com.example.app'
        : packageName;

    final buffer = StringBuffer()
      ..writeln('# Google Play custom store listings — upload guide')
      ..writeln()
      ..writeln(
        'These screenshots could not be uploaded automatically. The Google '
        'Play Android Publisher API has no custom store listing surface — '
        '`edits.listings` and `edits.images` are keyed only by language and '
        'image type, so every API write lands on the **main** store listing. '
        'Custom store listings are Play Console–only, so the steps below are '
        'manual.',
      )
      ..writeln()
      ..writeln('## Folder → Console field')
      ..writeln()
      ..writeln(
        'Each folder maps onto one field of the Console form:',
      )
      ..writeln()
      ..writeln('```')
      ..writeln('<listing>/<locale>/<imageType>/01.png')
      ..writeln('    │         │        └── the "Phone"/"Tablet"/… uploader')
      ..writeln('    │         └── the language picker on the listing page')
      ..writeln('    └── one custom store listing in Play Console')
      ..writeln('```')
      ..writeln()
      ..writeln('| Folder | Play Console uploader |')
      ..writeln('| --- | --- |');
    for (final entry in kPlayImageTypes.entries) {
      buffer.writeln('| `${entry.key}/` | ${entry.value} screenshots |');
    }

    buffer
      ..writeln()
      ..writeln('## Steps')
      ..writeln()
      ..writeln(
        '1. Play Console → your app → **Grow** → **Store presence** → '
        '**Custom store listings**.',
      )
      ..writeln(
        '2. **Create listing** and name it exactly as the folder is named '
        'below, so the two stay easy to match.',
      )
      ..writeln(
        '3. Choose the targeting (country, custom URL, search keyword, user '
        'or buyer state, or a Google Ads AdGroup ID).',
      )
      ..writeln(
        '4. For each language in the listing, open the language and drag the '
        'matching `<locale>/<imageType>/` folder contents into that '
        'uploader. Files are numbered in display order.',
      )
      ..writeln('5. **Save**, then submit for review when the listing is ready.')
      ..writeln()
      ..writeln('## What was exported')
      ..writeln();

    for (final result in results) {
      buffer
        ..writeln('### ${result.name}')
        ..writeln()
        ..writeln('Folder: `${result.slug}/`');
      final note = notesByName[result.name];
      if (note != null && note.trim().isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('Targeting: ${note.trim()}');
      }
      buffer
        ..writeln()
        ..writeln(
          'If you target this listing by URL, `${result.slug}` is a valid '
          'listing parameter:',
        )
        ..writeln()
        ..writeln('```')
        ..writeln(
          'https://play.google.com/store/apps/details'
          '?id=$pkg&listing=${result.slug}',
        )
        ..writeln('```')
        ..writeln()
        ..writeln('| Language | Screenshots |')
        ..writeln('| --- | --- |');
      for (final locale in result.locales) {
        final parts = locale.filesByImageType.entries
            .map((e) => '${kPlayImageTypes[e.key] ?? e.key}: ${e.value}')
            .join(', ');
        buffer.writeln('| `${locale.playLocale}` | $parts |');
      }
      if (result.warnings.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('**Warnings**');
        for (final warning in result.warnings) {
          buffer.writeln('- $warning');
        }
      }
      buffer.writeln();
    }

    buffer
      ..writeln('## Before you publish')
      ..writeln()
      ..writeln(
        '- **No automatic translation.** A language you do not fill in falls '
        'back to the main listing — the most common reason a custom listing '
        'looks like it "is not working".',
      )
      ..writeln(
        '- **One country per listing.** A country can only be claimed by a '
        'single custom store listing at a time.',
      )
      ..writeln(
        '- **Up to $kPlayMaxCustomStoreListings custom store listings** per '
        'app.',
      )
      ..writeln(
        '- **Review required.** Listings go live only after approval, and '
        'performance reporting needs roughly 1,000 visitors over 28 days '
        'before it populates.',
      )
      ..writeln(
        '- **Ads-targeted listings currently serve on AdMob only** — they do '
        'not apply to Google Play search ads.',
      );

    return buffer.toString();
  }

  /// Slugifies a listing name into something usable both as a folder name and
  /// as a Play custom store listing URL parameter (lowercase alphanumerics
  /// plus `.`, `-`, `_`, `~`).
  static String slugify(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._~-]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'listing' : slug;
  }

  String _uniqueSlug(String name, Set<String> taken) {
    final base = slugify(name);
    if (!taken.contains(base)) return base;
    var suffix = 2;
    while (taken.contains('$base-$suffix')) {
      suffix++;
    }
    return '$base-$suffix';
  }

  static String _extensionOf(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg')) return '.jpg';
    if (lower.endsWith('.jpeg')) return '.jpeg';
    return '.png';
  }
}
