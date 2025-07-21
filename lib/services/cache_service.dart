import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sambapos_app_restorant/models/menu_item.dart';
import 'package:sambapos_app_restorant/models/table.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String menuBox = 'menuItems';
  static const String tableBox = 'tables';
  static const String infoBox = 'cacheInfo';

  Future<void> cacheMenuItems(List<MenuItem> items) async {
    final box = Hive.box<MenuItem>(menuBox);
    await box.clear();
    for (var item in items) {
      await box.put(item.id.toString(), item);
    }
    await setCacheTimestamp(menuBox);
  }

  List<MenuItem> getMenuItems() {
    final box = Hive.box<MenuItem>(menuBox);
    return box.values.toList();
  }

  bool hasMenuItems() {
    final box = Hive.box<MenuItem>(menuBox);
    return box.isNotEmpty;
  }

  Future<void> cacheTables(List<RestaurantTable> tables) async {
    final box = Hive.box<RestaurantTable>(tableBox);
    await box.clear();
    for (var table in tables) {
      await box.put(table.id.toString(), table);
    }
    await setCacheTimestamp(tableBox);
  }

  List<RestaurantTable> getTables() {
    final box = Hive.box<RestaurantTable>(tableBox);
    return box.values.toList();
  }

  bool hasTables() {
    final box = Hive.box<RestaurantTable>(tableBox);
    return box.isNotEmpty;
  }

  Future<void> clearCache() async {
    await Hive.box<MenuItem>(menuBox).clear();
    await Hive.box<RestaurantTable>(tableBox).clear();
  }

  Future<void> setCacheTimestamp(String boxName) async {
    final box = Hive.box(infoBox);
    await box.put('lastUpdated_$boxName', DateTime.now().millisecondsSinceEpoch);
  }

  DateTime? getLastCacheUpdate(String boxName) {
    final box = Hive.box(infoBox);
    final timestamp = box.get('lastUpdated_$boxName');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  bool isCacheStale(String boxName, {Duration threshold = const Duration(hours: 1)}) {
    final lastUpdate = getLastCacheUpdate(boxName);
    if (lastUpdate == null) return true;
    final now = DateTime.now();
    return now.difference(lastUpdate) > threshold;
  }

  MenuItem? getMenuItemById(int id) {
    final box = Hive.box<MenuItem>(menuBox);
    return box.get(id.toString());
  }

  RestaurantTable? getTableById(int id) {
    final box = Hive.box<RestaurantTable>(tableBox);
    return box.get(id.toString());
  }

  RestaurantTable? getTableByName(String name) {
    final box = Hive.box<RestaurantTable>(tableBox);
    final tables = box.values.toList();
    try {
      return tables.firstWhere((table) => table.name == name);
    } catch (e) {
      return null;
    }
  }

  Future<void> moveTicket(int oldTableId, int newTableId, int ticketId) async {
    final box = Hive.box<RestaurantTable>(tableBox);
    try {
      final oldTable = getTableById(oldTableId);
      if (oldTable != null) {
        await box.put(
          oldTableId.toString(),
          RestaurantTable(
            id: oldTable.id,
            name: oldTable.name,
            order: oldTable.order,
            category: oldTable.category,
            ticketId: 0,
          ),
        );
      } else {
        throw Exception('Eski masa bulunamadı');
      }
      final newTable = getTableById(newTableId);
      if (newTable != null) {
        await box.put(
          newTableId.toString(),
          RestaurantTable(
            id: newTable.id,
            name: newTable.name,
            order: newTable.order,
            category: newTable.category,
            ticketId: ticketId,
          ),
        );
      } else {
        throw Exception('Yeni masa bulunamadı');
      }
      final requestBody = {
        'oldTableId': oldTableId,
        'newTableId': newTableId,
        'ticketId': ticketId,
      };
      final response = await http.put(
        Uri.parse('http://192.168.56.1:5235/api/table/moveTicket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode != 200) {
        throw Exception('API isteği başarısız: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
