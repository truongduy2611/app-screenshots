import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_client.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_model.dart';

/// Delivery state of an asset after upload commit.
class AssetDeliveryState {
  final String state;
  final List<AssetDeliveryError> errors;

  const AssetDeliveryState({required this.state, this.errors = const []});

  factory AssetDeliveryState.fromMap(Map<String, dynamic> map) {
    return AssetDeliveryState(
      state: (map['state'] as String?) ?? '',
      errors:
          (map['errors'] as List<dynamic>?)
              ?.map(
                (e) => AssetDeliveryError.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  bool get isComplete => state.toUpperCase() == 'COMPLETE';
  bool get isFailed => state.toUpperCase() == 'FAILED';

  String get errorSummary {
    if (errors.isEmpty) return 'unknown error';
    return errors
        .map((e) {
          if (e.code.isNotEmpty && e.message.isNotEmpty) {
            return '${e.code}: ${e.message}';
          }
          return e.message.isNotEmpty ? e.message : e.code;
        })
        .where((s) => s.isNotEmpty)
        .join('; ');
  }
}

class AssetDeliveryError {
  final String code;
  final String message;

  const AssetDeliveryError({this.code = '', this.message = ''});

  factory AssetDeliveryError.fromMap(Map<String, dynamic> map) {
    return AssetDeliveryError(
      code: (map['code'] as String?) ?? '',
      message: (map['message'] as String?) ?? '',
    );
  }
}

class AppScreenshot extends CallableModel {
  static const type = 'appScreenshots';

  final int fileSize;
  final String fileName;
  final String? sourceFileChecksum;
  final Map<String, dynamic>? imageAsset;
  final String? assetToken;
  final String? assetType;
  final List<dynamic>? uploadOperations;
  final AssetDeliveryState? assetDeliveryState;

  AppScreenshot(
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
  ) : fileSize = attributes['fileSize'] ?? 0,
      fileName = attributes['fileName'] ?? '',
      sourceFileChecksum = attributes['sourceFileChecksum'],
      imageAsset = attributes['imageAsset'],
      assetToken = attributes['assetToken'],
      assetType = attributes['assetType'],
      uploadOperations = attributes['uploadOperations'],
      assetDeliveryState = attributes['assetDeliveryState'] != null
          ? AssetDeliveryState.fromMap(
              attributes['assetDeliveryState'] as Map<String, dynamic>,
            )
          : null,
      super(type, id, client);
}

class AppScreenshotAttributes implements ModelAttributes {
  final int? fileSize;
  final String? fileName;
  final String? sourceFileChecksum;
  final bool? uploaded;

  AppScreenshotAttributes({
    this.fileSize,
    this.fileName,
    this.sourceFileChecksum,
    this.uploaded,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      if (fileSize != null) 'fileSize': fileSize,
      if (fileName != null) 'fileName': fileName,
      if (sourceFileChecksum != null) 'sourceFileChecksum': sourceFileChecksum,
      if (uploaded != null) 'uploaded': uploaded,
    };
  }
}

class AppScreenshotCreateAttributes implements ModelAttributes {
  final int fileSize;
  final String fileName;

  AppScreenshotCreateAttributes({
    required this.fileSize,
    required this.fileName,
  });

  @override
  Map<String, dynamic> toMap() {
    return {'fileSize': fileSize, 'fileName': fileName};
  }
}
