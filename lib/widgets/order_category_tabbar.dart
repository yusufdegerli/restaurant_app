import 'package:flutter/material.dart';

class OrderCategoryTabBar extends StatelessWidget {
  final List<String> categories;
  final TabController tabController;
  const OrderCategoryTabBar({Key? key, required this.categories, required this.tabController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      indicatorColor: Theme.of(context).colorScheme.primary,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.grey,
      tabs: categories.map((cat) => Tab(text: cat)).toList(),
    );
  }
} 