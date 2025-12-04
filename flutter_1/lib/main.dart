import 'package:flutter/material.dart';

const double pi = 3.141592653589793;

final scoreKey = GlobalKey<_ScoreWidgetState>();

// Left Side Button Template
class IconTextButton extends StatelessWidget {
  final String text;
  final Color iconBackgroundColor;
  final Widget icon;
  final VoidCallback onPressed;
  final double height;
  final double borderRadius;

  const IconTextButton({
    super.key,
    required this.text,
    required this.icon,
    required this.iconBackgroundColor,
    required this.onPressed,
    this.height = 50,
    this.borderRadius = 16,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 13, 14, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          children: [
            Container(
              width: height * 0.6,
              height: height * 0.6,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipOval(child: icon),
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                text,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Semi-Circle Widget for Score
class ScoreWidget extends StatefulWidget {
  const ScoreWidget({super.key});

  @override
  State<ScoreWidget> createState() => _ScoreWidgetState();
}

class _ScoreWidgetState extends State<ScoreWidget>
    with SingleTickerProviderStateMixin {
  double score = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize the animation without a listener first
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Add the listener separately
    _animationController.addListener(() {
      setState(() {
        score = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void updateScore(double newScore) {
    final clampedScore = newScore.clamp(0.0, 100.0);
    _animation = Tween<double>(begin: score, end: clampedScore).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 13, 14, 34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 150),
                painter: SemiCirclePainter(score: score),
              ),
              Positioned(
                top: 75,
                child: Text(
                  '${score.toInt()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            "PLACEHOLDER",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => updateScore(100),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 105, 25, 144),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Simulate Scan",
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
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final double score;
  SemiCirclePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 24.0;

    final rectSize = size.width * 0.7;
    final offset = (size.width - rectSize) / 2;
    final rect = Rect.fromLTWH(offset, offset, rectSize, rectSize);

    final startAngle = 3 * pi / 4;
    const totalSweepAngle = 3 * pi / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, totalSweepAngle, false, backgroundPaint);

    final progressSweepAngle = totalSweepAngle * score / 100;

    if (score > 0) {
      const gradientColors = [
        Color.fromARGB(255, 58, 30, 220),
        Color.fromARGB(255, 195, 36, 254),
        Color.fromARGB(255, 58, 30, 220),
      ];

      final segments = (progressSweepAngle * 180 / pi).ceil().clamp(1, 270);
      final segmentAngle = progressSweepAngle / segments;

      for (int i = 0; i < segments; i++) {
        final normalizedPosition = i / 270;
        final color = _getGradientColor(gradientColors, normalizedPosition);

        final segmentPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = (i == 0 || i == segments - 1)
              ? StrokeCap.round
              : StrokeCap.butt;

        canvas.drawArc(
          rect,
          startAngle + (i * segmentAngle),
          segmentAngle,
          false,
          segmentPaint,
        );
      }
    }
  }

  Color _getGradientColor(List<Color> colors, double position) {
    final segmentCount = colors.length - 1;
    final scaledPosition = position * segmentCount;
    final segmentIndex = scaledPosition.floor().clamp(0, segmentCount - 1);
    final segmentPosition = scaledPosition - segmentIndex;

    final startColor = colors[segmentIndex];
    final endColor = colors[(segmentIndex + 1) % colors.length];

    return Color.lerp(startColor, endColor, segmentPosition)!;
  }

  @override
  bool shouldRepaint(covariant SemiCirclePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          elevation: 0,
          title: Row(
            children: [
              Image.asset('assets/appIcon.png', width: 64, height: 64),

              // TEXT
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
                          // LEFT SIDE PANEL Buttons
                          IconTextButton(
                            text: "Website scanner",
                            icon: const Icon(Icons.search, color: Colors.white),
                            iconBackgroundColor: const Color.fromARGB(
                              255,
                              105,
                              25,
                              144,
                            ),
                            onPressed: () =>
                                scoreKey.currentState?.updateScore(10),
                          ),

                          const SizedBox(height: 16),

                          IconTextButton(
                            text: "Scanning History",
                            icon: const Icon(
                              Icons.history,
                              color: Colors.white,
                            ),
                            iconBackgroundColor: const Color.fromARGB(
                              255,
                              35,
                              22,
                              127,
                            ),
                            onPressed: () =>
                                scoreKey.currentState?.updateScore(25),
                          ),

                          const SizedBox(height: 16),

                          IconTextButton(
                            text: "Version Detector",
                            icon: const Icon(Icons.info, color: Colors.white),
                            iconBackgroundColor: const Color.fromARGB(
                              255,
                              99,
                              43,
                              129,
                            ),
                            onPressed: () =>
                                scoreKey.currentState?.updateScore(40),
                          ),

                          const SizedBox(height: 16),

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
                            onPressed: () =>
                                scoreKey.currentState?.updateScore(55),
                          ),

                          const SizedBox(height: 16),

                          IconTextButton(
                            text: "WAF Detector",
                            icon: const Icon(
                              Icons.security,
                              color: Colors.white,
                            ),
                            iconBackgroundColor: const Color.fromARGB(
                              255,
                              35,
                              22,
                              127,
                            ),
                            onPressed: () =>
                                scoreKey.currentState?.updateScore(70),
                          ),

                          const SizedBox(height: 16),

                          IconTextButton(
                            text: "Subscription and Account",
                            icon: const Icon(Icons.person, color: Colors.white),
                            iconBackgroundColor: const Color.fromARGB(
                              255,
                              69,
                              47,
                              87,
                            ),
                            onPressed: () =>
                                scoreKey.currentState?.updateScore(85),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // RIGHT SIDE PANEL
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: ScoreWidget(key: scoreKey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
