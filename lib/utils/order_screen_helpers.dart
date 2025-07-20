import 'package:flutter/material.dart';
import 'package:sambapos_app_restorant/models/menu_item.dart';
import 'package:provider/provider.dart';
import 'package:sambapos_app_restorant/providers/order_provider.dart';

List<MenuItem> filterMenuItems({
  required List<MenuItem> menuItems,
  required String searchText,
  required String selectedCategory,
}) {
  if (searchText.isNotEmpty) {
    return menuItems.where((item) => item.name.toLowerCase().contains(searchText.toLowerCase())).toList();
  } else if (selectedCategory.isNotEmpty) {
    return menuItems.where((item) => item.categories.contains(selectedCategory)).toList();
  } else {
    return menuItems;
  }
}

void showOrderError(BuildContext context, String message, VoidCallback onRetry) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Tekrar Dene',
        onPressed: onRetry,
      ),
    ),
  );
}

void updateOrderQuantity({
  required BuildContext context,
  required int newQuantity,
  required MenuItem? lastSelectedItem,
  required void Function(int) setCurrentQuantity,
}) {
  if (lastSelectedItem == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lütfen önce bir ürün seçin.")),
    );
    return;
  }
  final orderProvider = Provider.of<OrderProvider>(context, listen: false);
  for (int i = 0; i < newQuantity; i++) {
    orderProvider.addToOrder(lastSelectedItem);
  }
  setCurrentQuantity(newQuantity);
} 