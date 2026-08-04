/// Represents a Google Play Custom Store Listing (CSL).
class PlayCustomStoreListing {
  final String id;
  final String title;
  final List<String> languageList;

  const PlayCustomStoreListing({
    required this.id,
    required this.title,
    this.languageList = const [],
  });

  factory PlayCustomStoreListing.fromJson(Map<String, dynamic> json) {
    return PlayCustomStoreListing(
      id: json['id'] as String? ?? json['customStoreListingId'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? json['id'] as String? ?? '',
      languageList: (json['languageList'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'languageList': languageList,
      };

  @override
  String toString() => '$title ($id)';
}
