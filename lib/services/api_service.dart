import 'dart:async';
import 'dart:math';
import 'package:sambapos_app_restorant/models/table.dart';
import 'package:sambapos_app_restorant/models/menu_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sambapos_app_restorant/models/menu_item_property_groups.dart';
import 'package:sambapos_app_restorant/models/menu_item_properties.dart'
    as properties;
import 'package:sambapos_app_restorant/models/menu_item_portion.dart';
import 'package:sambapos_app_restorant/models/ticket.dart';
import 'package:sambapos_app_restorant/models/User_UserRole.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.56.1:5235';

  static Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/Menu'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        // 1) Yanıtı önce Map olarak parse et
        final Map<String, dynamic> data = json.decode(response.body);
        // 2) $values anahtarından gerçek listeyi al (anahtar isimleri API'ye göre değişebilir)
        final List<dynamic> items = data['\$values'] ?? [];
        // 3) Gelen listeyi modelinize map’le
        return items.map((item) => MenuItem.fromJson(item)).toList();
      } else {
        throw Exception(
          'Menü öğeleri yüklenemedi. Durum kodu: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Menü öğeleri alınırken hata: $e');
    }
  }

  static Future<Map<String, dynamic>?> validateUser(String username, String pin) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/User?name=$username'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        final user = users.firstWhere(
              (user) =>
          user['Name'] == username &&
              user['PinCode'] == pin &&
              user['UserRole_Id'] != null,
          orElse: () => null,
        );
        if (user != null) {
          return {
            'userId': user['Id'] as int,
            'userRoleId': user['UserRole_Id'] as int,
            'userName': user['Name'] as String,
            'roleName': user['UserRole']?['Name']?.toString() ?? 'Bilinmiyor',
          };
        }
        return null;
      } else {
        throw Exception('Kullanıcı doğrulanamadı. Durum kodu: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Kullanıcı doğrulanırken hata: $e');
    }
  }

  // static Future<List<Map<String, dynamic>>> getUserRoles() async {
  //   try {
  //     final response = await http
  //         .get(Uri.parse('$baseUrl/api/UserRole'))
  //         .timeout(const Duration(seconds: 20));
  //
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body);
  //       final List<dynamic> roles = data['\$values'] ?? [];
  //       return roles.cast<Map<String, dynamic>>();
  //     } else {
  //       throw Exception(
  //         'Kullanıcı rolleri yüklenemedi. Durum kodu: ${response.statusCode}',
  //       );
  //     }
  //   } on TimeoutException {
  //     throw Exception('İstem zaman aşımına uğradı');
  //   } catch (e) {
  //     throw Exception('Kullanıcı rolleri alınırken hata: $e');
  //   }
  // }

  static Future<List<User>> getUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/User'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> users = data['\$values'] ?? [];
        return users
            .map((user) => User.fromJson(user))
            .where((user) => user.id != 0)
            .toList();
      } else {
        throw Exception('Kullanıcılar yüklenemedi. Durum kodu: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Kullanıcı verileri alınırken hata: $e');
    }
  }

  static Future<List<UserRole>> getUserRoles() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/UserRole'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> roles = data['\$values'] ?? [];
        return roles.map((role) => UserRole.fromJson(role)).toList();
      } else {
        throw Exception('Kullanıcı rolleri yüklenemedi. Durum kodu: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Kullanıcı rolleri alınırken hata: $e');
    }
  }

  static Future<void> testUsersWithRoles() async {
    try {
      final List<User> users = await getUsers();
      //print("Kullanıcılar: $users");

      final List<UserRole> roles = await getUserRoles();
      //print("Roller: $roles");

      final Map<String, dynamic>? userData = await validateUserByPin("3334");
      //print("Doğrulanan Kullanıcı (Pin: 3334): $userData");

      final Map<String, dynamic>? invalidUserData = await validateUserByPin(
        "9999",
      );
      print("Doğrulanan Kullanıcı (Pin: 9999): $invalidUserData");
    } catch (e) {
      print("Test hatası: $e");
    }
  }

  static Future<Map<String, dynamic>?> validateUserByPin(String pin) async {
    try {
      final List<User> users = await getUsers();
      final matchedUser = users.firstWhere(
            (user) => user.pinCode == pin.trim(),
        orElse: () => User(id: 0, name: 'Unknown', pinCode: '', userRoleId: 0),
      );
      if (matchedUser.id != 0) {
        final userRole = (await getUserRoles()).firstWhere(
              (role) => role.id == matchedUser.userRoleId,
          orElse: () => UserRole(id: 0, name: 'Bilinmeyen Rol', isAdmin: false),
        );
        return {
          'userId': matchedUser.id,
          'userRoleId': matchedUser.userRoleId,
          'userName': matchedUser.name,
          'roleName': userRole.name,
          'isAdmin': userRole.isAdmin,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı doğrulanırken hata: $e');
    }
  }

  static Future<Map<String, dynamic>?> login(String pinCode) async {
    try {
      final userData = await validateUserByPin(pinCode);
      if (userData == null) {
        print('Giriş başarısız: Kullanıcı bulunamadı');
        return null;
      }
      return userData;
    } catch (e) {
      print('Giriş hatası: $e');
      throw Exception('Giriş başarısız: $e');
    }
  }

  static Future<void> moveTicket(
    int oldTableId,
    int newTableId,
    int ticketId,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse(
              '$baseUrl/api/Table/moveTicket?oldTableId=$oldTableId&newTableId=$newTableId&ticketId=$ticketId',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception("Fiş taşınamadı: ${response.body}");
      }
      print("Fiş başarıyla taşındı");
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Fiş taşınırken hata: $e');
    }
  }

  static Future<List<RestaurantTable>> getTables() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/Table'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          response.body,
        ); // Map olarak parse et
        final List<dynamic> tables =
            data['\$values'] ?? []; // $values anahtarından listeyi al
        return tables.map((item) => RestaurantTable.fromJson(item)).toList();
      } else {
        throw Exception(
          'Masalar yüklenemedi. Durum kodu: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Masalar alınırken hata: $e');
    }
  }

  static Future<void> updateTableTicketId({
    required int tableId,
    required int ticketId,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/Table/$tableId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'ticketId': ticketId ?? 0}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception("Masa güncellenemedi: ${response.body}");
      }
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı');
    }
  }

  static Future<void> updateTicket(
    int ticketId,
    Map<String, dynamic> ticketData,
  ) async {
    print("GÖNDERİLEN VERİ: $ticketData");
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/Tickets/$ticketId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(ticketData),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        print("Hata yanıtı: ${response.body}");
        throw Exception("Bilet güncellenemedi: ${response.body}");
      }
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı');
    } catch (e) {
      throw Exception("Billet günellenemdi: $e");
    }
  }

  static Future<int> getTableIdByName(String name) async {
    final resp = await http.get(Uri.parse('$baseUrl/api/table/byName/$name'));
    if (resp.statusCode == 200) {
      return int.parse(resp.body);
    }
    throw Exception('Masa ID alınamadı: ${resp.statusCode}');
  }

  static String formatDateTime(String dateTime) {
    final parsedDate = DateTime.parse(dateTime);
    return parsedDate.toIso8601String().split('.')[0];
  }

  static Future<String> getLatestTicketNumber() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/Tickets'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        List<dynamic> tickets = json.decode(response.body);
        if (tickets.isEmpty) {
          return "1"; // Hiç bilet yoksa "1" ile başla
        }
        // En yüksek ticketNumber'ı bul
        final latestTicket = tickets.fold<Map<String, dynamic>>(
          {'ticketNumber': '0'},
          (prev, ticket) {
            final currentNumber =
                int.tryParse(ticket['ticketNumber'] ?? '0') ?? 0;
            final prevNumber = int.tryParse(prev['ticketNumber'] ?? '0') ?? 0;
            return currentNumber > prevNumber ? ticket : prev;
          },
        );
        final latestNumber =
            int.tryParse(latestTicket['ticketNumber'] ?? '0') ?? 0;
        return (latestNumber + 1).toString();
      } else {
        throw Exception('Biletler alınamadı: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı');
    } catch (e) {
      throw Exception('Son bilet numarası alınırken hata: $e');
    }
  }

  static Future<Map<String, dynamic>> sendOrderToDatabase(
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/api/Tickets');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        final result = json.decode(response.body);
        return result;
      }
      throw Exception('API yanıtı boş');
    }
    throw Exception("Sipariş gönderilemedi: HTTP ${response.statusCode}");
  }

  //Ticket'tan sipariş silme.
  static Future<void> removeTicketItem(int ticketItemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/ticketItems/$ticketItemId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception("Ürün silinemedi");
    }
  }

  static Future<Ticket?> getTicketById(int ticketId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/Tickets/$ticketId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Ticket.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Bilet bilgileri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bilet alınırken hata oluştu $e');
    }
  }

  static Future<List<MenuItemPropertyGroup>> getMenuItemPropertyGroups() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/MenuItemPropertyGroups'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> groups = data['\$values'] ?? []; // dikkat: \$values
      return groups.map((e) => MenuItemPropertyGroup.fromJson(e)).toList();
    } else {
      throw Exception('PropertyGroups yüklenemedi: ${response.statusCode}');
    }
  }

  static Future<List<properties.MenuItemProperty>>
  getMenuItemProperties() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/MenuItemProperties'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = json.decode(response.body);
      final List<dynamic> data = decoded['\$values'] ?? [];

      return data.map((e) {
        // Farklı olasılıklar için tüm key adlarını kontrol et
        if (e.containsKey('MenuItemPropertyGroupId')) {
          e['menuItemPropertyGroupId'] = e['MenuItemPropertyGroupId'];
        } else if (e.containsKey('MenuItemPropertyGroup_Id')) {
          e['menuItemPropertyGroupId'] = e['MenuItemPropertyGroup_Id'];
        } else {
          e['menuItemPropertyGroupId'] = 0;
        }

        return properties.MenuItemProperty.fromJson(e);
      }).toList();
    } else {
      throw Exception('Properties yüklenemedi: ${response.statusCode}');
    }
  }

  // Örnek: MenuItemPortions için
  static Future<List<MenuItemPortion>> getMenuItemPortions() async {
    final response = await http.get(Uri.parse('$baseUrl/api/MenuItemPortions'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> portions = data['\$values'] ?? [];
      return portions.map((e) => MenuItemPortion.fromJson(e)).toList();
    } else {
      throw Exception('Portions yüklenemedi: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchTicketItems() async {
    final response = await http.get(Uri.parse('$baseUrl/api/TicketItems'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Veriler alınamadı');
    }
  }

  Future<void> sendTicketItem(TicketItemDto dto) async {
    final url = Uri.parse('$baseUrl/api/TicketItems');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 201) {
      print("✅ TicketItem başarıyla gönderildi.");
    } else {
      print("❌ TicketItem gönderilemedi. Kod: ${response.statusCode}");
      print("Yanıt: ${response.body}");
    }
  }

  static Future<void> sendTicketItemToDatabase(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/TicketItems'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('TicketItem gönderilemedi: ${response.body}');
    }
  }

  static Future<List<TicketItemDto>> getTicketItemsByTicketId(
    int ticketId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/TicketItems/byTicketId/$ticketId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> listData = data['\$values'] ?? [];
        // if (data.isEmpty) return [];
        return listData.map((item) => TicketItemDto.fromJson(item)).toList();
      } else {
        throw Exception('TicketItems yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('TicketItems alınırken (id) hata: $e');
    }
  }

  static Future<List<MenuItemPropertyGroup>> getPropertyGroupsForMenuItem(
    int menuItemId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/MenuItemPropertyGroups/$menuItemId/property-groups',
        ),
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        if (data.isEmpty) return [];
        return data.map((e) => MenuItemPropertyGroup.fromJson(e)).toList();
      } else {
        throw Exception(
          'PropertyGroups yüklenemedi: ${response.statusCode}, Mesaj: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('PropertyGroups alınırken hata: $e');
    }
  }
}
