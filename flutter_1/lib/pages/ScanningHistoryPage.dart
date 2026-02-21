import 'package:flutter/material.dart';
import 'package:flutter_1/state/AuthController.dart';
import 'package:flutter_1/widgets/IconTextButton.dart';
import 'package:flutter_1/widgets/GradientOutlineButton.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

enum ScanType { directoryScan, versionDetect, directoryBruteforce, wafDetect }

class ApiService {
  static const baseUrl = 'http://10.14.245.85:8000/api';

  static Future<List<int>> fetchUserTargetIds({required String token}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/targets/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load targets: ${res.body}');
    }

    final List data = jsonDecode(res.body);
    return data.map<int>((t) => t['id'] as int).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchUserScans({
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/scans/'),
      headers: {
        'Authorization': 'Token $token', // <-- pass the token here too
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load scans: ${res.body}');
    }

    final List data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }
}

class ScanHistoryItem {
  final String id;
  final ScanType type;
  final DateTime date;
  final String summary;

  ScanHistoryItem({
    required this.id,
    required this.type,
    required this.date,
    required this.summary,
  });
}

class ScanHistoryPage extends StatefulWidget {
  const ScanHistoryPage({super.key});

  @override
  State<ScanHistoryPage> createState() => _ScanHistoryPageState();
}

class _ScanHistoryPageState extends State<ScanHistoryPage> {
  List<Map<String, dynamic>> scans = [];
  Map<String, dynamic>? selectedScan;

  final int currentUserId = 1;

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    try {
      final auth = context.read<AuthController>();
      final token = auth.token;
      if (token == null) throw Exception('User not logged in');

      final targetIds = await ApiService.fetchUserTargetIds(token: token);
      final allScans = await ApiService.fetchUserScans(token: token);

      final userScans = allScans
          .where((scan) => targetIds.contains(scan['target']))
          .where(
            (scan) =>
                (scan['status'] ?? '').toString().toUpperCase() != 'PENDING',
          )
          .toList();

      setState(() {
        scans = userScans;
        selectedScan = scans.isNotEmpty ? scans.first : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 13, 14, 34),
        padding: const EdgeInsets.all(32),
        child: Row(
          children: [
            SizedBox(
              width: 280,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 32, 23, 49),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: scans.length,
                        itemBuilder: (context, index) {
                          final scan = scans[index];
                          final isSelected = scan['id'] == selectedScan?['id'];
                          final String displayDate = formatDate(
                            scan['date'] ?? scan['start_time'],
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: IconTextButton(
                              text: 'Scan: $displayDate',
                              icon: const Icon(
                                Icons.security,
                                color: Colors.white,
                                size: 20,
                              ),
                              iconBackgroundColor: isSelected
                                  ? const Color.fromARGB(255, 195, 36, 254)
                                  : const Color.fromARGB(255, 58, 30, 220),
                              height: 56,
                              borderRadius: 14,
                              onPressed: () {
                                setState(() => selectedScan = scan);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(width: 24),

            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: selectedScan == null
                        ? const Center(
                            child: Text(
                              'Select a scan to view details',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : _ScanDetails(scan: selectedScan!),
                  ),

                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        // Check if scans list is not empty AND a scan is actually selected
                        if (scans.isNotEmpty && selectedScan != null) ...[
                          GradientOutlineButton(
                            text: 'See Details',
                            onPressed: () {
                              final vulns = List<Map<String, dynamic>>.from(
                                selectedScan?['vulnerabilities'] ?? [],
                              );
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(
                                    'Vulnerabilities JSON',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    20,
                                    20,
                                    40,
                                  ),
                                  content: SingleChildScrollView(
                                    child: Text(
                                      const JsonEncoder.withIndent(
                                        '  ',
                                      ).convert(vulns),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                        ],

                        // This button stays visible so the user can always exit the page
                        GradientOutlineButton(
                          text: 'Back to Main Menu',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanDetails extends StatelessWidget {
  final Map<String, dynamic> scan;

  const _ScanDetails({required this.scan});

  @override
  Widget build(BuildContext context) {
    final modules = List<String>.from(scan['modules_selected'] ?? []);
    final vulns = List<Map<String, dynamic>>.from(
      scan['vulnerabilities'] ?? [],
    );
    final proScan = modules.contains('recon-crawler');
    final score = scan['score'] ?? 'N/A';
    final date = formatDate(scan['date'] ?? scan['start_time']);
    final duration = formatDuration(scan['start_time'], scan['end_time']);
    final totalVulns = vulns.length;
    final topSeverity = highestSeverity(vulns);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score
          Text(
            'Score: $score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Date & Duration
          Text(
            'Date: $date',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          Text(
            'Duration: $duration',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Modules
          Text(
            proScan ? 'Pro Scan' : 'Standard Scan',
            style: TextStyle(
              color: proScan ? Colors.greenAccent : Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: modules
                .map(
                  (m) => Chip(
                    label: Text(
                      m,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: Colors.deepPurple,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          // Vulnerabilities summary
          Text(
            'Vulnerabilities: $totalVulns',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            'Highest Severity: $topSeverity',
            style: TextStyle(
              color: topSeverity == 'CRITICAL'
                  ? Colors.redAccent
                  : topSeverity == 'HIGH'
                  ? Colors.orangeAccent
                  : Colors.greenAccent,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

String highestSeverity(List vulnerabilities) {
  if (vulnerabilities.isEmpty) return 'N/A';

  final severities = {'INFO': 1, 'HIGH': 2, 'CRITICAL': 3};
  int maxValue = 1; // default to INFO

  for (var v in vulnerabilities) {
    final sev = v['severity'] ?? 'INFO';
    maxValue = math.max(maxValue, severities[sev] ?? 0);
  }

  // find the key matching maxValue
  return severities.entries
      .firstWhere((e) => e.value == maxValue, orElse: () => MapEntry('INFO', 1))
      .key;
}

String formatDuration(String? start, String? end) {
  if (start == null || end == null) return 'N/A';
  final startDt = DateTime.parse(start);
  final endDt = DateTime.parse(end);
  final duration = endDt.difference(startDt);
  return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
}

String formatDate(String? date) {
  if (date == null) return 'N/A';
  final dt = DateTime.parse(date);
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
