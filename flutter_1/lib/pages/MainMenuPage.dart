import 'package:flutter/material.dart';
import 'package:flutter_1/pages/WebsiteScannerPage.dart';
import 'package:flutter_1/widgets/IconTextButton.dart';
import 'package:flutter_1/widgets/SemicircleScore.dart';
import 'package:flutter_1/pages/SubscriptionAndAccountPage.dart';
import 'package:flutter_1/pages/ScanningHistoryPage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_1/state/ScoreController.dart';
import 'package:flutter_1/state/AuthController.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

String formatModuleName(String module) {
  return module
      .replaceAll('-', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

List<Widget> buildPrettyOutputWidgets(dynamic output, {int indent = 0}) {
  final List<Widget> widgets = [];

  if (output is Map) {
    output.forEach((k, v) {
      if (v is Map || v is List) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: indent.toDouble()),
            child: Text(
              '• ${formatModuleName(k.toString())}:',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        );
        widgets.addAll(buildPrettyOutputWidgets(v, indent: indent + 16));
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: indent.toDouble()),
            child: Text(
              '• ${formatModuleName(k.toString())}: $v',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        );
      }
    });
  } else if (output is List) {
    for (var item in output) {
      if (item is Map || item is List) {
        widgets.addAll(buildPrettyOutputWidgets(item, indent: indent));
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: indent.toDouble()),
            child: Text(
              '• $item',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        );
      }
    }
  } else if (output is String) {
    final lines = output
        .split(RegExp(r'[,\n;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (var line in lines) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: indent.toDouble()),
          child: Text(
            '• $line',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }
  } else {
    widgets.add(
      Padding(
        padding: EdgeInsets.only(left: indent.toDouble()),
        child: Text(
          '• ${output.toString()}',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }

  return widgets;
}

class ApiService {
  static const baseUrl = 'http://10.247.240.85:8000/api';

  static Future<Map<String, dynamic>> startWebsiteScan({
    required String token,
    required int targetId,
    required List<String> modules,
  }) async {
    final payload = {'modules_selected': modules, 'target': targetId};

    final res = await http.post(
      Uri.parse('$baseUrl/scans/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Scan request failed: ${res.body}');
    }

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getScanStatus({
    required String token,
    required int scanId,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/scans/$scanId/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to get scan status: ${res.body}');
    }

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createTarget({
    required String token,
    required String name,
    required String url,
  }) async {
    final payload = {'name': name, 'url': url};

    debugPrint('POST $baseUrl/targets/');
    debugPrint('Authorization: Token $token');
    debugPrint('Payload: ${jsonEncode(payload)}');

    final res = await http.post(
      Uri.parse('$baseUrl/targets/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(payload),
    );

    debugPrint('Status: ${res.statusCode}');
    debugPrint('Response: ${res.body}');

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(res.body);
    }

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> startVersionDetection({
    required String token,
    required int targetId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/targets/$targetId/get_versions_and_engines/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode != 200 && res.statusCode != 202) {
      throw Exception(res.body);
    }

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> startWafDetection({
    required String token,
    required int targetId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/targets/$targetId/get_web_application_firewall/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode != 200 && res.statusCode != 202) {
      throw Exception(res.body);
    }

    return jsonDecode(res.body);
  }
}

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  Future<void> _showWebsiteScannerDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    bool isLoading = false;

    // 1. Determine if the user is PRO before showing/building the list
    final auth = context.read<AuthController>();
    final bool isPro = auth.userType == "PRO";

    final List<String> modules = [
      'recon-crawler',
      'waf-detection',
      'services-detection',
      'sqli',
      'xss-scanner',
      'xss-crawler',
    ];

    final Map<String, bool> selectedModules = {for (var m in modules) m: false};

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 20, 20, 40),
              title: const Text(
                'Website Scanner',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: urlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Target URL',
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: modules.map((module) {
                        // 2. Logic to disable 'recon-crawler' for non-pro users
                        bool isRecon = module == 'recon-crawler';
                        bool isDisabled = isRecon && !isPro;

                        return CheckboxListTile(
                          enabled: !isDisabled, // Greys out and prevents clicks
                          value: isDisabled ? false : selectedModules[module],
                          onChanged: isDisabled
                              ? null
                              : (val) {
                                  setState(() {
                                    selectedModules[module] = val ?? false;
                                  });
                                },
                          title: Text(
                            formatModuleName(module) +
                                (isDisabled ? " (PRO)" : ""),
                            style: TextStyle(
                              color: isDisabled ? Colors.grey : Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          secondary: isDisabled
                              ? const Icon(
                                  Icons.lock,
                                  color: Colors.grey,
                                  size: 20,
                                )
                              : null,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color.fromARGB(255, 195, 36, 254),
                          checkColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final url = urlController.text.trim();

                          // 1. Get the list of selected modules
                          final modulesSelected = selectedModules.entries
                              .where((e) => e.value)
                              .map((e) => e.key)
                              .toList();

                          // 2. Custom Logic: If Recon-Crawler is picked, force at least one more
                          bool hasRecon = modulesSelected.contains(
                            'recon-crawler',
                          );
                          bool onlyRecon =
                              hasRecon && modulesSelected.length == 1;

                          // 3. Updated Validation
                          if (name.isEmpty ||
                              url.isEmpty ||
                              modulesSelected.isEmpty ||
                              onlyRecon) {
                            // Provide feedback so the user knows why it won't start
                            String errorMsg = "Please fill all fields.";
                            if (onlyRecon) {
                              errorMsg =
                                  "Recon Crawler requires at least one other module to be selected.";
                            } else if (modulesSelected.isEmpty) {
                              errorMsg = "Please select at least one module.";
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMsg),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            final token = auth.token;
                            if (token == null) throw Exception('Not logged in');

                            final target = await ApiService.createTarget(
                              token: token,
                              name: name,
                              url: url,
                            );
                            final targetId = target['id'];

                            if (ctx.mounted) Navigator.pop(ctx);

                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WebsiteScannerPage(
                                  modulesSelected: modulesSelected,
                                  targetId: targetId,
                                  token: token,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (ctx.mounted) setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Start',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showVersionDetectorDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 20, 20, 40),
              title: const Text(
                'Version Detector',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Target URL',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          final auth = context.read<AuthController>();
                          final token = auth.token!;
                          final target = await ApiService.createTarget(
                            token: token,
                            name: nameController.text.trim(),
                            url: urlController.text.trim(),
                          );

                          final result = await ApiService.startVersionDetection(
                            token: token,
                            targetId: target['id'],
                          );

                          if (ctx.mounted) Navigator.pop(ctx);

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color.fromARGB(
                                255,
                                20,
                                20,
                                40,
                              ),
                              title: const Text(
                                'Version Detection Result',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: buildPrettyOutputWidgets(
                                    result['output'],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text(
                          'Start',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showWafDetectorDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 20, 20, 40),
              title: const Text(
                'WAF Detector',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Target URL',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          final auth = context.read<AuthController>();
                          final token = auth.token!;
                          final target = await ApiService.createTarget(
                            token: token,
                            name: nameController.text.trim(),
                            url: urlController.text.trim(),
                          );

                          final result = await ApiService.startWafDetection(
                            token: token,
                            targetId: target['id'],
                          );

                          if (ctx.mounted) Navigator.pop(ctx);

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color.fromARGB(
                                255,
                                20,
                                20,
                                40,
                              ),
                              title: const Text(
                                'WAF Detection Result',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: buildPrettyOutputWidgets(
                                    result['output'],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text(
                          'Start',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/appIcon.png', width: 64, height: 64),
            const Text(
              "WebGuard Scanner",
              style: TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: "Roboto Slab",
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 195, 36, 254),
                Color.fromARGB(255, 58, 30, 220),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        color: const Color.fromARGB(255, 32, 23, 49),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 350,
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        IconTextButton(
                          text: "Website Scanner",
                          icon: const Icon(Icons.search, color: Colors.white),
                          iconBackgroundColor: const Color.fromARGB(
                            255,
                            105,
                            25,
                            144,
                          ),
                          onPressed: () => _showWebsiteScannerDialog(context),
                        ),
                        const SizedBox(height: 33),
                        IconTextButton(
                          text: "Scanning History",
                          icon: const Icon(Icons.history, color: Colors.white),
                          iconBackgroundColor: const Color.fromARGB(
                            255,
                            35,
                            22,
                            127,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ScanHistoryPage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 33),
                        IconTextButton(
                          text: "Version Detector",
                          icon: const Icon(Icons.info, color: Colors.white),
                          iconBackgroundColor: const Color.fromARGB(
                            255,
                            99,
                            43,
                            129,
                          ),
                          onPressed: () => _showVersionDetectorDialog(context),
                        ),
                        const SizedBox(height: 33),
                        IconTextButton(
                          text: "Directory Brute-Forcing",
                          icon: const Icon(
                            Icons.folder_open,
                            color: Colors.white,
                          ),
                          iconBackgroundColor: const Color.fromARGB(
                            255,
                            65,
                            56,
                            125,
                          ),
                          onPressed: () {},
                        ),
                        const SizedBox(height: 33),
                        IconTextButton(
                          text: "WAF Detector",
                          icon: const Icon(Icons.security, color: Colors.white),
                          iconBackgroundColor: const Color.fromARGB(
                            255,
                            35,
                            22,
                            127,
                          ),
                          onPressed: () => _showWafDetectorDialog(context),
                        ),
                        const SizedBox(height: 33),
                        IconTextButton(
                          text: "Subscription and Account",
                          icon: const Icon(Icons.person, color: Colors.white),
                          iconBackgroundColor: const Color.fromARGB(
                            255,
                            69,
                            47,
                            87,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SubscriptionAndAccountPage(),
                              ),
                            );

                            if (result == true) {
                              context.read<ScoreController>().setSubscription(
                                true,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: ScoreWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
