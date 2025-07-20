class User {
  final int id;
  final String name;
  final String pinCode;
  final int userRoleId;

  User({
    required this.id,
    required this.name,
    required this.pinCode,
    required this.userRoleId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0, // null ise 0
      name: json['name']?.toString() ?? 'Unknown',
      pinCode: json['pinCode']?.toString() ?? '',
      userRoleId:
          json['userRole_Id'] ?? json['userRole']?['id'] ?? 0, // null ise 0
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, pinCode: $pinCode, userRoleId: $userRoleId)';
  }
}

class UserRole {
  final int id;
  final String name;
  final bool isAdmin;

  UserRole({required this.id, required this.name, required this.isAdmin});

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] ?? 0, // null ise 0
      name: json['name']?.toString() ?? 'Unknown',
      isAdmin: json['isAdmin'] ?? false, // null ise false
    );
  }

  @override
  String toString() {
    return 'UserRole(id: $id, name: $name, isAdmin: $isAdmin)';
  }
}
