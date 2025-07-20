/*import 'package:flutter/material.dart';
import 'package:sambapos_app_restorant/models/menu_item.dart';
import 'package:sambapos_app_restorant/models/ticket.dart';
import 'package:sambapos_app_restorant/services/api_service.dart';

class CalculatingScreen extends StatefulWidget {
  final String tableName;
  final int ticketId;

  const CalculatingScreen({Key? key, required this.tableName, required this.ticketId}) : super(key: key);

  @override
  _CalculatingScreenState createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends State<CalculatingScreen> {
  List<Map<String, dynamic>> _ticketItems = [];
  double _totalSelectedAmount = 0.0;
  double _totalOrderAmount = 0.0;
  double _remainingAmount = 0.0;
  List<Map<String, dynamic>> _selectedPayments = [];
  String? _selectedPaymentType;
  bool _isLoading = true;
  bool _hasSelectedItems = false;
  String? _error;
  TextEditingController _customPaymentController = TextEditingController();

  // Ödenen siparişleri saklamak için container
  List<Map<String, dynamic>> _paidOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchTicketItems();
  }

  Future<void> _fetchTicketItems() async {
    try {
      final ticketItems = await ApiService.getTicketItemsByTicketId(widget.ticketId);
      final menuItems = await ApiService.getMenuItems();
      final items = ticketItems.map((ticketItem) {
        final menuItem = menuItems.firstWhere(
              (item) => item.id == ticketItem.menuItemId,
          orElse: () => MenuItem(
            id: ticketItem.menuItemId,
            name: ticketItem.menuItemName,
            price: ticketItem.price,
            category: 'Genel',
            groupCode: 'Genel',
          ),
        );
        return {
          'menuItem': menuItem,
          'quantity': ticketItem.quantity,
          'portionName': ticketItem.portionName,
          'isSelected': false,
          'ticketItemDto': ticketItem, // TicketItemDto'yu da saklayalım
        };
      }).toList();

      setState(() {
        _ticketItems = items;
        _calculateTotalOrderAmount();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Sipariş bilgileri alınamadı: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateTotalOrderAmount() {
    final total = _ticketItems.fold<double>(
      0.0,
          (sum, item) {
        final menuItem = item['menuItem'] as MenuItem;
        final quantity = item['quantity'] as num;
        return sum + (menuItem.price * quantity);
      },
    );
    _totalOrderAmount = total;
    _calculateSelectedTotal();
  }

  void _toggleItemSelection(int index) {
    setState(() {
      _ticketItems[index]['isSelected'] = !_ticketItems[index]['isSelected'];
      _calculateSelectedTotal();
    });
  }

  void _calculateSelectedTotal() {
    _hasSelectedItems = _ticketItems.any((item) => item['isSelected'] == true);
    final selectedTotal = _ticketItems.fold<double>(
      0.0,
          (sum, item) {
        if (item['isSelected'] == true) {
          final menuItem = item['menuItem'] as MenuItem;
          final quantity = item['quantity'] as num;
          return sum + (menuItem.price * quantity);
        }
        return sum;
      },
    );
    _totalSelectedAmount = selectedTotal;

    final baseAmount = _totalSelectedAmount > 0 ? _totalSelectedAmount : _totalOrderAmount;
    _remainingAmount = baseAmount - _selectedPayments.fold<double>(0.0, (sum, p) => sum + p['amount']);
    if (_remainingAmount < 0) _remainingAmount = 0.0;
  }

  void _applyPayment(double percentage) {
    if (_selectedPaymentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir ödeme türü seçin!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final baseAmount = _totalSelectedAmount > 0 ? _totalSelectedAmount : _totalOrderAmount;
      final paymentAmount = baseAmount * (percentage / 100);

      _remainingAmount -= paymentAmount;
      if (_remainingAmount < 0) _remainingAmount = 0.0;

      _selectedPayments.add({
        'amount': paymentAmount,
        'type': _selectedPaymentType,
      });
      _selectedPaymentType = null;
    });
  }

  void _applyCustomPayment() {
    final value = double.tryParse(_customPaymentController.text);
    if (value != null && value >= 0) {
      if (_selectedPaymentType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen bir ödeme türü seçin!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _remainingAmount -= value;
        if (_remainingAmount < 0) _remainingAmount = 0.0;
        _selectedPayments.add({
          'amount': value,
          'type': _selectedPaymentType,
        });
        _selectedPaymentType = null;
        _customPaymentController.clear();
      });
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir ödeme miktarı girin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addPaymentAmount(double amount) {
    if (_selectedPaymentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir ödeme türü seçin!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _remainingAmount -= amount;
      if (_remainingAmount < 0) _remainingAmount = 0.0;
      _selectedPayments.add({
        'amount': amount,
        'type': _selectedPaymentType,
      });
      _selectedPaymentType = null;
    });
  }

  void _selectPaymentType(String type) {
    setState(() {
      _selectedPaymentType = type;
    });
  }

  void _roundAmount() {
    setState(() {
      _remainingAmount = _remainingAmount.roundToDouble();
    });
  }

  void _resetPayments() {
    setState(() {
      final baseAmount = _totalSelectedAmount > 0 ? _totalSelectedAmount : _totalOrderAmount;
      _remainingAmount = baseAmount;
      _selectedPayments.clear();
      _selectedPaymentType = null;
    });
  }

  void _printReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fiş yazdırılıyor... (Placeholder)')),
    );
  }

  void _completePayment() {
    final totalPaid = _selectedPayments.fold<double>(0.0, (sum, p) => sum + (p['amount'] as double));

    if (totalPaid == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir ödeme yapın!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Seçili öğeleri belirleme (eğer hiç seçili yoksa tümü)
    List<Map<String, dynamic>> itemsToPay = [];
    bool hasSelectedItems = _ticketItems.any((item) => item['isSelected'] == true);

    if (hasSelectedItems) {
      // Sadece seçili öğeleri al
      itemsToPay = _ticketItems.where((item) => item['isSelected'] == true).toList();
    } else {
      // Hiç seçili yoksa tüm öğeleri al
      itemsToPay = List.from(_ticketItems);
    }

    // Ödenen siparişleri _paidOrders listesine ekle
    for (var item in itemsToPay) {
      final paidOrder = {
        'ticketId': widget.ticketId,
        'tableName': widget.tableName,
        'menuItem': item['menuItem'],
        'quantity': item['quantity'],
        'portionName': item['portionName'],
        'ticketItemDto': item['ticketItemDto'],
        'paymentAmount': (item['menuItem'] as MenuItem).price * (item['quantity'] as num),
        'paymentTypes': List.from(_selectedPayments),
        'paidAt': DateTime.now(),
      };
      _paidOrders.add(paidOrder);
    }

    // Seçili öğeleri _ticketItems'dan kaldır
    setState(() {
      if (hasSelectedItems) {
        _ticketItems.removeWhere((item) => item['isSelected'] == true);
      } else {
        _ticketItems.clear();
      }
      _calculateTotalOrderAmount();
      _selectedPayments.clear();
      _selectedPaymentType = null;
    });

    // Ödenen siparişleri yazdır
    _printPaidOrders();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ödeme tamamlandı: ${_selectedPayments.map((p) => "${p['type']} ile ${p['amount'].toStringAsFixed(2)} ₺").join(", ")}' +
              (_remainingAmount > 0 ? ' (Kalan: ${_remainingAmount.toStringAsFixed(2)} ₺)' : ''),
        ),
      ),
    );

    // Eğer tüm öğeler ödendiyse ana ekrana dön
    if (_ticketItems.isEmpty) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _printPaidOrders() {
    print("=== ÖDENEN SİPARİŞLER ===");
    for (int i = 0; i < _paidOrders.length; i++) {
      final order = _paidOrders[i];
      final menuItem = order['menuItem'] as MenuItem;
      final ticketItemDto = order['ticketItemDto'] as TicketItemDto;

      print("Ödeme ${i + 1}:");
      print("  Masa: ${order['tableName']}");
      print("  Ticket ID: ${order['ticketId']}");
      print("  Menu Item ID: ${menuItem.id}");
      print("  Ürün Adı: ${menuItem.name}");
      print("  Kategori: ${menuItem.category}");
      print("  Grup Kodu: ${menuItem.groupCode}");
      print("  Birim Fiyat: ${menuItem.price} ₺");
      print("  Miktar: ${order['quantity']}");
      print("  Porsiyon: ${order['portionName']}");
      print("  Toplam Tutar: ${order['paymentAmount']} ₺");
      print("  Ödeme Türleri: ${order['paymentTypes']}");
      print("  Ödeme Zamanı: ${order['paidAt']}");
      print("  TicketItem CreatedDateTime: ${ticketItemDto.createdDateTime}");
      print("  TicketItem CreatingUserId: ${ticketItemDto.creatingUserId}");
      print("  TicketItem DepartmentId: ${ticketItemDto.departmentId}");
      print("  ---");
    }
    print("=== TOPLAM ${_paidOrders.length} SİPARİŞ ÖDENDİ ===");
  }

  void _showCustomPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Özel Ödeme Miktarı'),
        content: TextField(
          controller: _customPaymentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Ödeme Miktarı (₺)',
            hintText: 'Örn: 15',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: _applyCustomPayment,
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.tableName} Ödeme İşlemleri"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ödenen Siparişler'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: _paidOrders.map((order) {
                        final menuItem = order['menuItem'] as MenuItem;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "${menuItem.name} x${order['quantity']} - ${order['paymentAmount']} ₺",
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 18, color: Colors.red),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${widget.tableName} Sipariş Detayları",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_paidOrders.isNotEmpty)
                  Chip(
                    label: Text("${_paidOrders.length} ödendi"),
                    backgroundColor: Colors.green.shade100,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_ticketItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    "Tüm siparişler ödendi!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ticketItems.length,
                itemBuilder: (context, index) {
                  final item = _ticketItems[index];
                  final menuItem = item['menuItem'] as MenuItem;
                  final quantity = item['quantity'] as num;
                  return CheckboxListTile(
                    title: Text(menuItem.name),
                    subtitle: Text("Adet: $quantity - Porsiyon: ${item['portionName']}"),
                    secondary: Text(
                      "₺${(menuItem.price * quantity).toStringAsFixed(2)}",
                    ),
                    value: item['isSelected'],
                    onChanged: (value) => _toggleItemSelection(index),
                  );
                },
              ),
            if (_ticketItems.isNotEmpty) ...[
              const Divider(),
              Text(
                "Toplam Sipariş Tutarı: ₺${_totalOrderAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_totalSelectedAmount > 0) ...[
                Text(
                  "Seçilen Tutar: ₺${_totalSelectedAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
              Text(
                "Kalan Tutar: ₺${_remainingAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Ödeme Oranları",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _totalSelectedAmount > 0
                    ? "Seçili öğeler üzerinden oran uygulanacak"
                    : "Tüm sipariş üzerinden oran uygulanacak",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPaymentRatioButton("Tümü", 100),
                  _buildPaymentRatioButton("1/2", 50),
                  _buildPaymentRatioButton("1/4", 25),
                  _buildPaymentRatioButton("10%", 10),
                  _buildPaymentRatioButton("20%", 20),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Ödeme Miktarları",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPaymentButton(1),
                  _buildPaymentButton(5),
                  _buildPaymentButton(10),
                  _buildPaymentButton(20),
                  _buildPaymentButton(50),
                  _buildPaymentButton(200),
                  _buildPaymentButton(500),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Ödeme Türü",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPaymentTypeButton("Nakit"),
                  _buildPaymentTypeButton("Kredi Kartı"),
                  _buildPaymentTypeButton("Yemek Çeki"),
                  _buildPaymentTypeButton("Açık Hesap"),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Yapılan Ödemeler: ${_selectedPayments.map((p) => "${p['type']}: ${p['amount'].toStringAsFixed(2)} ₺").join(', ')}",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "Ödenen Toplam: ₺${_selectedPayments.fold<double>(0.0, (sum, p) => sum + (p['amount'] as double)).toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Ek İşlemler",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActionButton("Özel Ödeme", _showCustomPaymentDialog),
                  _buildActionButton("Yuvarla", _roundAmount),
                  _buildActionButton("Sıfırla", _resetPayments),
                  _buildActionButton("Hesap Yaz", _printReceipt),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Ödemeyi Tamamla",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "Geri Dön",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRatioButton(String label, double percentage) {
    return ElevatedButton(
      onPressed: () => _hasSelectedItems ? null : () => _applyPayment(percentage),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: const Size(80, 40),
      ),
      child: Text(label),
    );
  }

  Widget _buildPaymentButton(double amount) {
    return ElevatedButton(
      onPressed: () => _hasSelectedItems ? null : () => _addPaymentAmount(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        minimumSize: const Size(80, 40),
      ),
      child: Text("$amount ₺"),
    );
  }

  Widget _buildPaymentTypeButton(String type) {
    return ElevatedButton(
      onPressed: () => _selectPaymentType(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedPaymentType == type ? Colors.blue : Colors.grey,
        minimumSize: const Size(100, 40),
      ),
      child: Text(type),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        minimumSize: const Size(80, 40),
      ),
      child: Text(label),
    );
  }
}*/
// Flutter POS (Kasiyer Otomasyon) Odeme Ekrani - Tam Uyumlu---------------------------------------------------------------------------------------
/*import 'package:flutter/material.dart';

class CalculatingScreen extends StatefulWidget {
  final String tableName;
  final List<Map<String, dynamic>> orders; // menuItem, quantity, price

  const CalculatingScreen({required this.tableName, required this.orders, super.key});

  @override
  State<CalculatingScreen> createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends State<CalculatingScreen> {
  late List<Map<String, dynamic>> _orders;
  List<int> _selectedIndexes = [];
  List<Map<String, dynamic>> _payments = [];
  String? _selectedPaymentType;
  double _remainingAmount = 0.0;
  double _baseAmount = 0.0;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _orders = List.from(widget.orders);
    _calculateAmounts();
  }

  void _calculateAmounts() {
    double total = 0.0;
    final selectedItems = _selectedIndexes.isNotEmpty
        ? _selectedIndexes.map((i) => _orders[i])
        : _orders;

    for (var item in selectedItems) {
      total += (item['price'] * item['quantity']);
    }

    _baseAmount = total;
    final paid = _payments.fold(0.0, (sum, p) => sum + p['amount']);
    _remainingAmount = (_baseAmount - paid).clamp(0.0, double.infinity);
  }

  void _addPayment(double amount) {
    if (_selectedPaymentType == null) {
      _showMessage("Lütfen bir ödeme türü seçin.");
      return;
    }

    setState(() {
      _payments.add({'type': _selectedPaymentType, 'amount': amount});
      _calculateAmounts();
    });
  }

  void _completePayment() {
    if (_payments.isEmpty) {
      _showMessage("Lütfen bir ödeme yapın.");
      return;
    }

    setState(() {
      if (_selectedIndexes.isNotEmpty) {
        _selectedIndexes.sort((a, b) => b.compareTo(a));
        for (var i in _selectedIndexes) {
          _orders.removeAt(i);
        }
        _selectedIndexes.clear();
      } else {
        _orders.clear();
      }

      final description = "\u00d6deme tamamland\u0131. " +
          _payments.map((p) => "${p['amount']} ${p['type']}").join(", ") +
          ". Kalan: ${_remainingAmount.toStringAsFixed(2)} ₺";
      _payments.clear();
      _selectedPaymentType = null;
      _calculateAmounts();
      _showMessage(description);
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedIndexes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text("${widget.tableName} - Ödeme")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, i) {
                  final item = _orders[i];
                  final isSelected = _selectedIndexes.contains(i);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIndexes.add(i);
                        } else {
                          _selectedIndexes.remove(i);
                        }
                        _calculateAmounts();
                      });
                    },
                    title: Text(item['name']),
                    subtitle: Text("Adet: ${item['quantity']}"),
                    secondary: Text("${(item['price'] * item['quantity']).toStringAsFixed(2)} ₺"),
                  );
                },
              ),
            ),
            Text("Toplam: ${_baseAmount.toStringAsFixed(2)} ₺"),
            Text("Kalan: ${_remainingAmount.toStringAsFixed(2)} ₺", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Ödeme Türü"),
            Wrap(
              spacing: 8,
              children: ["Nakit", "Kart", "Yemek Çeki", "Açık Hesap"].map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _selectedPaymentType == type,
                  onSelected: (_) => setState(() => _selectedPaymentType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: hasSelection ? null : () => _addPayment(_baseAmount),
                  child: const Text("Tümü"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: hasSelection ? null : () => _addPayment(_baseAmount * 0.5),
                  child: const Text("Yarısı"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Özel Ödeme"),
                        content: TextField(
                          controller: _customAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: "Tutar girin"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("İptal"),
                          ),
                          TextButton(
                            onPressed: () {
                              final val = double.tryParse(_customAmountController.text);
                              if (val != null) _addPayment(val);
                              _customAmountController.clear();
                              Navigator.pop(context);
                            },
                            child: const Text("Ekle"),
                          )
                        ],
                      ),
                    );
                  },
                  child: const Text("Özel Tutar"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _completePayment,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("Ödemeyi Tamamla"),
            )
          ],
        ),
      ),
    );
  }
}*/

