import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambapos_app_restorant/providers/auth_provider.dart';
import 'package:sambapos_app_restorant/providers/order_provider.dart';
import '../models/menu_item.dart';
import 'package:sambapos_app_restorant/widgets/animate_gradient_background.dart'; // Yeni widget'ı ekle

class PaymentScreen extends StatefulWidget {
  final String tableName;
  final double totalAmount;
  final List<MenuItem> selectedItems;
  final int ticketId;

  const PaymentScreen({
    Key? key,
    required this.tableName,
    required this.totalAmount,
    required this.selectedItems,
    this.ticketId = 0,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Gradient görünecek
        appBar: AppBar(title: Text("Ödeme - ${widget.tableName}")),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.tableName} MASASI",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Toplam Tutar: ₺${widget.totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Sipariş Notu',
                  border: OutlineInputBorder(),
                  hintText: 'Ek not yazabilirsiniz...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  setState(() => _isLoading = true);
                  try {
                    final userName = authProvider.userName ?? 'Bilinmiyor';
                    final userId = authProvider.userId?.toString() ?? '0';
                    context.read<OrderProvider>().completeOrder(
                      widget.tableName,
                      widget.selectedItems,
                      note: _noteController.text.isNotEmpty
                          ? _noteController.text
                          : "Not yok",
                      userId: userId,
                      userName: userName,
                    );
                    await orderProvider.completeOrderWithApi(
                      tableName: widget.tableName,
                      items: widget.selectedItems,
                      note: _noteController.text.isNotEmpty
                          ? _noteController.text
                          : "Not yok",
                      userName: userName,
                      userId: userId,
                      totalAmount: widget.totalAmount,
                      existingTicketId: widget.ticketId,
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Sipariş başarıyla gönderildi!"),
                      ),
                    );
                    Navigator.popUntil(context, (route) => route.isFirst);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Hata: ${e.toString()}")),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("SİPARİŞİ TAMAMLA"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Geri Dön"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}