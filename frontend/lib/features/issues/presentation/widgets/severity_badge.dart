import 'package:flutter/material.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final normalized = severity.toUpperCase().trim();
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (normalized) {
      case 'CRITICAL':
        bgColor = const Color(0xFFFFE4E6); // Rose 100
        textColor = const Color(0xFFBE123C); // Rose 700
        icon = Icons.warning_rounded;
        break;
      case 'HIGH':
        bgColor = const Color(0xFFFEE2E2); // Red 100
        textColor = const Color(0xFFDC2626); // Red 600
        icon = Icons.priority_high;
        break;
      case 'MEDIUM':
        bgColor = const Color(0xFFFEF3C7); // Amber 100
        textColor = const Color(0xFFD97706); // Amber 600
        icon = Icons.swap_vert;
        break;
      case 'LOW':
      default:
        bgColor = const Color(0xFFF1F5F9); // Slate 100
        textColor = const Color(0xFF475569); // Slate 600
        icon = Icons.arrow_downward;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            normalized,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
