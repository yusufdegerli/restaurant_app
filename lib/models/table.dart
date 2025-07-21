import 'package:hive/hive.dart';

part 'table.g.dart';

@HiveType(typeId: 2)
class RestaurantTable {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int order;

  @HiveField(3)
  final String category;

  @HiveField(4)
  int ticketId;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.order,
    required this.category,
    required this.ticketId,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No Name',
      order: json['order'] ?? 0,
      category: json['category'] ?? 'General',
      ticketId: (json['ticketId'] is int) ? json['ticketId'] : 0,
    );
  }
}
