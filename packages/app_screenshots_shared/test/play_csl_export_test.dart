import 'dart:io';

import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late Directory source;
  late String out;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('csl_export_test_');
    source = Directory('${temp.path}/src')..createSync(recursive: true);
    out = '${temp.path}/out';
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  /// Creates [count] placeholder screenshots under `src/<locale>/`.
  List<File> seed(String locale, int count, {String extension = 'png'}) {
    final dir = Directory('${source.path}/$locale')..createSync(recursive: true);
    return [
      for (var i = 1; i <= count; i++)
        File('${dir.path}/shot_${i.toString().padLeft(2, '0')}.$extension')
          ..writeAsStringSync('$locale-$i'),
    ];
  }

  test('writes a listing/locale/imageType tree with ordered files', () async {
    final result = await PlayCslExporter().export(
      outputDirectory: out,
      packageName: 'com.example.app',
      listings: [
        PlayCslListing.singleType(
          name: 'Fitness keyword',
          imageType: 'phoneScreenshots',
          localeScreenshots: {'en': seed('en', 2), 'de': seed('de', 1)},
        ),
      ],
    );

    expect(result.fileCount, 3);
    expect(result.listings.single.slug, 'fitness-keyword');

    // Locales are mapped to Google Play's codes, not the app's.
    expect(
      File('$out/fitness-keyword/en-US/phoneScreenshots/01.png').existsSync(),
      isTrue,
    );
    expect(
      File('$out/fitness-keyword/en-US/phoneScreenshots/02.png').existsSync(),
      isTrue,
    );
    expect(
      File('$out/fitness-keyword/de-DE/phoneScreenshots/01.png').existsSync(),
      isTrue,
    );

    // Files are renumbered in display order, contents preserved.
    expect(
      File('$out/fitness-keyword/en-US/phoneScreenshots/01.png')
          .readAsStringSync(),
      'en-1',
    );
  });

  test('caps each image type at the Play per-locale limit and warns', () async {
    final result = await PlayCslExporter().export(
      outputDirectory: out,
      listings: [
        PlayCslListing.singleType(
          name: 'Overflow',
          imageType: 'phoneScreenshots',
          localeScreenshots: {'en': seed('en', kPlayMaxScreenshotsPerType + 3)},
        ),
      ],
    );

    expect(result.fileCount, kPlayMaxScreenshotsPerType);
    expect(result.warnings.single, contains('skipped 3'));
    expect(
      Directory('$out/overflow/en-US/phoneScreenshots').listSync().length,
      kPlayMaxScreenshotsPerType,
    );
  });

  test('keeps several image types side by side under one locale', () async {
    final result = await PlayCslExporter().export(
      outputDirectory: out,
      listings: [
        PlayCslListing(
          name: 'Tablet push',
          assets: {
            'phoneScreenshots': {'en': seed('en', 1)},
            'tenInchScreenshots': {'en': seed('en-tablet', 2)},
          },
        ),
      ],
    );

    expect(result.fileCount, 3);
    expect(
      File('$out/tablet-push/en-US/phoneScreenshots/01.png').existsSync(),
      isTrue,
    );
    expect(
      File('$out/tablet-push/en-US/tenInchScreenshots/02.png').existsSync(),
      isTrue,
    );
    // Both types are reported under the one locale folder.
    expect(result.listings.single.locales.single.filesByImageType, {
      'phoneScreenshots': 1,
      'tenInchScreenshots': 2,
    });
  });

  test('preserves jpg extensions', () async {
    await PlayCslExporter().export(
      outputDirectory: out,
      listings: [
        PlayCslListing.singleType(
          name: 'Jpeg',
          imageType: 'phoneScreenshots',
          localeScreenshots: {'en': seed('en', 1, extension: 'jpg')},
        ),
      ],
    );

    expect(
      File('$out/jpeg/en-US/phoneScreenshots/01.jpg').existsSync(),
      isTrue,
    );
  });

  test('disambiguates listings that slugify to the same folder', () async {
    final result = await PlayCslExporter().export(
      outputDirectory: out,
      listings: [
        PlayCslListing.singleType(
          name: 'Winter sale',
          imageType: 'phoneScreenshots',
          localeScreenshots: {'en': seed('en', 1)},
        ),
        PlayCslListing.singleType(
          name: 'Winter  Sale!',
          imageType: 'phoneScreenshots',
          localeScreenshots: {'de': seed('de', 1)},
        ),
      ],
    );

    expect(
      result.listings.map((l) => l.slug),
      ['winter-sale', 'winter-sale-2'],
    );
  });

  test('clean removes screenshots dropped since the last export', () async {
    Future<void> run(int count) => PlayCslExporter().export(
      outputDirectory: out,
      listings: [
        PlayCslListing.singleType(
          name: 'Repeat',
          imageType: 'phoneScreenshots',
          localeScreenshots: {'en': seed('en', count)},
        ),
      ],
    );

    await run(3);
    Directory('${source.path}/en').deleteSync(recursive: true);
    await run(1);

    expect(
      Directory('$out/repeat/en-US/phoneScreenshots').listSync().length,
      1,
    );
  });

  test('generates instructions naming the folders and the URL parameter',
      () async {
    final result = await PlayCslExporter().export(
      outputDirectory: out,
      packageName: 'com.example.app',
      listings: [
        PlayCslListing.singleType(
          name: 'Fitness keyword',
          targetingNote: 'Search keyword: "workout tracker"',
          imageType: 'phoneScreenshots',
          localeScreenshots: {'en': seed('en', 1)},
        ),
      ],
    );

    final markdown = File(result.instructionsPath).readAsStringSync();
    expect(markdown, contains('fitness-keyword'));
    expect(markdown, contains('Search keyword: "workout tracker"'));
    expect(
      markdown,
      contains(
        'https://play.google.com/store/apps/details'
        '?id=com.example.app&listing=fitness-keyword',
      ),
    );
    // The caveat that most often explains a "broken" custom listing.
    expect(markdown, contains('No automatic translation'));
  });

  test('rejects an empty listing set', () async {
    expect(
      () => PlayCslExporter().export(outputDirectory: out, listings: []),
      throwsArgumentError,
    );
  });

  group('slugify', () {
    test('produces a valid Play listing URL parameter', () {
      expect(PlayCslExporter.slugify('Winter Sale 2026!'), 'winter-sale-2026');
      expect(PlayCslExporter.slugify('  spaced  out  '), 'spaced-out');
      expect(PlayCslExporter.slugify('keep.dots_and~tildes'),
          'keep.dots_and~tildes');
      expect(PlayCslExporter.slugify('!!!'), 'listing');
    });
  });
}
