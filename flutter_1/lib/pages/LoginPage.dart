import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_1/pages/MainMenuPage.dart';
import 'package:flutter_1/state/AuthController.dart';
import 'package:provider/provider.dart';
import 'package:flutter_1/pages/RegisterPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginScannerStylePageState();
}

class _LoginScannerStylePageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('http://10.14.245.85:8000/api/login/');
    final body = {
      "username": _usernameController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // === DEBUG PRINT SERVER RESPONSE ===
      debugPrint('--- LOGIN API RESPONSE ---');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('--------------------------');

      setState(() => _isLoading = false);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        context.read<AuthController>().setAuth(
          token: data['token'],
          username: data['username'],
          userType: data['user_type'],
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainMenuPage()),
          (route) => false,
        );
      } else {
        _showError(data['message'] ?? "Invalid credentials");
      }
    } catch (e) {
      // Log the error if the request fails completely (e.g., timeout)
      debugPrint('--- LOGIN API ERROR ---');
      debugPrint(e.toString());

      setState(() => _isLoading = false);
      if (!mounted) return;
      _showError("Connection error");
    }
  }

  void _showError(String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color.fromARGB(255, 13, 14, 34)),
        child: SafeArea(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === CIRCLE VISUAL (same style as WebsiteScannerPage) ===
                  Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color.fromARGB(255, 102, 25, 144),
                          Color.fromARGB(255, 56, 22, 177),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_outline,
                        color: Color.fromARGB(255, 197, 37, 255),
                        size: 70,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // === USERNAME ===
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Username", Icons.person),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter username" : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // === PASSWORD ===
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Password", Icons.lock),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter password" : null,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // === LOGIN BUTTON ===
                  SizedBox(
                    width: 300,
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 195, 36, 254),
                              Color.fromARGB(255, 58, 30, 220),
                            ],
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isLoading ? null : _login,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === GO TO REGISTER ===
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromARGB(255, 30, 32, 70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
