import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_1/pages/LoginPage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_1/state/AuthController.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('http://10.247.240.85:8000/api/register/');
    final body = {
      "username": _usernameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      setState(() => _isLoading = false);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // If your register API also returns a token, log them in immediately
        if (data['token'] != null) {
          context.read<AuthController>().setAuth(
            token: data['token'],
            username: data['username'],
            userType: data['user_type'],
          );
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        } else {
          // Otherwise, send them back to login
          _showSuccess("Account created! Please login.");
          Navigator.pop(context);
        }
      } else {
        _showError(data['message'] ?? "Registration failed");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Connection error");
    }
  }

  void _showError(String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red));
  }

  void _showSuccess(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color.fromARGB(255, 13, 14, 34)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Added scroll view for smaller screens
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // === CIRCLE VISUAL ===
                    Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 102, 25, 144),
                            Color.fromARGB(255, 56, 22, 177),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_add_outlined,
                          color: Color.fromARGB(255, 197, 37, 255),
                          size: 60,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // === USERNAME ===
                    _buildField(_usernameController, "Username", Icons.person),
                    const SizedBox(height: 16),

                    // === EMAIL ===
                    _buildField(
                      _emailController,
                      "Email",
                      Icons.email,
                      isEmail: true,
                    ),
                    const SizedBox(height: 16),

                    // === PASSWORD ===
                    _buildField(
                      _passwordController,
                      "Password",
                      Icons.lock,
                      isPassword: true,
                    ),

                    const SizedBox(height: 32),

                    // === REGISTER BUTTON ===
                    _buildSubmitButton(),

                    const SizedBox(height: 16),

                    // === BACK TO LOGIN ===
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return SizedBox(
      width: 300,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(hint, icon),
        validator: (v) {
          if (v == null || v.isEmpty) return "Enter $hint";
          if (isEmail && !v.contains('@')) return "Enter a valid email";
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
            onTap: _isLoading ? null : _register,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Register",
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
