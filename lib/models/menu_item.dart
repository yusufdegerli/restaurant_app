import 'package:hive/hive.dart';

part 'menu_item.g.dart';

@HiveType(typeId: 1)
class MenuItem {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String groupCode;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final bool singleSelection;

  @HiveField(6)
  final bool multipleSelection;

  @HiveField(7)
  final bool hasVariants;

  @HiveField(8)
  final List<String> variants;

  @HiveField(9)
  final List<String> categories;

  MenuItem({
    required this.id,
    required this.name,
    required this.groupCode,
    required this.price,
    required this.category,
    this.singleSelection = false,
    this.multipleSelection = false,
    this.hasVariants = false,
    this.variants = const [],
    this.categories = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    try {
      final id = (json['id'] ?? json['Id']) as int? ?? 0;
      final name = (json['name'] ?? json['Name']) as String? ?? '';
      final groupCode = (json['groupCode'] ?? json['GroupCode']) as String? ?? '';
      final price = ((json['price'] ?? json['Price']) as num?)?.toDouble() ?? 0.0;
      final category = (json['category'] ?? json['Category']) as String? ?? '';
      final categories = (json['categories'] as List<dynamic>?)?.cast<String>() ?? [groupCode];
      return MenuItem(
        id: id,
        name: name,
        groupCode: groupCode,
        price: price,
        category: category,
        categories: categories,
      );
    } catch (e, stackTrace) {
      // Hata logunu sadeleştir ve tekrar fırlat
      print('MenuItem.fromJson Hatası: $e\nStackTrace: $stackTrace\nJSON: $json');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
