import 'package:equatable/equatable.dart';

class DesignFolder extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? parentId;

  const DesignFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.parentId,
  });

  factory DesignFolder.fromJson(Map<String, dynamic> json) {
    return DesignFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      parentId: json['parentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
    };
  }

  @override
  List<Object> get props => [id, name, createdAt];
}
