import 'package:flutter/material.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 13, 14, 34),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 0, // IMPORTANT: remove default shadow
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
                padding: const EdgeInsets.all(4),
                child: ClipOval(child: icon),
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
      ),
    );
  }
}
