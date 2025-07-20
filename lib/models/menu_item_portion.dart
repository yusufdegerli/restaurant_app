class MenuItemPortion {
  final int id;
  final int menuItemId;
  final String name;
  final double price;

  MenuItemPortion({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
  });

  factory MenuItemPortion.fromJson(Map<String, dynamic> json) {
    return MenuItemPortion(
      id: json['Id'] ?? 0,
      menuItemId: json['MenuItemId'] ?? 0,
      name: json['Name'] ?? '',
      price: (json['Price_Amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
