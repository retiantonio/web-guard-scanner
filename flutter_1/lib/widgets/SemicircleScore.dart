import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_1/pages/SubscriptionAndAccountPage.dart';
import 'package:flutter_1/state/ScoreController.dart';
import 'package:flutter_1/state/AuthController.dart'; // Ensure this path is correct
import 'package:provider/provider.dart';

class ScoreWidget extends StatefulWidget {
  const ScoreWidget({super.key});

  @override
  State<ScoreWidget> createState() => ScoreWidgetState();
}

class ScoreWidgetState extends State<ScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initial animation placeholder
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animation.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void animateScore(double newScore) {
    _animation = Tween<double>(begin: 0, end: newScore.clamp(0, 100)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final providerScore = context.watch<ScoreController>().score;

    // Only animate if the score changed significantly from the current animation value
    if ((_animation.value - providerScore).abs() > 0.1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) animateScore(providerScore);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen to ScoreController for the value
    final providerScore = context.watch<ScoreController>().score;

    // 2. Listen to AuthController for the subscription status
    final userType = context.watch<AuthController>().userType;
    final bool isPro = userType == "PRO";

    // Trigger initial animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_animationStarted) {
        animateScore(providerScore);
        _animationStarted = true;
      }
    });

    final score = _animation.value;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 13, 14, 34),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),

          // SCORE SEMICIRCLE + NUMBER
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
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            "Security Score",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {},
              child: const Text(
                "View More",
                style: TextStyle(
                  color: Color.fromARGB(255, 197, 37, 255),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // DECORATIVE GRADIENT LINE
          Container(
            width: double.infinity,
            height: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 195, 36, 254),
                  Color.fromARGB(255, 58, 30, 220),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // DYNAMIC TEXT BASED ON SUBSCRIPTION
          PaddedText(
            text: isPro
                ? "Enjoy the premium features of your subscription"
                : "Stay confident in your website's security",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.left,
          ),

          const SizedBox(height: 10),

          PaddedText(
            text: isPro
                ? "Your scans are automatically enhanced with professional features."
                : "Scan your subdomains automatically with every scan and much more",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.left,
          ),

          const SizedBox(height: 14),

          // DYNAMIC BUTTON BASED ON SUBSCRIPTION
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                // We navigate to the page. When the user upgrades there,
                // AuthController updates, and this widget will rebuild automatically.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionAndAccountPage(),
                  ),
                );
              },
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 195, 36, 254),
                        Color.fromARGB(255, 58, 30, 220),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                blendMode: BlendMode.srcIn,
                child: Center(
                  child: Text(
                    isPro
                        ? "You already have a subscription plan"
                        : "See professional subscription plan",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// === CUSTOM PAINTER ===
class SemiCirclePainter extends CustomPainter {
  final double score;
  SemiCirclePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 20.0;
    final rectSize = size.width * 0.7;
    final offset = (size.width - rectSize) / 2;
    final rect = Rect.fromLTWH(offset, offset, rectSize, rectSize);

    final totalSweepAngle = 29 * math.pi / 18;
    final startAngle = math.pi / 2 + (2 * math.pi - totalSweepAngle) / 2;

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

      final segments = (progressSweepAngle * 180 / math.pi).ceil().clamp(
        1,
        270,
      );
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

// === PADDED TEXT WIDGET ===
class PaddedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const PaddedText({super.key, required this.text, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Text(
        text,
        style: style ?? const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: textAlign ?? TextAlign.start,
        softWrap: true,
      ),
    );
  }
}
