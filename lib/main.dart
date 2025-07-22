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
              scaffoldBackgroundColor: const Color(0xFFFEFFC4),
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF799EFF),
                secondary: const Color(0xFFFFDE63),
                background: const Color(0xFFFEFFC4),
                surface: const Color(0xFFFFDE63),
                onPrimary: const Color(0xFF090040),
                onSecondary: const Color(0xFF090040),
                onBackground: const Color(0xFF090040),
                onSurface: const Color(0xFF090040),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFFFBC4C),
                foregroundColor: Color(0xFF090040),
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF799EFF),
                  foregroundColor: Color(0xFF090040),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
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
                  color: Color(0xFF090040),
                ),
                displayMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF090040),
                ),
                displaySmall: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF090040),
                ),
                headlineMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF090040),
                ),
                titleLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF090040),
                ),
                bodyLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Color(0xFF090040),
                ),
                bodyMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Color(0xFF090040),
                ),
                labelLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF090040),
                ),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF000B58),
              colorScheme: ColorScheme.dark(
                primary: const Color(0xFF213555),
                secondary: const Color(0xFF3E5879),
                background: const Color(0xFFEDEDED),
                surface: const Color(0xFF3E5879),
                onPrimary: const Color(0xFFF5EFE7),
                onSecondary: const Color(0xFFF5EFE7),
                onBackground: const Color(0xFF211C84),
                onSurface: const Color(0xFFF5EFE7),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF3E5879),
                foregroundColor: Color(0xFFF5EFE7),
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF213555),
                  foregroundColor: Color(0xFFF5EFE7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
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
                  color: Color(0xFFF5EFE7),
                ),
                displayMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFFF5EFE7),
                ),
                displaySmall: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFFF5EFE7),
                ),
                headlineMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFFF5EFE7),
                ),
                titleLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFFF5EFE7),
                ),
                bodyLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Color(0xFFF5EFE7),
                ),
                bodyMedium: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Color(0xFFF5EFE7),
                ),
                labelLarge: TextStyle(
                  fontFamily: 'WinkyRough',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFFF5EFE7),
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


/*@main.dart dosyasında scaffoldBackgroundColor'ı "000B58" şeklinde yaptım. Ancak arkplan çok sade kaldı. Diğer ekranlar için de geçerli bir şeyler yapmanı istiyorum. Arkaplanı gradient yapabilirsin.
Light mode için
#FEFFC4 -> #F5D667
Dark mode için:
#000000 -> #000B58*/ 