import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambapos_app_restorant/models/menu_item_property_groups.dart';
import 'package:sambapos_app_restorant/providers/order_provider.dart';
import 'package:sambapos_app_restorant/services/api_service.dart';
import '../models/menu_item.dart';
import 'payment_screen.dart';
import 'dart:async';
import 'package:sambapos_app_restorant/animations/animated_overlay.dart';
import 'package:sambapos_app_restorant/widgets/order_category_tabbar.dart';
import 'package:sambapos_app_restorant/widgets/order_menu_grid.dart';
import 'package:sambapos_app_restorant/widgets/order_list_view.dart';
import 'package:sambapos_app_restorant/utils/order_screen_helpers.dart';
import 'package:sambapos_app_restorant/widgets/animate_gradient_background.dart';

class OrderScreen extends StatefulWidget {
  final String tableName;
  final int ticketId;

  const OrderScreen({Key? key, required this.tableName, this.ticketId = 0})
    : super(key: key);

  @override
  OrderScreenState createState() => OrderScreenState();
}

class OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  String _selectedCategory = "";
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  MenuItem? _lastSelectedItem;
  int _currentQuantity = 1;
  Map<int, int> _itemQuantities = {}; // item.id = quantity
  TabController? _tabController;
  String _searchText = '';
  OverlayEntry? _reverseOverlayEntry;
  bool _isPopping = false;
  bool _hideContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMenuItems();
      Provider.of<OrderProvider>(context, listen: false).clearOrder();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    showOrderError(context, message, _fetchMenuItems);
  }

  void _addToOrder(MenuItem item) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final quantity = _itemQuantities[item.id] ?? 1;

    for (int i = 0; i < quantity; i++) {
      orderProvider.addToOrder(item);
    }
    // orderProvider.addToOrder(item);
    setState(() {
      _lastSelectedItem = item;
      _itemQuantities[item.id] = 1;
    });
  }

  Future<void> _fetchMenuItems() async {
    try {
      final items = await loadMenuItemsWithVariants();
      if (!mounted) return;
      setState(() {
        _menuItems = items;
        _isLoading = false;
        if (categories.isNotEmpty) {
          _selectedCategory = categories.first;
          _tabController?.dispose();
          _tabController = TabController(length: categories.length, vsync: this);
          _tabController!.addListener(() {
            if (_tabController!.indexIsChanging) {
              setState(() {
                _selectedCategory = categories[_tabController!.index];
              });
            }
          });
        }
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
        "Sunucuya bağlanırken zaman aşımı oluştu. Lütfen tekrar deneyin.",
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print("🔥 StackTrace: $stackTrace");
      _showError("Menü yüklenirken hata oluştu: "+e.toString());
    }
  }

  List<String> get categories =>
      _menuItems.expand((e) => e.categories).toSet().toList();

  List<MenuItem> get filteredItems => filterMenuItems(
    menuItems: _menuItems,
    searchText: _searchText,
    selectedCategory: _selectedCategory,
  );

  void _updateQuantity(int newQuantity) {
    updateOrderQuantity(
      context: context,
      newQuantity: newQuantity,
      lastSelectedItem: _lastSelectedItem,
      setCurrentQuantity: (val) => setState(() => _currentQuantity = val),
    );
  }

  void _incrementQuantity() => _updateQuantity(_currentQuantity + 1);
  void _decrementQuantity() =>
      _currentQuantity > 1 ? _updateQuantity(_currentQuantity - 1) : null;

  double get _totalPrice {
    final orderProvider = Provider.of<OrderProvider>(context, listen: true);
    return orderProvider.selectedItems.fold(0, (sum, item) => sum + item.price);
  }

  Future<List<MenuItem>> loadMenuItemsWithVariants() async {
    final items = await ApiService.getMenuItems();
    final propertyGroups = await ApiService.getMenuItemPropertyGroups();
    final properties = await ApiService.getMenuItemProperties();

    return items.map((item) {
      // 1. Menü öğesinin adıyla aynı ada sahip propertyGroup var mı?
      final matchingGroup = propertyGroups.firstWhere(
        (group) =>
            group.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
        orElse:
            () => MenuItemPropertyGroup(
              id: -1,
              name: '',
              singleSelection: false,
              multipleSelection: false,
            ),
      );

      List<String> variants = [];
      bool hasVariants = false;
      bool singleSelection = false;
      bool multipleSelection = false;

      // 2. Grup id'si ile eşleşen property'leri bul
      variants =
          properties
              .where(
                (prop) => prop.menuItemPropertyGroupId == matchingGroup.id,
              )
              .map((e) => e.name)
              .toList();

      hasVariants = variants.isNotEmpty;
      singleSelection = matchingGroup.singleSelection;
      multipleSelection = matchingGroup.multipleSelection;

      return MenuItem(
        id: item.id,
        name: item.name,
        groupCode: item.groupCode,
        price: item.price,
        category: item.category,
        singleSelection: singleSelection,
        multipleSelection: multipleSelection,
        hasVariants: hasVariants,
        variants: variants,
        categories: item.categories,
      );
    }).toList();
  }

  void _showVariantsModal(MenuItem item) {
    if (item.variants.isEmpty) {
      _addToOrder(item);
      return;
    }

    final uniqueVariants = item.variants.toSet().toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.name} için seçenek seçin',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: uniqueVariants.map((variant) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        MenuItem modifiedItem = MenuItem(
                          id: "${item.id}_${variant}".hashCode,
                          name: "${item.name} ($variant)",
                          price: item.price,
                          groupCode: item.groupCode,
                          category: item.category,
                          singleSelection: item.singleSelection,
                          multipleSelection: item.multipleSelection,
                          hasVariants: item.hasVariants,
                          variants: item.variants,
                          categories: item.categories,
                        );
                        _addToOrder(modifiedItem);
                        Navigator.pop(context);
                      },
                      child: Text(variant),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_isPopping) return false;
    _isPopping = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final initialPosition = args?['initialPosition'] as Offset?;
    final initialSize = args?['initialSize'] as Size?;
    final buttonColor = args?['buttonColor'] as Color?;
    if (initialPosition != null && initialSize != null && buttonColor != null) {
      setState(() => _hideContent = true);
      _reverseOverlayEntry = OverlayEntry(
        builder: (context) => AnimatedOverlay(
          initialPosition: initialPosition,
          initialSize: initialSize,
          buttonColor: buttonColor,
          reverse: true,
          onAnimationComplete: () {
            _reverseOverlayEntry?.remove();
            _reverseOverlayEntry = null;
            Navigator.of(context).pop();
          },
        ),
      );
      Overlay.of(context, rootOverlay: true).insert(_reverseOverlayEntry!);
      // Animasyon bitince pop yapılacak, burada false dönüyoruz
      return false;
    } else {
      print('Ters animasyon için  gerekli argümanlar eksik!');
      // Pozisyon bilgisi yoksa normal pop
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return PopScope(
        canPop: false, //_onWillPop'a girecek
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            await _onWillPop();
          }
        },
        child: _hideContent
            ? Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              )
            : Scaffold(
                appBar: AppBar(
                  title: Text('${widget.tableName} - Sipariş'),
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23242B) : Colors.blue[800]),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                body: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          if (categories.isNotEmpty && _tabController != null && _searchText.isEmpty)
                            OrderCategoryTabBar(categories: categories, tabController: _tabController!),
                          // Arama Barı
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Ürün ara...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchText = val;
                                });
                              },
                            ),
                          ),
                          // Adet Seçimi
                          SizedBox(
                            height: 60,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Center(
                                    child: Text(
                                      "Adet: ",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _decrementQuantity,
                                  child: const Text("-"),
                                ),
                                ...List.generate(10, (index) => index + 1).map(
                                      (number) => ElevatedButton(
                                    onPressed: () => _updateQuantity(number),
                                    child: Text("$number"),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _incrementQuantity,
                                  child: const Text("+"),
                                ),
                              ],
                            ),
                          ),
                          // Menü Gridview
                          Expanded(
                            child: OrderMenuGrid(
                              items: filteredItems,
                              onItemTap: (item) {
                                if (item.hasVariants && item.variants.isNotEmpty) {
                                  _showVariantsModal(item);
                                } else {
                                  _addToOrder(item);
                                }
                              },
                            ),
                          ),
                          // Sipariş Listesi ve Ödeme Butonu
                          SizedBox(
                            height: 350,
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    "Siparişler",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    child: Provider.of<OrderProvider>(
                                      context,
                                      listen: true,
                                    ).selectedItems.isEmpty
                                        ? const Center(
                                            child: Text("Henüz sipariş eklenmedi"),
                                          )
                                        : OrderListView(
                                            groupedItems: Provider.of<OrderProvider>(
                                              context,
                                              listen: true,
                                            ).selectedItems.fold<Map<MenuItem, int>>(
                                              {},
                                              (map, item) {
                                                map[item] = (map[item] ?? 0) + 1;
                                                return map;
                                              },
                                            ),
                                            onDelete: (item) {
                                              final orderProvider = Provider.of<OrderProvider>(
                                                context,
                                                listen: false,
                                              );
                                              orderProvider.selectedItems.removeWhere(
                                                (i) => i.id == item.id,
                                              );
                                              // orderProvider.notifyListeners(); // Bunu kaldırıyoruz
                                              // Bunun yerine OrderProvider'a bir metot eklenmeli
                                              // Örneğin: orderProvider.removeItemAndUpdate(item);
                                              // Şimdilik sadece setState ile güncelliyoruz
                                              setState(() {});
                                            },
                                          ),
                                  ),
                                ),
                                if (Provider.of<OrderProvider>(
                                  context,
                                  listen: true,
                                ).selectedItems.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.amber[0x3238A5FF]
                                            : Theme.of(context).colorScheme.primary,
                                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.black
                                            : Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        final orderProvider =
                                            Provider.of<OrderProvider>(
                                          context,
                                          listen: false,
                                        );
                                        if (orderProvider.selectedItems.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Lütfen en az bir ürün seçin.",
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => PaymentScreen(
                                              tableName:
                                                  widget
                                                      .tableName, // ⇐ o masanın adı string
                                              totalAmount: _totalPrice,
                                              selectedItems:
                                                  orderProvider.selectedItems,
                                              ticketId: widget.ticketId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "SİPARİŞ AL (₺${_totalPrice.toStringAsFixed(2)})",
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
      );
    } catch (e, stackTrace) {
      print("Error in build: $e");
      print(stackTrace);
      return Scaffold(
        appBar: AppBar(title: Text("${widget.tableName} - Sipariş")),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Text(
            "Bir hata oluştu, lütfen tekrar deneyin.",
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }
  }
}
