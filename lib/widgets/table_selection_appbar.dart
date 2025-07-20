import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambapos_app_restorant/providers/auth_provider.dart';
import 'package:lottie/lottie.dart';

class TableSelectionAppBar extends StatelessWidget {
  final String? userName;
  final int? userRoleId;
  final AnimationController lottieController;
  final VoidCallback onLogout;
  final VoidCallback onCloseTable;
  final bool isAuthorized;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const TableSelectionAppBar({
    Key? key,
    required this.userName,
    required this.userRoleId,
    required this.lottieController,
    required this.onLogout,
    required this.onCloseTable,
    required this.isAuthorized,
    required this.themeMode,
    required this.onToggleTheme,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeMode == ThemeMode.dark;
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userName != null)
            Text(
              "$userName ${_getRoleEmoji(userRoleId)}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
        ],
      ),
      toolbarHeight: 70,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuthorized)
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: onCloseTable,
                  child: Text(
                    "Masayı Kapat",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
          ],
        ),
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: TextButton(
            onPressed: onLogout,
            child: Text(
              "Çıkış Yap",
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            onToggleTheme();
            if (isDarkMode) {
              lottieController.reverse(from: 1.0);
            } else {
              lottieController.forward(from: 0.0);
            }
          },
          child: Lottie.asset(
            'lib/assets/animations/light_dark_mode_button.json',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
            controller: lottieController,
            repeat: false,
          ),
        ),
      ],
    );
  }
} 