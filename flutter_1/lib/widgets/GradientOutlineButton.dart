import 'package:flutter/material.dart';

class GradientOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GradientOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  static const _gradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 195, 36, 254),
      Color.fromARGB(255, 58, 30, 220),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            constraints: const BoxConstraints(minWidth: 96, minHeight: 30),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 13, 14, 34),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: ShaderMask(
              shaderCallback: _gradient.createShader,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
