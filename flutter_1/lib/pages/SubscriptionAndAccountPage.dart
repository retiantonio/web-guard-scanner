import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_1/state/AuthController.dart';

class SubscriptionAndAccountPage extends StatefulWidget {
  const SubscriptionAndAccountPage({super.key});

  @override
  State<SubscriptionAndAccountPage> createState() =>
      _SubscriptionAndAccountPageState();
}

class _SubscriptionAndAccountPageState
    extends State<SubscriptionAndAccountPage> {
  final Color highlightColor = const Color.fromARGB(255, 197, 37, 255);
  final Color backgroundColor = const Color.fromARGB(255, 32, 23, 49);

  @override
  void initState() {
    super.initState();
  }

  String _getPlanName(String? userType) {
    return userType == "PRO" ? "Professional" : "Standard";
  }

  Color _getPlanColor(String? userType) {
    return userType == "PRO" ? Colors.amber : Colors.blue;
  }

  Future<void> _upgradePlan(BuildContext context, String token) async {
    try {
      final Map<String, dynamic> requestBody = {"user_type": "PRO"};

      final res = await http.post(
        Uri.parse('http://10.247.240.85:8000/api/change-plan/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(requestBody),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (!mounted) return;

        context.read<AuthController>().setAuth(
          token: token,
          username: context.read<AuthController>().username,
          userType: data['user_type'] ?? 'PRO',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully upgraded to Professional!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Server error: ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upgrade failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(color: Colors.white);
    const headerStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Account & Subscription",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        // === GRADIENT ADDED HERE ===
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 195, 36, 254),
                Color.fromARGB(255, 58, 30, 220),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<AuthController>(
            builder: (context, authController, _) {
              final userType = authController.userType;
              final planName = _getPlanName(userType);
              final planColor = _getPlanColor(userType);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Account", style: headerStyle),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: highlightColor.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _infoRow("Username", authController.username ?? "N/A"),
                        const SizedBox(height: 12),
                        _infoRow("Account Type", planName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text("Subscription", style: headerStyle),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: highlightColor.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Current Plan", style: textStyle),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: planColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: planColor),
                              ),
                              child: Text(
                                planName,
                                style: TextStyle(
                                  color: planColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (userType != "PRO")
                          ElevatedButton(
                            onPressed: () async {
                              final token = authController.token;
                              if (token != null)
                                await _upgradePlan(context, token);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: highlightColor,
                              foregroundColor: Colors
                                  .white, // White text looks better on this purple
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text("Upgrade to Professional"),
                          )
                        else
                          _proBadge(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text("More", style: headerStyle),
                  _settingsTile("Privacy Policy"),
                  _settingsTile("Terms of Service"),
                  _settingsTile("Help & Support"),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _settingsTile(String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Icon(Icons.chevron_right, color: highlightColor),
      onTap: () {},
    );
  }

  Widget _proBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: const Center(
        child: Text(
          "✓ Professional Subscriber",
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
