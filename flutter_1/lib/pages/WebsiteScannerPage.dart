import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_1/state/ScoreController.dart';
import 'package:flutter_1/widgets/GradientOutlineButton.dart';
import 'package:flutter_1/pages/MainMenuPage.dart';

String formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    // Format like: 12 Jan 2026 16:32:08
    return '${dt.day.toString().padLeft(2, '0')} '
        '${_monthName(dt.month)} '
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso; // fallback if parsing fails
  }
}

String _monthName(int month) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month];
}

List<Widget> buildVulnerabilities(List vulnerabilities) {
  final List<Widget> widgets = [];

  for (int i = 0; i < vulnerabilities.length; i++) {
    final vuln = vulnerabilities[i];

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '• Vulnerability ${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    widgets.addAll([
      _kv('Type', vuln['type']),
      _kv('Severity', vuln['severity']),
      _kv('URL Found', vuln['url_found']),
    ]);

    final findings = vuln['details']?['findings'];
    if (findings is List && findings.isNotEmpty) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 6, bottom: 4),
          child: Text(
            'Findings:',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

      for (final f in findings) {
        widgets.addAll([
          _kv('Parameter', f['parameter'], indent: 32),
          _kv('Payload', f['payload'], indent: 32),
          _kv('Description', f['description'], indent: 32),
          const SizedBox(height: 8),
        ]);
      }
    }

    widgets.add(const SizedBox(height: 12));
  }

  return widgets;
}

Widget _kv(String key, dynamic value, {double indent = 16}) {
  return Padding(
    padding: EdgeInsets.only(left: indent, bottom: 4),
    child: Text(
      '• $key: $value',
      style: const TextStyle(color: Colors.grey, fontSize: 14),
    ),
  );
}

class WebsiteScannerPage extends StatefulWidget {
  final List<String> modulesSelected;
  final int targetId;
  final String token;

  const WebsiteScannerPage({
    super.key,
    required this.modulesSelected,
    required this.targetId,
    required this.token,
  });

  @override
  State<WebsiteScannerPage> createState() => _ScanningPageState();
}

class _ScanningPageState extends State<WebsiteScannerPage> {
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _paused = false;
  bool _scanFinished = false;
  Map<String, dynamic>? _scanResult;
  int? _scanId;

  @override
  void initState() {
    super.initState();

    // start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || _scanFinished) return;
      setState(() {
        _elapsedSeconds++;
      });
    });

    // start scan + polling
    _startScan(
      token: widget.token,
      targetId: widget.targetId,
      modulesSelected: widget.modulesSelected,
    );
  }

  Future<void> _startScan({
    required String token,
    required int targetId,
    required List<String> modulesSelected,
  }) async {
    setState(() {
      _paused = false;
      _scanFinished = false;
      _scanResult = null;
    });

    try {
      // 1. Start the scan
      final startResponse = await ApiService.startWebsiteScan(
        token: token,
        targetId: targetId,
        modules: modulesSelected,
      );

      final scanId = startResponse['id'];
      if (scanId is! int) {
        throw Exception('Invalid scan id returned from server');
      }

      _scanId = scanId;

      // 2. Poll the server every 5 seconds until scan is completed
      while (mounted) {
        final result = await ApiService.getScanStatus(
          token: token,
          scanId: _scanId!,
        );

        if (result['status'] == 'COMPLETED') {
          final score = result['score'];

          if (score is int) {
            context.read<ScoreController>().setScore(score.toDouble());
          }

          setState(() {
            _scanFinished = true;
            _paused = true;
            _scanResult = result;
          });
          break;
        }

        // wait 5 seconds before polling again
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paused = true;
          _scanFinished = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during scan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get formattedTime {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String formatModuleName(String module) {
    return module
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color.fromARGB(255, 13, 14, 34)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scanFinished ? 'Scan Completed' : 'Scanning',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Tabs and indicator (unchanged)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'Scan',
                                style: TextStyle(
                                  color: !_scanFinished
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Report',
                                style: TextStyle(
                                  color: _scanFinished
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 2,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              alignment: _scanFinished
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 195, 36, 254),
                                        Color.fromARGB(255, 58, 30, 220),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: Row(
                    children: [
                      // Left panel: timer
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 102, 25, 144),
                                    Color.fromARGB(255, 56, 22, 177),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.qr_code_rounded,
                                color: Color.fromARGB(255, 197, 37, 255),
                                size: 90,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Time elapsed',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right panel: scan summary / result
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                !_scanFinished
                                    ? 'Scan in progress'
                                    : 'Scan summary',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Display selected modules + result dynamically
                              if (_scanResult == null && !_scanFinished)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: widget.modulesSelected
                                      .map(
                                        (m) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            '• ${formatModuleName(m)}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                )
                              else if (_scanResult != null)
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _kv('Score', _scanResult!['score']),
                                        _kv('Status', _scanResult!['status']),
                                        _kv(
                                          'Target URL',
                                          _scanResult!['target_url'],
                                        ),
                                        const SizedBox(height: 12),

                                        // Display formatted start and end times
                                        if (_scanResult!['start_time'] != null)
                                          _kv(
                                            'Start Time',
                                            formatDate(
                                              _scanResult!['start_time'],
                                            ),
                                          ),
                                        if (_scanResult!['end_time'] != null)
                                          _kv(
                                            'End Time',
                                            formatDate(
                                              _scanResult!['end_time'],
                                            ),
                                          ),

                                        // Optional: display date field as-is or formatted
                                        if (_scanResult!['date'] != null)
                                          _kv('Date', _scanResult!['date']),

                                        const SizedBox(height: 12),

                                        // Vulnerabilities
                                        if (_scanResult!['vulnerabilities']
                                                is List &&
                                            _scanResult!['vulnerabilities']
                                                .isNotEmpty)
                                          ...buildVulnerabilities(
                                            _scanResult!['vulnerabilities'],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 32),

                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _scanFinished
                                      ? [
                                          // Remove View report button completely
                                          GradientOutlineButton(
                                            text: 'Done',
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                          const SizedBox(width: 16),
                                        ]
                                      : [
                                          GradientOutlineButton(
                                            text: _paused ? 'Resume' : 'Pause',
                                            onPressed: () => setState(
                                              () => _paused = !_paused,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          GradientOutlineButton(
                                            text: 'Cancel',
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          const SizedBox(width: 16),
                                        ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
