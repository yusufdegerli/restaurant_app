import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambapos_app_restorant/models/table.dart';
import 'package:sambapos_app_restorant/providers/order_provider.dart';
import 'package:sambapos_app_restorant/widgets/animated_table_button.dart';

class TableCategorySection extends StatelessWidget {
  final Map<String, List<RestaurantTable>> groupedTables;
  final Map<String, GlobalKey> tableKeys;
  final bool isMovingTable;
  final String? sourceTable;
  final void Function(RestaurantTable table, Color buttonColor) onTableTap;
  final void Function(RestaurantTable table, BuildContext context, Offset offset) onTableLongPress;

  const TableCategorySection({
    Key? key,
    required this.groupedTables,
    required this.tableKeys,
    required this.isMovingTable,
    required this.sourceTable,
    required this.onTableTap,
    required this.onTableLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: groupedTables.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final table = entry.value[index];
                tableKeys.putIfAbsent(table.name, () => GlobalKey());
                return TableGridButton(
                  table: table,
                  tableKey: tableKeys[table.name]!,
                  isMovingTable: isMovingTable,
                  sourceTable: sourceTable,
                  onTap: onTableTap,
                  onLongPress: (context, offset) => onTableLongPress(table, context, offset),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }
}

class TableGridButton extends StatelessWidget {
  final RestaurantTable table;
  final GlobalKey tableKey;
  final bool isMovingTable;
  final String? sourceTable;
  final void Function(RestaurantTable table, Color buttonColor) onTap;
  final void Function(BuildContext context, Offset offset) onLongPress;

  const TableGridButton({
    Key? key,
    required this.table,
    required this.tableKey,
    required this.isMovingTable,
    required this.sourceTable,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        if (orderProvider == null) {
          return const Text("OrderProvider bulunamadı.");
        }
        final hasOrder = orderProvider.hasOrder(table.name);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final buttonColor = isMovingTable && table.name == sourceTable
            ? Colors.purple
            : (table.ticketId != 0 || hasOrder)
                ? (isDarkMode ? Color(0xFF1B3562) : Color(0xFFE67C25))
                : (isDarkMode ? Color(0xFF566571) : Color(0xFFF8E4BF));

        return AnimatedTableButton(
          buttonKey: tableKey,
          isOccupied: table.ticketId != 0 || hasOrder,
          buttonColor: buttonColor,
          onTap: () => onTap(table, buttonColor),
          onLongPress: () {
            final box = tableKey.currentContext?.findRenderObject() as RenderBox?;
            if (box != null) {
              final offset = box.localToGlobal(Offset.zero);
              onLongPress(context, offset);
            }
          },
          child: Center(
            child: Text(
              table.name,
              style: TextStyle(
                color: isMovingTable && table.name == sourceTable
                    ? Colors.white
                    : (table.ticketId != 0 || hasOrder)
                        ? (isDarkMode ? Color(0xFFF2F2F2) : Color(0xFFFFFFFF))
                        : (isDarkMode ? Color(0xFFF2F2F2) : Color(0xFF555F70)),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
} 