/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sambapos_app_restorant/models/menu_item.dart';
import 'package:sambapos_app_restorant/models/ticket.dart';
import 'package:sambapos_app_restorant/services/api_service.dart';

class CalculatingScreen extends StatefulWidget {
  final String tableName;
  final int ticketId;

  const CalculatingScreen({Key? key, required this.tableName, required this.ticketId}) : super(key: key);

  @override
  _CalculatingScreenState createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends State<CalculatingScreen> {
  List<Map<String, dynamic>> _ticketItems = [];
  List<Map<String, dynamic>> _selectedPayments = [];
  List<Map<String, dynamic>> _paidOrders = [];
  List<int> _selectedItemIndexes = [];

  String? _selectedPaymentType;
  double _totalOrderAmount = 0.0;
  double _selectedItemsAmount = 0.0;
  double _paidAmount = 0.0;
  double _remainingAmount = 0.0;
  double _changeAmount = 0.0;

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _receivedAmountController = TextEditingController();

  // Ödeme türleri
  final List<String> _paymentTypes = [
    'Nakit', 'Kredi Kartı', 'Banka Kartı', 'Yemek Çeki',
    'Sodexo', 'Multinet', 'Açık Hesap', 'Havale/EFT'
  ];

  @override
  void initState() {
    super.initState();
    _fetchTicketItems();
  }

  Future<void> _fetchTicketItems() async {
    try {
      final ticketItems = await ApiService.getTicketItemsByTicketId(
          widget.ticketId);
      final menuItems = await ApiService.getMenuItems();

      final items = ticketItems.map((ticketItem) {
        final menuItem = menuItems.firstWhere(
              (item) => item.id == ticketItem.menuItemId,
          orElse: () =>
              MenuItem(
                id: ticketItem.menuItemId,
                name: ticketItem.menuItemName,
                price: ticketItem.price,
                category: 'Genel',
                groupCode: 'Genel',
              ),
        );
        return {
          'menuItem': menuItem,
          'quantity': ticketItem.quantity,
          'portionName': ticketItem.portionName,
          'ticketItemDto': ticketItem,
          'unitPrice': menuItem.price,
          'totalPrice': menuItem.price * ticketItem.quantity,
        };
      }).toList();

      setState(() {
        _ticketItems = items;
        _calculateAmounts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Sipariş bilgileri alınamadı: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateAmounts() {
    // Toplam sipariş tutarı
    _totalOrderAmount =
        _ticketItems.fold<double>(0.0, (sum, item) => sum + item['totalPrice']);

    // Seçili öğelerin tutarı
    _selectedItemsAmount = _selectedItemIndexes.fold<double>(0.0, (sum, index) {
      return sum + _ticketItems[index]['totalPrice'];
    });

    // Toplam ödenen tutar
    _paidAmount = _selectedPayments.fold<double>(
        0.0, (sum, payment) => sum + payment['amount']);

    // Kalan tutar hesaplama
    final baseAmount = _selectedItemIndexes.isNotEmpty
        ? _selectedItemsAmount
        : _totalOrderAmount;
    _remainingAmount = (baseAmount - _paidAmount).clamp(0.0, double.infinity);

    // Para üstü hesaplama (ödenen tutar fazlaysa)
    _changeAmount = _paidAmount > baseAmount ? _paidAmount - baseAmount : 0.0;
  }

  void _toggleItemSelection(int index) {
    setState(() {
      if (_selectedItemIndexes.contains(index)) {
        _selectedItemIndexes.remove(index);
      } else {
        _selectedItemIndexes.add(index);
      }
      _calculateAmounts();
    });
  }

  void _selectAllItems() {
    setState(() {
      _selectedItemIndexes =
          List.generate(_ticketItems.length, (index) => index);
      _calculateAmounts();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItemIndexes.clear();
      _calculateAmounts();
    });
  }

  void _addPayment(double amount) {
    if (_selectedPaymentType == null) {
      _showErrorMessage('Lütfen bir ödeme türü seçin!');
      return;
    }

    if (amount <= 0) {
      _showErrorMessage('Geçerli bir tutar girin!');
      return;
    }

    setState(() {
      _selectedPayments.add({
        'type': _selectedPaymentType!,
        'amount': amount,
        'timestamp': DateTime.now(),
      });
      _calculateAmounts();
    });

    // Ödeme türü seçimini temizle
    _selectedPaymentType = null;
  }

  void _addPercentagePayment(double percentage) {
    final baseAmount = _selectedItemIndexes.isNotEmpty
        ? _selectedItemsAmount
        : _totalOrderAmount;
    final amount = baseAmount * (percentage / 100);
    _addPayment(amount);
  }

  void _addFullPayment() {
    _addPayment(_remainingAmount);
  }

  void _removePayment(int index) {
    setState(() {
      _selectedPayments.removeAt(index);
      _calculateAmounts();
    });
  }

  void _clearAllPayments() {
    setState(() {
      _selectedPayments.clear();
      _calculateAmounts();
    });
  }

  void _showCustomAmountDialog() {
    _customAmountController.clear();
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Özel Tutar Girin'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customAmountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tutar (₺)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Kalan Tutar: ${_remainingAmount.toStringAsFixed(2)} ₺'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(_customAmountController.text);
                  if (amount != null && amount > 0) {
                    _addPayment(amount);
                    Navigator.pop(context);
                  } else {
                    _showErrorMessage('Geçerli bir tutar girin!');
                  }
                },
                child: const Text('Ekle'),
              ),
            ],
          ),
    );
  }

