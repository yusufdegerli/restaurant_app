import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sambapos_app_restorant/models/menu_item.dart';
import 'package:sambapos_app_restorant/models/table.dart';
import 'package:sambapos_app_restorant/services/api_service.dart';
import 'package:sambapos_app_restorant/services/cache_service.dart';
import 'package:sambapos_app_restorant/services/websocket_service.dart';

class OrderProvider with ChangeNotifier {
  final WebSocketService _webSocketService;
  final CacheService _cacheService;
  Map<String, List<MenuItem>> _orders = {};
  Map<String, DateTime> _orderTimes = {};
  Map<String, String> _orderNotes = {};
  Map<String, String> _orderUserNames = {};
  Map<String, String> _orderUserIds = {};
  List<MenuItem> _selectedItems = [];

  // Menü öğeleri için değişkenler
  List<MenuItem> _menuItems = [];
  bool _isLoadingMenuItems = false;
  String? _menuItemsError;

  // Masalar için değişkenler
  List<RestaurantTable> _tables = [];
  bool _isLoadingTables = false;
  String? _tablesError;

  OrderProvider(this._webSocketService, this._cacheService) {
    // WebSocket mesajlarını dinleme
    _webSocketService.stream.listen(
      (message) {
        _handleWebSocketMessage(message);
      },
      onError: (error) {
        print('WebSocket stream hatası: $error');
      },
      onDone: () {
        print('WebSocket stream kapandı');
      },
    );
    // Başlangıçta siparişleri yükle
    _loadInitialOrders();
  }

  // Getters
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoadingMenuItems => _isLoadingMenuItems;
  String? get menuItemsError => _menuItemsError;

  List<RestaurantTable> get tables => _tables;
  bool get isLoadingTables => _isLoadingTables;
  String? get tablesError => _tablesError;

