import 'package:app_screenshots/features/screenshot_editor/data/asc_api/asc_client.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_app.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_app_info.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_app_info_localization.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_build.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_screenshot.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_screenshot_set.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_version.dart';
import 'package:app_screenshots/features/screenshot_editor/data/asc_api/models/asc_version_localization.dart';

abstract class Model {
  final String _type;
  final String id;

  Model(this._type, this.id);

  factory Model._fromJson(
    String type,
    String id,
    AppStoreConnectClient client,
    Map<String, dynamic> attributes,
    Map<String, dynamic> relations,
  ) {
    switch (type) {
      case AppStoreVersion.type:
        return AppStoreVersion(id, client, attributes, relations);
      case App.type:
        return App(id, attributes, relations);
      case Build.type:
        return Build(id, attributes);
      case AppInfoModel.type:
        return AppInfoModel(id, attributes, relations);
      case AppInfoLocalization.type:
        return AppInfoLocalization(id, attributes);
      case VersionLocalization.type:
        return VersionLocalization(id, client, attributes);
      case AppScreenshotSet.type:
        return AppScreenshotSet(id, client, attributes, relations);
      case AppScreenshot.type:
        return AppScreenshot(id, client, attributes);
      default:
        throw Exception('Type $type is not supported yet');
    }
  }
}

abstract class CallableModel extends Model {
  final AppStoreConnectClient client;

  CallableModel(super.type, super.id, this.client);
}

abstract class ModelAttributes {
  Map<String, dynamic> toMap();
}

abstract class ModelRelationship {
  dynamic toJson();
}

class SingleModelRelationship extends ModelRelationship {
  final String type;
  final String id;

  SingleModelRelationship({required this.type, required this.id});

  @override
  toJson() {
    return {'type': type, 'id': id};
  }
}

class MultiModelRelationship extends ModelRelationship {
  final List<SingleModelRelationship> relationships;

  MultiModelRelationship(this.relationships);

  @override
  toJson() {
    return relationships.map((e) => e.toJson()).toList();
  }
}

class ModelParser {
  static List<T> parseList<T extends Model>(
    AppStoreConnectClient client,
    Map<String, dynamic> envelope,
  ) {
    final includedModels = _parseIncludes(client, envelope);

    final Iterable<Model> modelList;
    final dataValue = envelope['data'];
    if (dataValue is Map) {
      modelList = dataValue.values.map(
        (value) => _parseModel(client, value, includedModels),
      );
    } else if (dataValue is List) {
      modelList = dataValue.map(
        (value) => _parseModel(client, value, includedModels),
      );
    } else {
      throw Error();
    }

    return modelList.toList().cast<T>();
  }

  static T parse<T extends Model>(
    AppStoreConnectClient client,
    Map<String, dynamic> envelope,
  ) {
    final includedModels = _parseIncludes(client, envelope);
    final data = envelope['data'] as Map<String, dynamic>;
    return _parseModel(client, data, includedModels) as T;
  }

  static Map<String, Map<String, Model>> _parseIncludes(
    AppStoreConnectClient client,
    Map<String, dynamic> envelope,
  ) {
    final includedModels = <String, Map<String, Model>>{};
    if (envelope.containsKey('included')) {
      final includedData = envelope['included'].cast<Map<String, dynamic>>();
      for (final data in includedData) {
        final model = _parseModel(client, data, includedModels);
        includedModels.putIfAbsent(model._type, () => {})[model.id] = model;
      }
    }

    return includedModels;
  }

  static Model _parseModel(
    AppStoreConnectClient client,
    Map<String, dynamic> data,
    Map<String, Map<String, Model>> includes,
  ) {
    final type = data['type'] as String;
    final id = data['id'] as String;
    final attributes =
        data['attributes'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final relations = data.containsKey('relationships')
        ? _parseRelations(
            data['relationships'] as Map<String, dynamic>,
            includes,
          )
        : <String, dynamic>{};

    return Model._fromJson(type, id, client, attributes, relations);
  }

  static Map<String, dynamic> _parseRelations(
    Map<String, dynamic> data,
    Map<String, Map<String, Model>> includes,
  ) {
    final relations = <String, dynamic>{};
    for (final entry in data.entries) {
      final relationName = entry.key;
      final relationShip = entry.value as Map<String, dynamic>;
      final relationShipData = relationShip['data'];
      if (relationShipData != null) {
        if (relationShipData is List) {
          for (final element in relationShipData) {
            final relatedType = element['type'] as String;
            final relatedId = element['id'] as String;
            if (includes[relatedType]?[relatedId] != null) {
              relations
                  .putIfAbsent(relationName, () => [])
                  .add(includes[relatedType]![relatedId]!);
            }
          }
        } else {
          final relatedType = relationShipData['type'] as String;
          final relatedId = relationShipData['id'] as String;
          if (includes[relatedType]?[relatedId] != null) {
            relations[relationName] = includes[relatedType]![relatedId]!;
          }
        }
      }
    }

    return relations;
  }
}
