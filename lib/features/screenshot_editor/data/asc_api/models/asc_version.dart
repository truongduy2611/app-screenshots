import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_client.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_platform.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_version_localization.dart';

class AppStoreVersion extends CallableModel {
  static const type = 'appStoreVersions';

  final AppStoreVersionAttributes _attributes;
  final Map<String, dynamic> _relations;

  AppStoreVersion(
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
    this._relations,
  ) : _attributes = AppStoreVersionAttributes._(attributes),
      super(type, id, client);

  String get versionString => _attributes.versionString;
  AppStorePlatform get platform => _attributes.platform;
  AppVersionState get appVersionState => _attributes.appVersionState;

  bool get editable => AppVersionState.editStates.contains(appVersionState);

  List<VersionLocalization> get localizations =>
      _relations['appStoreVersionLocalizations']?.cast<VersionLocalization>() ??
      const [];

  Future<List<VersionLocalization>> getLocalizations() async {
    final request = GetRequest(
      AppStoreConnectUri.v1(
        'appStoreVersions/$id/appStoreVersionLocalizations',
      ),
    );
    final response = await client.get(request);
    return response.asList<VersionLocalization>();
  }

  @override
  String toString() => '$versionString ($appVersionState)';
}

class AppStoreVersionAttributes implements ModelAttributes {
  final Map<String, dynamic> _attributes;

  AppStoreVersionAttributes._(Map<String, dynamic> attributes)
    : _attributes = attributes;

  // Named constructor for public creation
  AppStoreVersionAttributes({AppStorePlatform? platform, String? versionString})
    : _attributes = {
        if (platform != null) 'platform': platform.toString(),
        'versionString': ?versionString,
      };

  String get versionString => _attributes['versionString'] ?? '';
  AppStorePlatform get platform =>
      AppStorePlatform(_attributes['platform'] ?? 'IOS');
  AppVersionState get appVersionState =>
      AppVersionState._(_attributes['appVersionState'] ?? '');

  @override
  Map<String, dynamic> toMap() => _attributes;
}

class AppVersionState {
  static const prepareForSubmission = AppVersionState._(
    'PREPARE_FOR_SUBMISSION',
  );
  static const developerRejected = AppVersionState._('DEVELOPER_REJECTED');
  static const rejected = AppVersionState._('REJECTED');
  static const metadataRejected = AppVersionState._('METADATA_REJECTED');
  static const waitingForReview = AppVersionState._('WAITING_FOR_REVIEW');
  static const readyForReview = AppVersionState._('READY_FOR_REVIEW');
  static const inReview = AppVersionState._('IN_REVIEW');
  static const invalidBinary = AppVersionState._('INVALID_BINARY');
  static const waitingForExportCompliance = AppVersionState._(
    'WAITING_FOR_EXPORT_COMPLIANCE',
  );
  static const accepted = AppVersionState._('ACCEPTED');
  static const readyForDistribution = AppVersionState._(
    'READY_FOR_DISTRIBUTION',
  );

  static const editStates = [
    accepted,
    readyForReview,
    prepareForSubmission,
    developerRejected,
    rejected,
    metadataRejected,
    waitingForReview,
    invalidBinary,
    waitingForExportCompliance,
  ];

  final String _value;
  const AppVersionState._(this._value);

  String get value => _value;

  @override
  int get hashCode => _value.hashCode;
  @override
  bool operator ==(Object other) =>
      other is AppVersionState && other._value == _value;
  @override
  String toString() => _value;
}
