import 'package:flutter/material.dart';
import 'package:sambapos_app_restorant/models/menu_item.dart';

class OrderMenuGrid extends StatelessWidget {
  final List<MenuItem> items;
  final void Function(MenuItem item) onItemTap;
  const OrderMenuGrid({Key? key, required this.items, required this.onItemTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double width = constraints.maxWidth;
        if (width > 1200) {
          crossAxisCount = 5;
        } else if (width > 900) {
          crossAxisCount = 4;
        } else if (width > 600) {
          crossAxisCount = 3;
        }
        return GridView.builder(
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          cacheExtent: 500,
          padding: const EdgeInsets.all(8),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () => onItemTap(item),
              child: Card(
                child: Center(
                  child: Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
} 