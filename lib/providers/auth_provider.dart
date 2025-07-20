import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  int? _userId;
  int? _userRoleId;
  String? _userName;
  String? _roleName;

  bool get isAuthenticated => _isAuthenticated;
  int? get userId => _userId;
  int? get userRoleId => _userRoleId;
  String? get roleName => _roleName;
  String? get userName => _userName;

  void login(int userId, String roleName, String userName, int userRoleId) {
    _isAuthenticated = true;
    _userId = userId;
    _roleName = roleName;
    _userName = userName;
    _userRoleId = userRoleId;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _userId = null;
    _userRoleId = null;
    _userName = null;
    _roleName = null;
    notifyListeners();
  }
}