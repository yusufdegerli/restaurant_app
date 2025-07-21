import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambapos_app_restorant/services/api_service.dart';
import 'package:sambapos_app_restorant/screens/table_selection_screen.dart';
import 'package:sambapos_app_restorant/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final userData = await ApiService.login(_pinController.text.trim());
      Navigator.pop(context);
      if (userData != null) {
        authProvider.login(
          userData['userId'],
          userData['roleName'] ?? 'Bilinmiyor',
          userData['userName'],
          userData['userRoleId'],
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => TableSelectionScreen()),
              (Route<dynamic> route) => false,
            );
          }
        });
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Giriş başarısız. PIN veya rol geçersiz.")),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Hata oluştu: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(labelText: "PIN Kodu"),
                validator: (value) => (value == null || value.isEmpty) ? "PIN kodu gereklidir" : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _handleLogin, child: const Text("Giriş Yap")),
            ],
          ),
        ),
      ),
    );
  }
}