  void _handleWebSocketMessage(String message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'ticket_updated') {
        final tableId = data['data']['tableId'];
        final ticketId = data['data']['ticketId'];
        final table = _cacheService.getTableById(tableId);

        if (table != null) {
          final tableName = table.name;
          if (ticketId == 0) {
            // Masa boşaldı, siparişi kaldır
            _orders.remove(tableName);
            print('OrderProvider: $tableName için sipariş kaldırıldı');
          } else {
            // Masa doldu, siparişi güncelle
            _fetchOrderFromDatabase(tableName, ticketId);
          }
          notifyListeners();
        }
      }
    } catch (e) {
      print("Websocket işlenirken hata: (_handleWebSocketMessage): $e");
    }
  }

  // ID'ye göre masa ismini almak (CacheService üzerinden)
  String? _getTableNameById(int tableId) {
    final table = _cacheService.getTableById(tableId);
    return table?.name;
  }

  Future<void> _fetchOrderFromDatabase(String tableName, int ticketId) async {
    try {
      final ticketItems = await ApiService.getTicketItemsByTicketId(ticketId);
      if (ticketItems.isNotEmpty) {
        final menuItems = await ApiService.getMenuItems();
        final items =
            ticketItems.map((item) {
              final menuItem = menuItems.firstWhere(
                (menu) => menu.id == item.menuItemId,
                orElse:
                    () => MenuItem(
                      id: item.menuItemId,
                      name: item.menuItemName,
                      groupCode: 'Bilinmiyor',
                      price: item.price,
                      category: 'Genel',
                    ),
              );
              return menuItem;
            }).toList();
        _orders[tableName] = items;
        print('OrderProvider: $tableName için sipariş güncellendi: $items');
        notifyListeners();
      } else {
        // Bilette öğe yoksa siparişi kaldır
        _orders.remove(tableName);
        print('OrderProvider: $tableName için sipariş bulunamadı, kaldırıldı');
        notifyListeners();
      }
    } catch (e) {
      print("Sipariş çekilirken hata oldu (_fetchOrderFromDatabase): $e");
    }
  }

  // Başlangıçta siparişleri yükle
  Future<void> _loadInitialOrders() async {
    try {
      final tables = _cacheService.getTables();
      for (final table in tables) {
        if (table.ticketId != 0) {
          await _fetchOrderFromDatabase(table.name, table.ticketId);
        }
      }
    } catch (e) {
      print('Başlangıç siparişleri yüklenirken hata: $e');
    }
  }

  // Menü öğelerini yükle
  Future<void> loadMenuItems() async {
    if (_isLoadingMenuItems) return;

    _isLoadingMenuItems = true;
    _menuItemsError = null;
    notifyListeners();

    try {
      if (_cacheService.hasMenuItems() &&
          !_cacheService.isCacheStale(CacheService.menuBox)) {
        print("📋 Menü öğeleri önbellekten yükleniyor...");
        _menuItems = _cacheService.getMenuItems();
        _isLoadingMenuItems = false;
        notifyListeners();
        return;
      }

      print("🌐 Menü öğeleri API'den yükleniyor...");
      final items = await ApiService.getMenuItems();
      _menuItems = items;
      await _cacheService.cacheMenuItems(items);

      _isLoadingMenuItems = false;
      notifyListeners();
    } catch (e) {
      print("❌ Menü öğeleri yüklenirken hata: $e");
      _menuItemsError = e.toString();

      if (_cacheService.hasMenuItems()) {
        print("📋 Hata nedeniyle önbellekten yükleniyor...");
        _menuItems = _cacheService.getMenuItems();
      }

      _isLoadingMenuItems = false;
      notifyListeners();
    }
  }

  // Masaları yükle
  Future<void> loadTables() async {
    if (_isLoadingTables) return;

    _isLoadingTables = true;
    _tablesError = null;
    notifyListeners();

    try {
      if (_cacheService.hasTables() &&
          !_cacheService.isCacheStale(CacheService.tableBox)) {
        print("📋 Masalar önbellekten yükleniyor...");
        _tables = _cacheService.getTables();
        _isLoadingTables = false;
        notifyListeners();
        return;
      }

      print("🌐 Masalar API'den yükleniyor...");
      final tables = await ApiService.getTables();
      _tables = tables;
      await _cacheService.cacheTables(tables);

      _isLoadingTables = false;
      notifyListeners();
    } catch (e) {
      print("❌ Masalar yüklenirken hata: $e");
      _tablesError = e.toString();

      if (_cacheService.hasTables()) {
        print("📋 Hata nedeniyle önbellekten yükleniyor...");
        _tables = _cacheService.getTables();
      }

      _isLoadingTables = false;
      notifyListeners();
    }
  }

  // Önbelleği zorla yenile
  Future<void> refreshCache() async {
    try {
      _isLoadingMenuItems = true;
      _isLoadingTables = true;
      notifyListeners();

      final menuItems = await ApiService.getMenuItems();
      final tables = await ApiService.getTables();

      _menuItems = menuItems;
      _tables = tables;

      await _cacheService.cacheMenuItems(menuItems);
      await _cacheService.cacheTables(tables);

      _isLoadingMenuItems = false;
      _isLoadingTables = false;
      _menuItemsError = null;
      _tablesError = null;

      notifyListeners();
      print("✅ Önbellek başarıyla yenilendi");
    } catch (e) {
      print("❌ Önbellek yenilenirken hata: $e");
      _menuItemsError = e.toString();
      _tablesError = e.toString();
      _isLoadingMenuItems = false;
      _isLoadingTables = false;
      notifyListeners();
    }
  }

  // Önbelleği temizle
  Future<void> clearCache() async {
    await _cacheService.clearCache();
    _menuItems = [];
    _tables = [];
    _orders.clear();
    _orderTimes.clear();
    _orderNotes.clear();
    _orderUserNames.clear();
    _orderUserIds.clear();
    notifyListeners();
  }

  void setCurrentOrder({
    String? note,
    String? tableNumber,
    double? totalAmount,
  }) {
    notifyListeners();
  }

  void completeOrder(
    String tableNumber,
    List<MenuItem> items, {
    String note = '',
    required String userName,
    required String userId,
  }) {
    //print("✅ completeOrder çağrıldı: $tableNumber - ${items.length} ürün");
    _orders[tableNumber] = items;
    _orderTimes[tableNumber] = DateTime.now();
    _orderNotes[tableNumber] = note;
    _orderUserNames[tableNumber] = userName;
    _orderUserIds[tableNumber] = userId;
    notifyListeners();
  }

  String? getOrderUserName(String tableNumber) {
    return _orderUserNames[tableNumber];
  }

  String? getOrderUserId(String tableNumber) {
    return _orderUserIds[tableNumber];
  }

  List<MenuItem>? getOrders(String tableNumber) {
    return _orders[tableNumber];
  }

  DateTime? getOrderTime(String tableNumber) {
    return _orderTimes[tableNumber];
  }

  String? getOrderNote(String tableNumber) {
    return _orderNotes[tableNumber];
  }

  bool hasOrder(String tableNumber) {
    return _orders.containsKey(tableNumber) && _orders[tableNumber]!.isNotEmpty;
  }

  void removeOrder(String tableNumber) {
    _orders.remove(tableNumber);
    _orderTimes.remove(tableNumber);
    _orderNotes.remove(tableNumber);
    _orderUserNames.remove(tableNumber);
    _orderUserIds.remove(tableNumber);
    notifyListeners();
  }

  void addToOrder(MenuItem item) {
    _selectedItems.add(item);
    notifyListeners();
  }

  void removeItemFromOrder(String tableName, MenuItem item) {
    if (_orders.containsKey(tableName)) {
      _orders[tableName]!.remove(item);
      notifyListeners();
    }
  }

  void clearOrder() {
    _selectedItems.clear();
    notifyListeners();
  }

  Future<void> loadOrdersForTables(List<RestaurantTable> tables) async {
    try {
      for (var table in tables) {
        if (table.ticketId != 0) {
          print(
            'Siparişler yükleniyor: Masa=${table.name}, TicketId=${table.ticketId}',
          );
          final ticket = await ApiService.getTicketById(table.ticketId);
          if (ticket == null) {
            print('Ticket bulunamadı: ticketId=${table.ticketId}');
            continue;
          }

          final ticketItems = await ApiService.getTicketItemsByTicketId(
            table.ticketId,
          );
          final menuItems = await ApiService.getMenuItems();

          List<MenuItem> items =
              ticketItems.map((ticketItem) {
                return menuItems.firstWhere(
                  (menuItem) => menuItem.id == ticketItem.menuItemId,
                  orElse:
                      () => MenuItem(
                        id: ticketItem.menuItemId,
                        name: ticketItem.menuItemName,
                        price: ticketItem.price,
                        category: 'Genel',
                        groupCode: 'Genel',
                      ),
                );
              }).toList();

          // Boş liste bile olsa _orders'a ekle
          _orders[table.name] = items;
          if (items.isNotEmpty) {
            completeOrder(
              table.name,
              items,
              note: ticket.note ?? '',
              userName: 'Bilinmiyor',
              userId: '0',
            );
            //print("Sipariş yüklendi: Masa=${table.name}, Öğeler=$items");
          } else {
            print(
              'Masa için sipariş bulunamadı, boş liste eklendi: ${table.name}',
            );
          }
        }
      }
    } catch (e) {
      print('Sipariş yükleme hatası: loadOrdersForTables orderprovider: $e');
    }
  }

  void removeFromOrder(MenuItem item) {
    _selectedItems.remove(item);
    notifyListeners();
  }

  // Önbellekteki masaları güncelleme
  Future<void> _updateTableCache(
    int oldTableId,
    int newTableId,
    int ticketId,
  ) async {
    final updatedTables =
        _tables.map((table) {
          if (table.id == oldTableId) {
            return RestaurantTable(
              id: table.id,
              name: table.name,
              order: table.order,
              category: table.category,
              ticketId: 0,
            );
          } else if (table.id == newTableId) {
            return RestaurantTable(
              id: table.id,
              name: table.name,
              order: table.order,
              category: table.category,
              ticketId: ticketId,
            );
          }
          return table;
        }).toList();

    _tables = updatedTables;
    await _cacheService.cacheTables(updatedTables);
  }

  List<MenuItem> get selectedItems => _selectedItems;

  void moveOrder(String sourceTable, String targetTable) async {
    if (_orders.containsKey(targetTable) && _orders[targetTable]!.isNotEmpty) {
      throw Exception("Hedef masa ($targetTable) zaten dolu!");
    }

    // Masa ID'lerini al
    final sourceTableObj = _cacheService.getTableByName(sourceTable);
    final targetTableObj = _cacheService.getTableByName(targetTable);
    if (sourceTableObj == null || targetTableObj == null) {
      throw Exception("Masa bilgileri alınamadı!");
    }
    final oldTableId = sourceTableObj.id;
    final newTableId = targetTableObj.id;
    final ticketId = sourceTableObj.ticketId;

    if (ticketId == 0) {
      throw Exception("Kaynak masada bilet bulunamadı!");
    }

    // API ile fiş taşı
    await ApiService.moveTicket(oldTableId, newTableId, ticketId);

    // Yerel siparişi taşı (null ise boş liste ata)
    _orders[targetTable] = _orders[sourceTable] ?? [];
    _orderTimes[targetTable] = _orderTimes[sourceTable] ?? DateTime.now();
    _orderNotes[targetTable] = _orderNotes[sourceTable] ?? '';
    _orderUserNames[targetTable] = _orderUserNames[sourceTable] ?? '';
    _orderUserIds[targetTable] = _orderUserIds[sourceTable] ?? '';
    _orders.remove(sourceTable);
    _orderTimes.remove(sourceTable);
    _orderNotes.remove(sourceTable);
    _orderUserNames.remove(sourceTable);
    _orderUserIds.remove(sourceTable);

    // Önbelleği güncelle
    await _updateTableCache(oldTableId, newTableId, ticketId);

    notifyListeners();
  }

  Future<void> completeOrderWithApi({
    required String tableName,
    required List<MenuItem> items,
    required String note,
    required String userName,
    required String userId,
    required double totalAmount,
    int existingTicketId = 0,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final dateString = now.toIso8601String().split('.')[0];
      int ticketId;

      if (existingTicketId != 0) {
        ticketId = existingTicketId;
        final existingTicket = await ApiService.getTicketById(ticketId);
        if (existingTicket != null) {
          final newTotal = existingTicket.totalAmount + totalAmount;
          await ApiService.updateTicket(ticketId, {
            "TotalAmount": newTotal,
            "RemainingAmount": newTotal,
            "LastUpdateTime": dateString,
            "LastOrderDate": dateString,
            "LastPaymentDate": dateString,
          });
        } else {
          throw Exception("Mevcut bilet bulunamadı");
        }
      } else {
        final orderData = {
          "Id": 0,
          "Name": "Mobil Sipariş",
          "DepartmentId": 1,
          "LastUpdateTime": now.toIso8601String(),
          "PrintJobData": "2:1",
          "Date": now.toIso8601String(),
          "LastOrderDate": now.toIso8601String(),
          "LastPaymentDate": now.toIso8601String(),
          "LocationName": tableName,
          "CustomerId": int.tryParse(userId) ?? 0,
          "CustomerName": "Musteri",
          "CustomerGroupCode": "misafir",
          "IsPaid": false,
          "RemainingAmount": totalAmount,
          "TotalAmount": totalAmount,
          "Note": note.isNotEmpty ? note : "Not yok",
          "Locked": false,
          "Tag": "RestaurantOrder",
        };

        final response = await ApiService.sendOrderToDatabase(orderData);
        ticketId = response['id'] as int;
      }

      for (final item in items) {
        final ticketItemData = {
          "MenuItemName": item.name,
          "PortionName": "Normal",
          "Price": item.price,
          "Quantity": 1,
          "Note": note,
          "MenuItemId": item.id,
          "TicketId": ticketId,
        };
        await ApiService.sendTicketItemToDatabase(ticketItemData);
      }

      if (existingTicketId == 0) {
        final tableId = await ApiService.getTableIdByName(tableName);
        await ApiService.updateTableTicketId(
          tableId: tableId,
          ticketId: ticketId,
        );
      }

      final existingItems = getOrders(tableName) ?? [];
      final combinedItems = [...existingItems, ...items];
      completeOrder(
        tableName,
        combinedItems,
        note: note,
        userName: userName,
        userId: userId,
      );
      _selectedItems.clear();
      notifyListeners();
    } catch (e) {
      throw Exception('Sipariş kaydedilemedi: $e');
    }
  }
}
