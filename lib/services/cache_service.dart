import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sambapos_app_restorant/models/menu_item.dart';
import 'package:sambapos_app_restorant/models/table.dart';

class CacheService {
  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Sabit değerler
  static const String menuBox = 'menuItems';
  static const String tableBox = 'tables';
  static const String infoBox = 'cacheInfo';

  // Menü öğelerini önbelleğe al
  Future<void> cacheMenuItems(List<MenuItem> items) async {
    final box = Hive.box<MenuItem>(menuBox);
    await box.clear(); // Eski verileri temizle

    for (var item in items) {
      await box.put(item.id.toString(), item);
    }

    // Son güncellenme zamanını kaydet
    await setCacheTimestamp(menuBox);
    //print("✅ ${items.length} menü öğesi önbelleğe alındı");
  }

  // Menü öğelerini önbellekten getir
  List<MenuItem> getMenuItems() {
    final box = Hive.box<MenuItem>(menuBox);
    return box.values.toList();
  }

  // Menü öğeleri önbellekte var mı kontrol et
  bool hasMenuItems() {
    final box = Hive.box<MenuItem>(menuBox);
    return box.isNotEmpty;
  }

  // Masaları önbelleğe al
  Future<void> cacheTables(List<RestaurantTable> tables) async {
    final box = Hive.box<RestaurantTable>(tableBox);
    await box.clear(); // Eski verileri temizle

    for (var table in tables) {
      // ticketId'yi logla
      print(
        "Önbelleğe alınan masa: ID=${table.id}, TicketId=${table.ticketId}",
      );
      await box.put(table.id.toString(), table);
    }

    // Son güncellenme zamanını kaydet
    await setCacheTimestamp(tableBox);
    print("✅ ${tables.length} masa önbelleğe alındı");
  }

  // Masaları önbellekten getir
  List<RestaurantTable> getTables() {
    final box = Hive.box<RestaurantTable>(tableBox);
    return box.values.toList();
  }

  // Masalar önbellekte var mı kontrol et
  bool hasTables() {
    final box = Hive.box<RestaurantTable>(tableBox);
    return box.isNotEmpty;
  }

  // Önbelleği temizle (örn. oturum kapatıldığında)
  Future<void> clearCache() async {
    await Hive.box<MenuItem>(menuBox).clear();
    await Hive.box<RestaurantTable>(tableBox).clear();
    print("🗑️ Önbellek temizlendi");
  }

  // Önbelleğin son güncellenme zamanını kaydet
  Future<void> setCacheTimestamp(String boxName) async {
    final box = Hive.box(infoBox);
    await box.put(
      'lastUpdated_$boxName',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Önbelleğin son güncellenme zamanını al
  DateTime? getLastCacheUpdate(String boxName) {
    final box = Hive.box(infoBox);
    final timestamp = box.get('lastUpdated_$boxName');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // Önbellek eski mi kontrol et (örn. 1 saatten eski ise)
  bool isCacheStale(
    String boxName, {
    Duration threshold = const Duration(hours: 1),
  }) {
    final lastUpdate = getLastCacheUpdate(boxName);
    if (lastUpdate == null) return true;

    final now = DateTime.now();
    return now.difference(lastUpdate) > threshold;
  }

  // ID'ye göre menü öğesi getir
  MenuItem? getMenuItemById(int id) {
    final box = Hive.box<MenuItem>(menuBox);
    return box.get(id.toString());
  }

  // ID'ye göre masa getir
  RestaurantTable? getTableById(int id) {
    final box = Hive.box<RestaurantTable>(tableBox);
    final table = box.get(id.toString());
    if (table != null) {
      if (table.ticketId == 0) {
        print('Uyarı: ID=$id için TicketId 0: ${table.ticketId}');
      } else {
        print('Masa alındı: ID=$id, TicketId=${table.ticketId}');
      }
    }
    return table;
  }

  // İsime göre masa getir
  RestaurantTable? getTableByName(String name) {
    final box = Hive.box<RestaurantTable>(tableBox);
    final tables = box.values.toList();
    try {
      final table = tables.firstWhere((table) => table.name == name);
      if (table.ticketId == 0) {
        print('Uyarı: Name=$name için TicketId 0: ${table.ticketId}');
      } else {
        print('Masa alındı: Name=$name, TicketId=${table.ticketId}');
      }
      return table;
    } catch (e) {
      return null;
    }
  }

  // Fiş taşıma işlemini gerçekleştir
  Future<void> moveTicket(int oldTableId, int newTableId, int ticketId) async {
    final box = Hive.box<RestaurantTable>(tableBox);

    try {
      // İşlem öncesi değerleri logla (hata ayıklama için)
      print(
        'Fiş taşıma başlatılıyor: oldTableId=$oldTableId, newTableId=$newTableId, ticketId=$ticketId',
      );

      // Eski masanın TicketId'sini 0 yap
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
        print('Hive: Eski masa TicketId=0 yapıldı (ID: $oldTableId)');
      } else {
        print('Hata: Eski masa bulunamadı (ID: $oldTableId)');
        throw Exception('Eski masa bulunamadı');
      }

      // Yeni masanın TicketId'sini güncelle
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
        print(
          'Hive: Yeni masa TicketId=$ticketId olarak güncellendi (ID: $newTableId)',
        );
      } else {
        print('Hata: Yeni masa bulunamadı (ID: $newTableId)');
        throw Exception('Yeni masa bulunamadı');
      }

      // API isteği için JSON verisini hazırla
      final requestBody = {
        'oldTableId': oldTableId,
        'newTableId': newTableId,
        'ticketId': ticketId,
      };

      print('API isteği gönderiliyor: ${jsonEncode(requestBody)}');

      // API'ye istek gönder
      final response = await http.put(
        Uri.parse('http://192.168.56.1:5235/api/table/moveTicket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('API yanıtı alındı: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('API isteği başarısız: ${response.body}');
      }
      print('API: Fiş taşıma başarılı');
    } catch (e) {
      print('Hata: $e');
      rethrow;
    }
  }
}