  void _showReceivedAmountDialog() {
    _receivedAmountController.clear();
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Alınan Tutar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _receivedAmountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Müşteriden Alınan Tutar (₺)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.money),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Kalan Tutar: ${_remainingAmount.toStringAsFixed(2)} ₺'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final receivedAmount = double.tryParse(
                      _receivedAmountController.text);
                  if (receivedAmount != null && receivedAmount > 0) {
                    _addPayment(_remainingAmount);
                    Navigator.pop(context);

                    // Para üstü hesaplama
                    final change = receivedAmount - _remainingAmount;
                    if (change > 0) {
                      _showChangeDialog(change);
                    }
                  } else {
                    _showErrorMessage('Geçerli bir tutar girin!');
                  }
                },
                child: const Text('Hesapla'),
              ),
            ],
          ),
    );
  }

  void _showChangeDialog(double change) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Para Üstü'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.money, size: 48, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Para Üstü: ${change.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }

  void _completePayment() async {
    if (_selectedPayments.isEmpty) {
      _showErrorMessage('Lütfen en az bir ödeme yapın!');
      return;
    }

    if (_remainingAmount > 0.01) {
      _showErrorMessage(
          'Ödeme tamamlanmamış! Kalan tutar: ${_remainingAmount.toStringAsFixed(
              2)} ₺');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Ödenen siparişleri belirleme
      List<Map<String, dynamic>> itemsToPay = _selectedItemIndexes.isNotEmpty
          ? _selectedItemIndexes.map((index) => _ticketItems[index]).toList()
          : List.from(_ticketItems);

      // Ödenen siparişleri kaydetme
      for (var item in itemsToPay) {
        _paidOrders.add({
          'ticketId': widget.ticketId,
          'tableName': widget.tableName,
          'menuItem': item['menuItem'],
          'quantity': item['quantity'],
          'portionName': item['portionName'],
          'ticketItemDto': item['ticketItemDto'],
          'unitPrice': item['unitPrice'],
          'totalPrice': item['totalPrice'],
          'payments': List.from(_selectedPayments),
          'paidAt': DateTime.now(),
        });
      }

      // Ödenen öğeleri listeden kaldırma
      setState(() {
        if (_selectedItemIndexes.isNotEmpty) {
          _selectedItemIndexes.sort((a, b) => b.compareTo(a));
          for (var index in _selectedItemIndexes) {
            _ticketItems.removeAt(index);
          }
          _selectedItemIndexes.clear();
        } else {
          _ticketItems.clear();
        }

        _selectedPayments.clear();
        _selectedPaymentType = null;
        _calculateAmounts();
        _isProcessing = false;
      });

      // Başarı mesajı
      _showSuccessMessage('Ödeme başarıyla tamamlandı!');

      // Fiş yazdır
      await _printReceipt();

      // Eğer tüm öğeler ödendiyse ana ekrana dön
      if (_ticketItems.isEmpty) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorMessage('Ödeme işlemi sırasında hata oluştu: $e');
    }
  }

  Future<void> _printReceipt() async {
    // TODO: Gerçek yazıcı entegrasyonu
    await Future.delayed(const Duration(seconds: 1));
    _showSuccessMessage('Fiş yazdırıldı!');
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _receivedAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('${widget.tableName} - Hesap'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showPaidOrdersDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReceipt(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchTicketItems(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      )
          : Row(
        children: [
          // Sol Panel - Sipariş Listesi
          Expanded(
            flex: 3,
            child: _buildOrderList(),
          ),
          // Sağ Panel - Ödeme İşlemleri
          Expanded(
            flex: 2,
            child: _buildPaymentPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sipariş Detayları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _selectAllItems,
                      icon: const Icon(Icons.select_all, size: 16),
                      label: const Text('Tümünü Seç'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearSelection,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Seçimi Temizle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Sipariş Listesi
          Expanded(
            child: _ticketItems.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Tüm siparişler ödendi!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _ticketItems.length,
              itemBuilder: (context, index) {
                final item = _ticketItems[index];
                final menuItem = item['menuItem'] as MenuItem;
                final isSelected = _selectedItemIndexes.contains(index);

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) => _toggleItemSelection(index),
                    title: Text(
                      menuItem.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Porsiyon: ${item['portionName']}'),
                        Text('Birim Fiyat: ${item['unitPrice'].toStringAsFixed(
                            2)} ₺'),
                        Text('Adet: ${item['quantity']}'),
                      ],
                    ),
                    secondary: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Toplam', style: TextStyle(fontSize: 12)),
                        Text(
                          '${item['totalPrice'].toStringAsFixed(2)} ₺',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Hesap Özeti
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Hesap Özeti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildAmountRow(
                    'Toplam Tutar', _totalOrderAmount, Colors.black),
                if (_selectedItemIndexes.isNotEmpty)
                  _buildAmountRow(
                      'Seçilen Tutar', _selectedItemsAmount, Colors.blue),
                _buildAmountRow('Ödenen Tutar', _paidAmount, Colors.green),
                const Divider(),
                _buildAmountRow(
                    'Kalan Tutar', _remainingAmount, Colors.red, isLarge: true),
                if (_changeAmount > 0)
                  _buildAmountRow(
                      'Para Üstü', _changeAmount, Colors.orange, isLarge: true),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ödeme Türü Seçimi
                  const Text(
                    'Ödeme Türü',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paymentTypes.map((type) {
                      final isSelected = _selectedPaymentType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPaymentType = selected ? type : null;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Hızlı Ödeme Butonları
                  const Text(
                    'Hızlı Ödeme',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _remainingAmount > 0
                              ? _addFullPayment
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Tam Ödeme'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _remainingAmount > 0 ? () =>
                              _addPercentagePayment(50) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Yarım Ödeme'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Sabit Tutar Butonları
                  const Text(
                    'Sabit Tutarlar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [5, 10, 20, 50, 100, 200].map((amount) {
                      return SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          onPressed: () => _addPayment(amount.toDouble()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text('$amount ₺'),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Özel Tutarlar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showCustomAmountDialog,
                          icon: const Icon(Icons.edit),
                          label: const Text('Özel Tutar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedPaymentType == 'Nakit'
                              ? _showReceivedAmountDialog
                              : null,
                          icon: const Icon(Icons.calculate),
                          label: const Text('Para Üstü'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Yapılan Ödemeler
                  const Text(
                    'Yapılan Ödemeler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedPayments.isEmpty
                        ? const Center(
                      child: Text(
                        'Henüz ödeme yapılmamış',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      itemCount: _selectedPayments.length,
                      itemBuilder: (context, index) {
                        final payment = _selectedPayments[index];
                        return ListTile(
                          dense: true,
                          title: Text(payment['type']),
                          subtitle: Text(
                              '${payment['amount'].toStringAsFixed(2)} ₺'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removePayment(index),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // İşlem Butonları
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedPayments.isNotEmpty
                              ? _clearAllPayments
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Ödemeleri Temizle'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _printReceipt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Fiş Yazdır'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Ödeme Tamamla Butonu
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _completePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _remainingAmount <= 0.01
                            ? Colors.green
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'ÖDEMEYİ TAMAMLA',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, Color color,
      {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ₺',
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaidOrdersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödenen Siparişler'),
        content: Container(
          width: double.maxFinite,
          child: _paidOrders.isEmpty
              ? const Text('Henüz ödenen sipariş yok.')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: _paidOrders.length,
            itemBuilder: (context, index) {
              final order = _paidOrders[index];
              final menuItem = order['menuItem'] as MenuItem;
              return ListTile(
                title: Text(menuItem.name),
                subtitle: Text('Adet: ${order['quantity']}'),
                trailing: Text('${order['totalPrice'].toStringAsFixed(2)} ₺'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}*/
