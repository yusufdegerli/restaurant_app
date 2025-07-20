import 'package:flutter/material.dart';
import 'package:sambapos_app_restorant/models/menu_item.dart';

class OrderListView extends StatelessWidget {
  final Map<MenuItem, int> groupedItems;
  final void Function(MenuItem item) onDelete;
  const OrderListView({Key? key, required this.groupedItems, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final entry = groupedItems.entries.elementAt(index);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          dense: true,
          visualDensity: VisualDensity.compact,
          minVerticalPadding: 0,
          title: Text(
            "${entry.key.name} x${entry.value}",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            "₺${(entry.key.price * entry.value).toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => onDelete(entry.key),
          ),
        );
      },
    );
  }
} 