import 'package:flutter/material.dart';
import 'package:sambapos_app_restorant/models/table.dart';
import 'package:sambapos_app_restorant/screens/calculating_table_screen.dart';

class CloseTableScreen extends StatelessWidget {
  final List<RestaurantTable> tables;

  const CloseTableScreen({Key? key, required this.tables}) : super(key: key);

  void _navigateToCalculatingScreen(BuildContext context, String tableName, int ticketId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CalculatingScreen(tableName: tableName, ticketId: ticketId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Masayı Kapat")),
      body: tables.isEmpty
          ? const Center(child: Text("Kapatılacak masa bulunmamaktadır.", style: TextStyle(fontSize: 18)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return GestureDetector(
                  onTap: () => _navigateToCalculatingScreen(context, table.name, table.ticketId),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        table.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}