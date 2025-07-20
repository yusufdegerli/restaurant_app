import 'package:flutter/material.dart';
import 'package:sambapos_app_restorant/models/table.dart';
import 'package:sambapos_app_restorant/services/cache_service.dart';
import 'package:provider/provider.dart';
import 'package:sambapos_app_restorant/providers/order_provider.dart';

Future<void> handleTableMove({
  required BuildContext context,
  required String? sourceTable,
  required RestaurantTable targetTable,
  required List<RestaurantTable> tables,
  required void Function(void Function()) setState,
  required void Function(List<RestaurantTable>) updateTables,
  required void Function(Map<String, List<RestaurantTable>>) updateGroupedTables,
}) async {
  if (sourceTable == null) {
    showError(context, 'Kaynak masa seçilmemiş!');
    return;
  }
  final cacheService = CacheService();
  final sourceTableObj = cacheService.getTableByName(sourceTable);
  final targetTableObj = cacheService.getTableByName(targetTable.name);
  if (sourceTableObj == null || targetTableObj == null) {
    showError(context, 'Masa bilgileri alınamadı!');
    return;
  }
  final sourceTableId = sourceTableObj.id;
  final targetTableId = targetTableObj.id;
  final ticketId = sourceTableObj.ticketId;
  if (ticketId == 0) {
    showError(context, 'Kaynak masa ($sourceTable) için bilet bulunamadı!');
    return;
  }
  final orderProvider = Provider.of<OrderProvider>(context, listen: false);
  if (!orderProvider.hasOrder(sourceTable)) {
    showError(context, 'Kaynak masa ($sourceTable) için sipariş bulunamadı!');
    return;
  }
  try {
    await cacheService.moveTicket(sourceTableId, targetTableId, ticketId);
    orderProvider.moveOrder(sourceTable, targetTable.name);
    final newTables = tables.map((t) {
      if (t.id == sourceTableId) {
        return RestaurantTable(
          id: t.id,
          name: t.name,
          order: t.order,
          category: t.category,
          ticketId: 0,
        );
      }
      if (t.id == targetTableId) {
        return RestaurantTable(
          id: t.id,
          name: t.name,
          order: t.order,
          category: t.category,
          ticketId: ticketId,
        );
      }
      return t;
    }).toList();
    updateTables(newTables);
    updateGroupedTables(_groupTablesByCategory(newTables));
    showSuccess(context, 'Sipariş $sourceTable → ${targetTable.name} taşındı.');
  } catch (e) {
    showError(context, 'Taşıma işlemi başarısız: $e');
  }
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red),
  );
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.green),
  );
}

Map<String, List<RestaurantTable>> _groupTablesByCategory(List<RestaurantTable> tables) {
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