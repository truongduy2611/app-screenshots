import 'dart:io';

import 'package:app_screenshots_shared/app_screenshots_shared.dart';
import 'package:args/command_runner.dart';

import '../app_client.dart';
import '../output.dart';
import '../upload_payload.dart';
import 'jobs_command.dart';

class PlayCommand extends Command<int> {
  @override
  String get name => 'play';

  @override
  String get description =>
      'Upload screenshots to the Google Play main listing';

  PlayCommand() {
    addSubcommand(_PlayUploadCommand());
    addSubcommand(_PlayExportCslCommand());
  }
}

class _PlayUploadCommand extends Command<int> {
  @override
  String get name => 'upload';

  @override
  String get description => 'Upload locale folders to Google Play';

  _PlayUploadCommand() {
    argParser
      ..addOption('package', help: 'Android package name', mandatory: true)
      ..addOption(
        'source',
        abbr: 's',
        help: 'Directory containing locale subdirectories',
        mandatory: true,
      )
      ..addOption(
        'image-type',
        help: 'Google Play screenshot image type',
        defaultsTo: 'phoneScreenshots',
        allowed: const [
          'phoneScreenshots',
          'sevenInchScreenshots',
          'tenInchScreenshots',
          'tvScreenshots',
          'wearScreenshots',
        ],
      )
      ..addMultiOption(
        'locale',
        abbr: 'l',
        help: 'Locales to upload; defaults to every locale folder',
        splitCommas: true,
      )
      ..addFlag(
        'delete-existing',
        help: 'Replace existing screenshots',
        defaultsTo: true,
      )
      ..addFlag(
        'draft',
        help: 'Keep changes from being sent for review automatically',
        defaultsTo: true,
      )
      ..addFlag(
        'wait',
        help: 'Wait for the background upload to finish',
        defaultsTo: true,
      );
  }

  @override
  Future<int> run() async {
    final client = await AppClient.discover(
      portOverride: globalResults?['port'] as String?,
    );
    final locales = argResults!['locale'] as List<String>;
    final screenshots = await encodeLocaleScreenshots(
      argResults!['source'] as String,
      selectedLocales: locales,
    );
    if (screenshots.isEmpty) {
      Output.print({
        'ok': false,
        'error': 'No screenshots found in the selected locale folders',
      }, json: Output.isJson(globalResults));
      client.close();
      return 1;
    }
    final body = <String, dynamic>{
      'packageName': argResults!['package'],
      'screenshots': screenshots,
      'imageType': argResults!['image-type'],
      'deleteExisting': argResults!['delete-existing'],
      'changesNotSentForReview': argResults!['draft'],
      if (locales.isNotEmpty) 'locales': locales,
    };
    var result = await client.post(
      PlayAction.upload.path,
      body,
      const Duration(minutes: 5),
    );
    if (argResults!['wait'] == true) result = await waitForJob(client, result);
    Output.print(result, json: Output.isJson(globalResults));
    client.close();
    return result['ok'] == true ? 0 : 1;
  }
}

/// Lays screenshots out for a manual custom store listing upload.
///
/// Google Play has no custom store listing API — `edits.listings` and
/// `edits.images` only address the main listing — so this command does not
/// talk to Google or to the running app. It restructures files on disk and
/// writes an `UPLOAD.md` that maps each folder to a Play Console field.
class _PlayExportCslCommand extends Command<int> {
  @override
  String get name => 'export-csl';

  @override
  String get description =>
      'Export locale folders as a custom store listing upload kit';

  @override
  String get invocation =>
      'appshots play export-csl --listing <name>[=<dir>] --out <dir>';

  _PlayExportCslCommand() {
    argParser
      ..addMultiOption(
        'listing',
        abbr: 'L',
        help:
            'Custom store listing to export, as "name" or "name=sourceDir". '
            'Repeat for several listings. Without "=dir" the listing uses '
            '--source.',
        splitCommas: false,
      )
      ..addOption(
        'out',
        abbr: 'o',
        help: 'Directory to write the upload kit into',
        mandatory: true,
      )
      ..addOption(
        'source',
        abbr: 's',
        help:
            'Default directory of locale subdirectories, used by listings '
            'given without "=dir"',
      )
      ..addOption(
        'image-type',
        help: 'Google Play screenshot image type',
        defaultsTo: 'phoneScreenshots',
        allowed: kPlayImageTypes.keys.toList(),
      )
      ..addOption(
        'package',
        help: 'Android package name, used for the example listing URLs',
      )
      ..addMultiOption(
        'locale',
        abbr: 'l',
        help: 'Locales to export; defaults to every locale folder',
        splitCommas: true,
      )
      ..addFlag(
        'clean',
        help: "Delete each listing's existing folder before writing",
        defaultsTo: true,
      );
  }

  @override
  Future<int> run() async {
    final json = Output.isJson(globalResults);
    final specs = argResults!['listing'] as List<String>;
    if (specs.isEmpty) {
      Output.print({
        'ok': false,
        'error': 'Provide at least one --listing.',
      }, json: json);
      return 1;
    }

    final defaultSource = argResults!['source'] as String?;
    final locales = argResults!['locale'] as List<String>;
    final imageType = argResults!['image-type'] as String;

    final listings = <PlayCslListing>[];
    for (final spec in specs) {
      final separator = spec.indexOf('=');
      final listingName = (separator == -1 ? spec : spec.substring(0, separator))
          .trim();
      final source = separator == -1
          ? defaultSource
          : spec.substring(separator + 1).trim();

      if (listingName.isEmpty) {
        Output.print({
          'ok': false,
          'error': 'Listing name is empty in "--listing $spec".',
        }, json: json);
        return 1;
      }
      if (source == null || source.isEmpty) {
        Output.print({
          'ok': false,
          'error':
              'No source directory for listing "$listingName". Pass '
              '--source, or use --listing "$listingName=<dir>".',
        }, json: json);
        return 1;
      }

      final Map<String, List<File>> screenshots;
      try {
        screenshots = await readLocaleScreenshots(
          source,
          selectedLocales: locales,
        );
      } on ArgumentError catch (e) {
        Output.print({'ok': false, 'error': e.message}, json: json);
        return 1;
      }
      if (screenshots.isEmpty) {
        Output.print({
          'ok': false,
          'error':
              'No screenshots found for listing "$listingName" in $source.',
        }, json: json);
        return 1;
      }

      listings.add(
        PlayCslListing.singleType(
          name: listingName,
          imageType: imageType,
          localeScreenshots: screenshots,
        ),
      );
    }

    final result = await PlayCslExporter().export(
      outputDirectory: argResults!['out'] as String,
      listings: listings,
      packageName: argResults!['package'] as String?,
      clean: argResults!['clean'] as bool,
    );

    Output.print({
      'ok': true,
      'outputDirectory': result.outputDirectory,
      'instructions': result.instructionsPath,
      'fileCount': result.fileCount,
      'listings': [
        for (final listing in result.listings)
          {
            'name': listing.name,
            'slug': listing.slug,
            'directory': listing.directoryPath,
            'fileCount': listing.fileCount,
            'locales': [
              for (final locale in listing.locales)
                {
                  'playLocale': locale.playLocale,
                  'sourceLocale': locale.sourceLocale,
                  'files': locale.filesByImageType,
                },
            ],
          },
      ],
      'warnings': result.warnings,
      'note':
          'Google Play has no custom store listing API. Follow '
          '${result.instructionsPath} to upload these in Play Console.',
    }, json: json);
    return 0;
  }
}
