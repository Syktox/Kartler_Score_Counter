import 'package:flutter/material.dart';

class ScoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Size minimumSize;
  final double fontSize;

  const ScoreButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.minimumSize = const Size(100, 80),
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(minimumSize: minimumSize),
      child: Text(label, style: TextStyle(fontSize: fontSize)),
    );
  }
}
