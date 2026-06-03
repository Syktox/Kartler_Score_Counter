import 'package:flutter/material.dart';

class ScoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Size minimumSize;
  final double fontSize;
  final double? width;

  const ScoreButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.minimumSize = const Size(100, 80),
    this.fontSize = 24,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(minimumSize: minimumSize),
        child: Text(label, style: TextStyle(fontSize: fontSize)),
      ),
    );
  }
}
