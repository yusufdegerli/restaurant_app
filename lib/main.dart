import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sambapos_app_restorant/models/menu_item.dart';
import 'package:sambapos_app_restorant/models/table.dart';
import 'package:sambapos_app_restorant/providers/auth_provider.dart';
import 'package:sambapos_app_restorant/providers/order_provider.dart';
import 'package:sambapos_app_restorant/screens/login_screen.dart';
import 'package:sambapos_app_restorant/services/cache_service.dart';
import 'package:sambapos_app_restorant/services/websocket_service.dart';
import 'screens/table_selection_screen.dart';
import 'screens/order_screen.dart';

// Tema yönetimi için provider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();

    Hive.registerAdapter(MenuItemAdapter());
    Hive.registerAdapter(RestaurantTableAdapter());

    await Hive.openBox<MenuItem>('menuItems');
    await Hive.openBox<RestaurantTable>('tables');
    await Hive.openBox('cacheInfo');

    print("Hive kutuları başarıyla açıldı.");
  } catch (e) {
    print("Hive başlatma hatası: $e");
  }

  // Servisleri başlat
  final webSocketService = WebSocketService();
  final cacheService = CacheService();
  final orderProvider = OrderProvider(webSocketService, cacheService);

  // WebSocket bağlantısını kur
  webSocketService.connect(
    onMessageReceived: (message) {
      print("Main: WebSocket mesajı alındı: $message");
    },
  );

  runApp(
    MyApp(
      webSocketService: webSocketService,
      cacheService: cacheService,
      orderProvider: orderProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final WebSocketService webSocketService;
  final CacheService cacheService;
  final OrderProvider orderProvider;

  const MyApp({
    super.key,
    required this.webSocketService,
    required this.cacheService,
    required this.orderProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: orderProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider.value(value: webSocketService),
        Provider.value(value: cacheService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Restaurant POS',
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF4ECEC),
              colorScheme: ColorScheme.light(
                primary: const Color(0xFFF0C84C),
                secondary: const Color(0xFF803E64),
                background: const Color(0xFFF4ECEC),
                surface: const Color(0xFFF8E4BF),
                onPrimary: const Color(0xFF203F62),
                onSecondary: const Color(0xFFFFFFFF),
                onBackground: const Color(0xFF555F70),
                onSurface: const Color(0xFF555F70),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF8E4BF),
                foregroundColor: Color(0xFF555F70),
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF0C84C),
                  foregroundColor: Color(0xFF203F62),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
              textTheme: TextTheme(
                displayLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF555F70),
                ),
                displayMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF555F70),
                ),
                displaySmall: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF555F70),
                ),
                headlineMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF555F70),
                ),
                titleLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF555F70),
                ),
                bodyLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Color(0xFF555F70),
                ),
                bodyMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Color(0xFF555F70),
                ),
                labelLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF555F70),
                ),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF272140),
              colorScheme: ColorScheme.dark(
                primary: const Color(0xFF4DA6EF),
                secondary: const Color(0xFF4AACFD),
                background: const Color(0xFF272140),
                surface: const Color(0xFF566571),
                onPrimary: const Color(0xFFF2F2F2),
                onSecondary: const Color(0xFFBFDDf7),
                onBackground: const Color(0xFFF2F2F2),
                onSurface: const Color(0xFFF2F2F2),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF566571),
                foregroundColor: Color(0xFFF2F2F2),
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4DA6EF),
                  foregroundColor: Color(0xFFF2F2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
              textTheme: TextTheme(
                displayLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFFF2F2F2),
                ),
                displayMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFFF2F2F2),
                ),
                displaySmall: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFFF2F2F2),
                ),
                headlineMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFFF2F2F2),
                ),
                titleLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFFF2F2F2),
                ),
                bodyLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Color(0xFFF2F2F2),
                ),
                bodyMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Color(0xFFF2F2F2),
                ),
                labelLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFFF2F2F2),
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            routes: {
              '/tables': (context) => TableSelectionScreen(),
              '/order': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return OrderScreen(
                  tableName: args?['tableName'] as String? ?? '',
                  ticketId: args?['ticketId'] as int? ?? 0,
                );
              },
            },
            home: LoginScreen(),
          );
        },
      ),
    );
  }
}

class CommonScreen extends StatelessWidget {
  final String tableNumber;

  const CommonScreen({super.key, required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$tableNumber Masası')),
      body: Center(child: Text('$tableNumber Masası İçerik Alanı')),
    );
  }
}