import 'package:flutter/material.dart';

class WinnerBanner extends StatelessWidget {
  final String winner;

  const WinnerBanner({super.key, required this.winner});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: Text(
        '$winner wins',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
    );
  }
}
