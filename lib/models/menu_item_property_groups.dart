class MenuItemPropertyGroup {
  final int id;
  final String name;
  final bool singleSelection; // API'den gelmeli
  final bool multipleSelection; // API'den gelmeli

  MenuItemPropertyGroup({
    required this.id,
    required this.name,
    required this.singleSelection,
    required this.multipleSelection,
  });

  factory MenuItemPropertyGroup.fromJson(Map<String, dynamic> json) {
    return MenuItemPropertyGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      singleSelection:
          json['singleSelection'] ??
          false, // API'de bu alan yoksa varsayılan false
      multipleSelection: json['multipleSelection'] ?? false,
    );
  }
}
