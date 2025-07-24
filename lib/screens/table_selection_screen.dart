import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambapos_app_restorant/models/table.dart';
import 'package:sambapos_app_restorant/providers/auth_provider.dart';
import 'package:sambapos_app_restorant/providers/order_provider.dart';
import 'package:sambapos_app_restorant/services/api_service.dart';
import 'package:sambapos_app_restorant/models/menu_item.dart';
import 'order_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:sambapos_app_restorant/services/websocket_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sambapos_app_restorant/screens/login_screen.dart';
import 'package:sambapos_app_restorant/screens/close_table_screen.dart';
import '../main.dart';
import 'package:sambapos_app_restorant/animations/animated_overlay.dart';
import 'package:sambapos_app_restorant/widgets/animated_sheet_content.dart';
import 'package:sambapos_app_restorant/widgets/table_category_section.dart';
import 'package:sambapos_app_restorant/widgets/table_selection_appbar.dart';
import 'package:sambapos_app_restorant/utils/table_selection_helpers.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sambapos_app_restorant/widgets/animate_gradient_background.dart';

class Particle {
  Offset position;
  double speed;
  double radius;

  Particle({
    required this.position,
    required this.speed,
    required this.radius,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final bool isDarkMode;

  ParticlePainter(this.particles, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.9)
          : Colors.black.withOpacity(0.7);
    canvas.drawCircle(Offset(100, 100), 10, paint); // Sabit test partikülü
    for (var p in particles) {
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return particles != oldDelegate.particles;
  }
}

class AnimatedParticles extends StatefulWidget {
  final bool isDarkMode;
  const AnimatedParticles({super.key, required this.isDarkMode});

  @override
  State<AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<AnimatedParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Particle> _particles = [];
  final int count = 150;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_updateParticles);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initParticles(MediaQuery.of(context).size);
    });

    _controller.repeat();
  }

  void _initParticles(Size size) {
    _particles.clear();
    for (int i = 0; i < count; i++) {
      _particles.add(
        Particle(
          position: Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
          speed: random.nextDouble() * 0.7 + 0.3,
          radius: random.nextDouble() * 3 + 1.0,
        ),
      );
    }
  }

  void _updateParticles() {
    final size = MediaQuery.of(context).size;
    for (var p in _particles) {
      var y = p.position.dy + p.speed;
      if (y > size.height) y = 0;
      p.position = Offset(p.position.dx, y);
      if (_particles.indexOf(p) < 5) {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: ParticlePainter(_particles, widget.isDarkMode),
              child: Container(),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class TableSelectionScreen extends StatefulWidget {
  @override
  _TableSelectionScreenState createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen>
    with TickerProviderStateMixin {
  Timer? _pollingTimer;
  List<RestaurantTable> _tables = [];
  Map<String, List<RestaurantTable>> _groupedTables = {};
  Map<String, int> _tableIdCache = {};
  bool _isLoading = true;
  String _error = '';
  String? _userName;
  bool _isMovingTable = false;
  String? _sourceTable;
  int? _userId;
  bool _isEditing = false;

  late WebSocketService _webSocketService;
  late Box<RestaurantTable> _tablesBox;
  bool _useLocalCache = true;
  late AnimationController _lottieController;

  //gradient animasyonu için
  late AnimationController _gradientController;
  late Animation<Alignment> _beginAnimation;
  late Animation<Alignment> _endAnimation;

  OverlayEntry? _overlayEntry;
  final Map<String, GlobalKey> _tableKeys = {};

  // Renk test için eklenen state
  /*Map<String, String> _lightColors = {
    'primary': '799EFF',
    'secondary': 'FFDE63',
    'background': 'FEFFC4',
    'surface': 'FFDE63',
    'appBar': 'FFBC4C',
    'onPrimary': '090040',
    'onSurface': '090040',
  };
  Map<String, String> _darkColors = {
    'primary': '000B58',
    'secondary': '003161',
    'background': '006A67',
    'surface': '003161',
    'appBar': '003161',
    'onPrimary': 'FFF4B7',
    'onSurface': 'FFF4B7',
  };
  bool _showColorTest = false;*/

  // Aktif renkleri döndüren yardımcı fonksiyonlar
  /*Color _getColor(String key) {
    final brightness = Theme.of(context).brightness;
    final hex = brightness == Brightness.dark ? _darkColors[key]! : _lightColors[key]!;
    return Color(int.parse('0xFF$hex'));
  }
  Color get _backgroundColor => _getColor('background');
  Color get _appBarColor => _getColor('appBar');
  Color get _primaryColor => _getColor('primary');
  Color get _surfaceColor => _getColor('surface');
  Color get _onPrimaryColor => _getColor('onPrimary');
  Color get _onSurfaceColor => _getColor('onSurface');*/

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    //Gradient animasyonu
    _gradientController  = AnimationController(
        vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _beginAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(_gradientController);

    _endAnimation = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).animate(_gradientController);
    //Gradient animasyon yukarısı
    _initHive().then((_) {
      print("Hive initialized, fetching tables");
      _fetchTables();
      _getUserName();
      _getUserId();

      _webSocketService = WebSocketService();
      _webSocketService.connect(
        onMessageReceived: (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'ticket_updated') {
            final tableId = data['data']['tableId'];
            final ticketId = data['data']['ticketId'] ?? 0;
            setState(() {
              final table = _tables.firstWhere(
                    (t) => t.id == tableId,
                orElse: () => RestaurantTable(
                  id: -1,
                  name: '',
                  category: 'Genel',
                  order: -1,
                  ticketId: 0,
                ),
              );
              if (table.id == -1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Masa (ID: $tableId) bulunamadı!"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              table.ticketId = ticketId;
              _groupedTables = _groupTablesByCategory(_tables);
              _saveTableToHive(table);
            });
          }
        },
      );

      _pollingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
        _fetchTables();
      });
    }).catchError((error) {
      print("Error in initState: $error");
      setState(() {
        _error = 'Yerel depolama başlatılamadı: $error';
        _isLoading = false;
      });
    });
  }

  String _getRoleEmoji(int? userRoleId) {
    switch (userRoleId) {
      case 1:
        return '👨🏻‍💼'; // Admin
      case 2:
        return '👨🏻‍💻';
      case 3:
        return '🛎️';
      case 4:
        return '🤵🏻';
      case 5:
        return '🛵';
      default:
        return '';
    }
  }

  Future<void> _initHive() async {
    try {
      await Hive.initFlutter();
      print("HIVE BAŞLADI");
      if (!Hive.isAdapterRegistered(RestaurantTableAdapter().typeId)) {
        Hive.registerAdapter(RestaurantTableAdapter());
      }
      if (!Hive.isBoxOpen('Tables')) {
        _tablesBox = await Hive.openBox<RestaurantTable>('Tables');
        print("TABLES açıldı. Box boş mu: ${_tablesBox.isEmpty}");
        print("TABLES kutusundaki kayıt sayısı: ${_tablesBox.length}");
      } else {
        _tablesBox = Hive.box<RestaurantTable>('Tables');
      }
      if (_tablesBox.isNotEmpty && _useLocalCache) {
        final cachedTables = _tablesBox.values.toList();
        print("Önbellekten ${cachedTables.length} masa yüklendi");
        setState(() {
          _tables = cachedTables;
          _groupedTables = _groupTablesByCategory(cachedTables);
          _tableIdCache = {for (var table in cachedTables) table.name: table.id};
          _isLoading = false;
        });
      }
      print("Hive başarıyla başlatıldı ve Tables kutusu açıldı.");
    } catch (e) {
      print("Hive başlatma hatası: $e");
      setState(() {
        _error = 'Hive başlatma hatası: $e';
        _isLoading = false;
      });
      throw e;
    }
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    _pollingTimer?.cancel();
    if (Hive.isBoxOpen('Tables')) {
      _tablesBox.close();
    }
    _gradientController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  void _startAnimationAndNavigate(BuildContext context, String tableName, Color buttonColor) {
    final tableKey = _tableKeys[tableName];
    if (tableKey == null || tableKey.currentContext == null) return;

    // Butonun pozisyonu ve boyutu için
    final RenderBox renderBox = tableKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    // Overlay girişleri
    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedOverlay(
        initialPosition: position,
        initialSize: size,
        buttonColor: buttonColor,
        onAnimationComplete: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          _navigateToOrderScreen(context, tableName, position, size, buttonColor);
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // initialPosition, initialSize ve buttonColor parametreleri eklendi
  void _navigateToOrderScreen(BuildContext context, String tableName, [Offset? initialPosition, Size? initialSize, Color? buttonColor]) {
    final table = _tables.firstWhere((t) => t.name == tableName);
    final ticketId = table.ticketId;
    Provider.of<OrderProvider>(context, listen: false).clearOrder();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OrderScreen(
          tableName: tableName,
          ticketId: ticketId,
          // Route arguments ile pozisyon, boyut ve renk aktarılıyor
        ),
        settings: RouteSettings(
          arguments: {
            'initialPosition': initialPosition,
            'initialSize': initialSize,
            'buttonColor': buttonColor,
          },
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  void _getUserId() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.userId;
    print("UserId fetched: $_userId");
  }

  void _getUserName() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userName = authProvider.userName;
    print("UserName fetched: $_userName");
  }

  Future<void> _fetchTables() async {
    try {
      print("Fetching tables from API");
      List<RestaurantTable> tables = await ApiService.getTables();
      final grouped = await _groupTablesInBackground(tables);
      if (!mounted) return;

      setState(() {
        _tables = tables;
        _groupedTables = grouped;
        _tableIdCache = {for (var table in tables) table.name: table.id};
        _isLoading = false;
      });

      await _saveAllTablesToHive(tables);

      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.loadOrdersForTables(tables);
      print(
        "Siparişler yüklendi: ${_tables.map((t) => '${t.name}: ${orderProvider.getOrders(t.name)}').join(', ')}",
      );
    } catch (e, stackTrace) {
      print("Error fetching tables: $e");
      print(stackTrace);
      if (_useLocalCache && _tablesBox.isNotEmpty) {
        final cachedTables = _tablesBox.values.toList();
        setState(() {
          _tables = cachedTables;
          _groupedTables = _groupTablesByCategory(cachedTables);
          _tableIdCache = {for (var table in cachedTables) table.name: table.id};
          _isLoading = false;
          _error = 'API bağlantı hatası: $e (Önbellekten veriler gösteriliyor)';
        });
      } else {
        setState(() {
          _error = 'Masalar yüklenemedi: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAllTablesToHive(List<RestaurantTable> tables) async {
    try {
      if (!Hive.isBoxOpen('Tables')) {
        await _initHive();
      }
      await _tablesBox.clear();
      for (var table in tables) {
        await _tablesBox.put(table.id.toString(), table);
      }
    } catch (e) {
      print("Hive kaydetme hatası: $e");
    }
  }

  Future<void> _saveTableToHive(RestaurantTable table) async {
    try {
      if (!Hive.isBoxOpen('Tables')) {
        await _initHive();
      }
      await _tablesBox.put(table.id.toString(), table);
    } catch (e) {
      print("Masa Hive'a kaydedilemedi: $e");
    }
  }

  Future<Map<String, List<RestaurantTable>>> _groupTablesInBackground(List<RestaurantTable> tables) async {
    return await compute(_groupTablesByCategory, tables);
  }

  static Map<String, List<RestaurantTable>> _groupTablesByCategory(List<RestaurantTable> tables) {
    Map<String, List<RestaurantTable>> grouped = {};
    for (var table in tables) {
      String category = table.category ?? 'Genel';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(table);
    }
    return grouped;
  }

  void _onTableLongPress(String tableName, BuildContext context, Offset tapPosition) {
    final table = _tables.firstWhere(
          (t) => t.name == tableName,
      orElse: () => RestaurantTable(
        id: -1,
        name: '',
        category: 'Genel',
        order: -1,
        ticketId: 0,
      ),
    );
    if (table.ticketId != 0) {
      setState(() {
        _sourceTable = tableName;
        _isMovingTable = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Taşıma modu: $tableName masası seçildi. Hedef masaya dokunun.",
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Boş masayı ($tableName) taşıyamazsınız!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _closeActionMenu() {
    setState(() {
      _sourceTable = null;
      _isMovingTable = false;
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Çıkış Yap"),
        content: Text("Çıkış yapmak istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hayır"),
          ),
          TextButton(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return child;
                  },
                ),
                    (Route<dynamic> route) => false,
              );
            },
            child: Text("Evet"),
          ),
        ],
      ),
    );
  }

  void _handleCloseTable() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CloseTableScreen(
          tables: _tables.where((t) => t.ticketId != 0).toList(),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  void _showOrderDetails(String tableName) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if (orderProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OrderProvider bulunamadı.")),
      );
      return;
    }
    final orders = orderProvider.getOrders(tableName);
    final orderTime = orderProvider.getOrderTime(tableName);
    final orderNote = orderProvider.getOrderNote(tableName);

    if (orders == null || orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bu masada sipariş bulunmamaktadır.")),
      );
      return;
    }

    Map<MenuItem, int> grouped = {};
    for (var item in orders) {
      grouped[item] = (grouped[item] ?? 0) + 1;
    }

    double total = 0;
    grouped.forEach((item, quantity) {
      total += item.price * quantity;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return AnimatedSheetContent(
                  scrollController: scrollController,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "$tableName Masası Sipariş Detayları",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  final tableKey = _tableKeys[tableName];
                                  Offset? initialPosition;
                                  Size? initialSize;
                                  Color? buttonColor = Theme.of(context).colorScheme.primary;
                                  if (tableKey  != null && tableKey.currentContext != null){
                                    final RenderBox renderBox = tableKey.currentContext!.findRenderObject() as RenderBox;
                                    initialSize = renderBox.size;
                                    initialPosition = renderBox.localToGlobal(Offset.zero);
                                  }
                                  _startAnimationAndNavigate(context, tableName, buttonColor ?? Theme.of(context).colorScheme.primary);
                                  //_navigateToOrderScreen(context, tableName);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isEditing ? Colors.black : Colors.orange,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size(100, 32),
                                ),
                                child: Text(
                                  _isEditing ? "Bitir" : "Düzenle",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text("Siparişi Alan: $_userName - $_userId"),
                          SizedBox(height: 8),
                          Text(
                            "Sipariş Saati: ${orderTime?.toString() ?? 'Bilinmiyor'}",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Not: ${orderNote?.isNotEmpty == true ? orderNote : 'Not eklenmemiş'}",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                final tableKey = _tableKeys[tableName];
                                Offset? initialPosition;
                                Size? initialSize;
                                Color? buttonColor = Theme.of(context).colorScheme.primary;
                                if (tableKey != null && tableKey.currentContext != null) {
                                  final RenderBox renderBox = tableKey.currentContext!.findRenderObject() as RenderBox;
                                  initialSize = renderBox.size;
                                  initialPosition = renderBox.localToGlobal(Offset.zero);
                                }
                                _startAnimationAndNavigate(context, tableName, buttonColor ?? Theme.of(context).colorScheme.primary);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                "Sipariş Ekle",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Column(
                            children: grouped.entries.map((entry) {
                              final menuItem = entry.key;
                              final quantity = entry.value;
                              return ListTile(
                                title: Text(menuItem.name),
                                subtitle: Text("Adet: $quantity"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "₺${(menuItem.price * quantity).toStringAsFixed(2)}",
                                    ),
                                    if (_isEditing)
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setModalState(() {
                                            if (quantity > 1) {
                                              grouped[menuItem] = quantity - 1;
                                            } else {
                                              grouped.remove(menuItem);
                                            }
                                            orderProvider.removeItemFromOrder(
                                              tableName,
                                              menuItem,
                                            );
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          Divider(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Toplam: ₺${total.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showTicketDetails(RestaurantTable table) async {
    if (table.ticketId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${table.name} masasının geçerli bir ticketId değeri yok.",
          ),
        ),
      );
      return;
    }

    try {
      final ticket = await ApiService.getTicketById(table.ticketId);
      if (ticket == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ticket bulunamadı: ticketId ${table.ticketId}"),
          ),
        );
        return;
      }

      final ticketItems = await ApiService.getTicketItemsByTicketId(table.ticketId);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final menuItems = await ApiService.getMenuItems();

      List<MenuItem> items = ticketItems.map((ticketItem) {
        return menuItems.firstWhere(
              (menuItem) => menuItem.id == ticketItem.menuItemId,
          orElse: () => MenuItem(
            id: ticketItem.menuItemId,
            name: ticketItem.menuItemName,
            price: ticketItem.price,
            category: 'Genel',
            groupCode: 'Genel',
          ),
        );
      }).toList();

      orderProvider.completeOrder(
        table.name,
        items,
        note: ticket.note ?? '',
        userName: _userName ?? 'Bilinmiyor',
        userId: _userId?.toString() ?? '0',
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        enableDrag: true,
        barrierColor: Colors.black.withOpacity(0.2),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) {
              return AnimatedSheetContent(
                scrollController: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${table.name} Masası Bilet Detayları",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Future.delayed(Duration(milliseconds: 100), () {
                                final tableKey = _tableKeys[table.name];
                                Offset? initialPosition;
                                Size? initialSize;
                                Color? buttonColor = Theme.of(context).colorScheme.primary;
                                if (tableKey != null && tableKey.currentContext != null) {
                                  final RenderBox renderBox = tableKey.currentContext!.findRenderObject() as RenderBox;
                                  initialSize = renderBox.size;
                                  initialPosition = renderBox.localToGlobal(Offset.zero);
                                }
                                _startAnimationAndNavigate(context, table.name, buttonColor ?? Theme.of(context).colorScheme.primary);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size(100, 32),
                            ),
                            child: Text(
                              "Düzenle",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Bilet ID: ${ticket.id}",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Masa Adı: ${ticket.name}",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Bilet Numarası: ${ticket.ticketNumber}",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Müşteri Adı: ${ticket.customerName ?? 'Bilinmiyor'}",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Kalan Tutar: ₺${ticket.remainingAmount.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Toplam Tutar: ₺${ticket.totalAmount.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Not: ${ticket.note?.isNotEmpty == true ? ticket.note : 'Not eklenmemiş'}",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Etiket: ${ticket.tag?.isNotEmpty == true ? ticket.tag : 'Etiket yok'}",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Sipariş Öğeleri:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ticketItems.isEmpty
                          ? Text(
                        "Bu bilete ait sipariş öğesi bulunmamaktadır.",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: ticketItems.length,
                        itemBuilder: (context, index) {
                          final ticketItem = ticketItems[index];
                          return ListTile(
                            title: Text(ticketItem.menuItemName),
                            subtitle: Text(
                              "Adet: ${ticketItem.quantity.toStringAsFixed(0)} - Porsiyon: ${ticketItem.portionName}",
                            ),
                            trailing: Text(
                              "₺${(ticketItem.price * ticketItem.quantity).toStringAsFixed(2)}",
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bilet bilgileri alınamadı: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Kategorileri ve masaları gösteren widget'ı dışarıdan alıyoruz
  Widget _buildCategorySections() {
    return TableCategorySection(
      groupedTables: _groupedTables,
      tableKeys: _tableKeys,
      isMovingTable: _isMovingTable,
      sourceTable: _sourceTable,
      onTableTap: (table, buttonColor) async {
        if (_isMovingTable) {
          if (table.name == _sourceTable) {
            setState(() {
              _isMovingTable = false;
              _sourceTable = null;
            });
            showSuccess(context, "Taşıma iptal edildi.");
          } else if (table.ticketId != 0) {
            showError(context, "Hedef masa (${table.name}) zaten dolu!");
            setState(() {
              _isMovingTable = false;
              _sourceTable = null;
            });
          } else {
            await handleTableMove(
              context: context,
              sourceTable: _sourceTable,
              targetTable: table,
              tables: _tables,
              setState: setState,
              updateTables: (newTables) => _tables = newTables,
              updateGroupedTables: (newGrouped) => _groupedTables = newGrouped,
            );
            setState(() {
              _isMovingTable = false;
              _sourceTable = null;
            });
          }
        } else {
          if (table.ticketId != 0) {
            _showTicketDetails(table);
          } else {
            _startAnimationAndNavigate(context, table.name, buttonColor);
          }
        }
      },
      onTableLongPress: (table, context, offset) {
        _onTableLongPress(table.name, context, offset);
      },
    );
  }

  // Renk paleti testiyle ilgili tüm kodlar kaldırıldı

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthorized = authProvider.userRoleId == 1 || authProvider.userRoleId == 2;
    print("isAuthorized: $isAuthorized");

    if (_isLoading) {
      return AnimatedGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                elevation: 0,
                title: Text(
                  "Masa Seçimi",
                  style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                ),
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
    }
    if (_error.isNotEmpty) {
      return AnimatedGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                elevation: 0,
                title: Text(
                  "Masa Seçimi",
                  style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _error,
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return AnimatedGradientBackground(
      includeParticles: true, // Partikül animasyonunu sadece burada kullanıyoruz
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return TableSelectionAppBar(
                  userName: _userName,
                  userRoleId: authProvider.userRoleId,
                  lottieController: _lottieController,
                  onLogout: _handleLogout,
                  onCloseTable: _handleCloseTable,
                  isAuthorized: isAuthorized,
                  themeMode: themeProvider.themeMode,
                  onToggleTheme: themeProvider.toggleTheme,
                );
              },
            ),
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: _closeActionMenu,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCategorySections(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}