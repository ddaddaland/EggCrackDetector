import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  final IconData icon;
  final String text;

  const Label(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 4,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white70,
        ),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
