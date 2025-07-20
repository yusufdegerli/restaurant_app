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

class _CalculatingScreenState extends State<CalculatingScreen> with SingleTickerProviderStateMixin {
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

  late TabController _tabController;

  // Ödeme türleri
  final List<String> _paymentTypes = [
    'Nakit', 'Kredi Kartı', 'Banka Kartı', 'Yemek Çeki',
    'Sodexo', 'Multinet', 'Açık Hesap', 'Havale/EFT'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTicketItems();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _receivedAmountController.dispose();
    _tabController.dispose();
    super.dispose();
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
    _totalOrderAmount = _ticketItems.fold<double>(0.0, (sum, item) => sum + item['totalPrice']);
    _selectedItemsAmount = _selectedItemIndexes.fold<double>(0.0, (sum, index) => sum + _ticketItems[index]['totalPrice']);
    _paidAmount = _selectedPayments.fold<double>(0.0, (sum, payment) => sum + payment['amount']);
    final baseAmount = _selectedItemIndexes.isNotEmpty ? _selectedItemsAmount : _totalOrderAmount;
    _remainingAmount = (baseAmount - _paidAmount).clamp(0.0, double.infinity);
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
      _selectedItemIndexes = List.generate(_ticketItems.length, (index) => index);
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
      _selectedPayments.add({'type': _selectedPaymentType!, 'amount': amount, 'timestamp': DateTime.now()});
      _calculateAmounts();
    });
    _selectedPaymentType = null;
  }

  void _addPercentagePayment(double percentage) {
    final baseAmount = _selectedItemIndexes.isNotEmpty ? _selectedItemsAmount : _totalOrderAmount;
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
      builder: (context) => AlertDialog(
        title: const Text('Özel Tutar Girin'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Tutar (₺)', hintText: '0.00', prefixIcon: Icon(Icons.attach_money)),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
          ),
          const SizedBox(height: 16),
          Text('Kalan Tutar: ${_remainingAmount.toStringAsFixed(2)} ₺'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
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
      builder: (context) => AlertDialog(
        title: const Text('Alınan Tutar'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _receivedAmountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Müşteriden Alınan Tutar (₺)', hintText: '0.00', prefixIcon: Icon(Icons.money)),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
          ),
          const SizedBox(height: 16),
          Text('Kalan Tutar: ${_remainingAmount.toStringAsFixed(2)} ₺'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final receivedAmount = double.tryParse(_receivedAmountController.text);
              if (receivedAmount != null && receivedAmount > 0) {
                _addPayment(_remainingAmount);
                Navigator.pop(context);
                final change = receivedAmount - _remainingAmount;
                if (change > 0) _showChangeDialog(change);
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
      builder: (context) => AlertDialog(
        title: const Text('Para Üstü'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.money, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          Text('Para Üstü: ${change.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
      ),
    );
  }

  void _completePayment() async {
    if (_selectedPayments.isEmpty) {
      _showErrorMessage('Lütfen en az bir ödeme yapın!');
      return;
    }
    if (_remainingAmount > 0.01) {
      _showErrorMessage('Ödeme tamamlanmamış! Kalan tutar: ${_remainingAmount.toStringAsFixed(2)} ₺');
      return;
    }
    setState(() => _isProcessing = true);
    try {
      List<Map<String, dynamic>> itemsToPay = _selectedItemIndexes.isNotEmpty
          ? _selectedItemIndexes.map((index) => _ticketItems[index]).toList()
          : List.from(_ticketItems);
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
      setState(() {
        if (_selectedItemIndexes.isNotEmpty) {
          _selectedItemIndexes.sort((a, b) => b.compareTo(a));
          for (var index in _selectedItemIndexes) _ticketItems.removeAt(index);
          _selectedItemIndexes.clear();
        } else {
          _ticketItems.clear();
        }
        _selectedPayments.clear();
        _selectedPaymentType = null;
        _calculateAmounts();
        _isProcessing = false;
      });
      _showSuccessMessage('Ödeme başarıyla tamamlandı!');
      await _printReceipt();
      if (_ticketItems.isEmpty) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorMessage('Ödeme işlemi sırasında hata oluştu: $e');
    }
  }

  Future<void> _printReceipt() async {
    await Future.delayed(const Duration(seconds: 1));
    _showSuccessMessage('Fiş yazdırıldı!');
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)));
  }

  Widget _buildOrderList(BuildContext context, bool isDark) {
    return ListView.builder(
      itemCount: _ticketItems.length,
      itemBuilder: (context, index) {
        final item = _ticketItems[index];
        final menuItem = item['menuItem'] as MenuItem;
        final isSelected = _selectedItemIndexes.contains(index);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) => _toggleItemSelection(index),
          title: Text(menuItem.name, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black)),
          subtitle: Text('Porsiyon: ${item['portionName']} - Adet: ${item['quantity']} - Birim Fiyat: ${item['unitPrice'].toStringAsFixed(2)} ₺', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          secondary: Text('${item['totalPrice'].toStringAsFixed(2)} ₺', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[400])),
          activeColor: Theme.of(context).colorScheme.primary,
          checkColor: isDark ? Colors.black : Colors.white,
        );
      },
    );
  }

  Widget _buildPaymentPanel(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountRow('Toplam Tutar', _totalOrderAmount, isDark ? Colors.white : Colors.black),
          if (_selectedItemIndexes.isNotEmpty) _buildAmountRow('Seçilen Tutar', _selectedItemsAmount, Colors.blue),
          _buildAmountRow('Ödenen Tutar', _paidAmount, Colors.green),
          const Divider(),
          _buildAmountRow('Kalan Tutar', _remainingAmount, Colors.red, isLarge: true),
          if (_changeAmount > 0) _buildAmountRow('Para Üstü', _changeAmount, Colors.orange, isLarge: true),
          const SizedBox(height: 16),
          Text('Ödeme Türü', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          Wrap(spacing: 8, runSpacing: 8, children: _paymentTypes.map((type) {
            final isSelected = _selectedPaymentType == type;
            return ChoiceChip(
              label: Text(type, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              onSelected: (selected) => setState(() => _selectedPaymentType = selected ? type : null),
            );
          }).toList()),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: _remainingAmount > 0 ? _addFullPayment : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Tam Ödeme'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: _remainingAmount > 0 ? () => _addPercentagePayment(50) : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Yarım Ödeme'))),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [5, 10, 20, 50, 100, 200].map((amount) => SizedBox(width: 80, child: ElevatedButton(onPressed: () => _addPayment(amount.toDouble()), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)), child: Text('$amount ₺')))).toList()),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: _showCustomAmountDialog, icon: const Icon(Icons.edit), label: const Text('Özel Tutar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(onPressed: _selectedPaymentType == 'Nakit' ? _showReceivedAmountDialog : null, icon: const Icon(Icons.calculate), label: const Text('Para Üstü'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)))),
          ]),
          const SizedBox(height: 16),
          Text('Yapılan Ödemeler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          Container(height: 120, decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)), child: _selectedPayments.isEmpty
              ? Center(child: Text('Henüz ödeme yapılmamış', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)))
              : ListView.builder(itemCount: _selectedPayments.length, itemBuilder: (context, index) {
                final payment = _selectedPayments[index];
                return ListTile(dense: true, title: Text(payment['type'], style: TextStyle(color: isDark ? Colors.white : Colors.black)), subtitle: Text('${payment['amount'].toStringAsFixed(2)} ₺', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removePayment(index)));
              })),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: _selectedPayments.isNotEmpty ? _clearAllPayments : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Ödemeleri Temizle'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: _printReceipt, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Fiş Yazdır'))),
          ]),
          const SizedBox(height: 16),
          SizedBox(height: 50, child: ElevatedButton(onPressed: _isProcessing ? null : _completePayment, style: ElevatedButton.styleFrom(backgroundColor: _remainingAmount <= 0.01 ? Colors.green : Colors.grey, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('ÖDEMEYİ TAMAMLA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, Color color, {bool isLarge = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: isLarge ? 16 : 14, fontWeight: isLarge ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white : Colors.black)),
        Text('${amount.toStringAsFixed(2)} ₺', style: TextStyle(fontSize: isLarge ? 16 : 14, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  void _showPaidOrdersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödenen Siparişler'),
        content: Container(width: double.maxFinite, child: _paidOrders.isEmpty
            ? const Text('Henüz ödenen sipariş yok.')
            : ListView.builder(shrinkWrap: true, itemCount: _paidOrders.length, itemBuilder: (context, index) {
          final order = _paidOrders[index];
          final menuItem = order['menuItem'] as MenuItem;
          return ListTile(title: Text(menuItem.name), subtitle: Text('Adet: ${order['quantity']}'), trailing: Text('${order['totalPrice'].toStringAsFixed(2)} ₺'));
        })),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${widget.tableName} - Hesap'),
        backgroundColor: isDark ? const Color(0xFF23242B) : Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Sipariş Detayları'), Tab(text: 'Ödeme İşlemleri')],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () => _showPaidOrdersDialog()),
          IconButton(icon: const Icon(Icons.print), onPressed: () => _printReceipt()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 16, color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _fetchTicketItems(), child: const Text('Tekrar Dene')),
        ]),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(context, isDark),
          SingleChildScrollView(child: _buildPaymentPanel(context, isDark)),
        ],
      ),
    );
  }
}