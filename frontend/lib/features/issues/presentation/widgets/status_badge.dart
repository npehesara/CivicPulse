import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase().trim();
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (normalized) {
      case 'RESOLVED':
        bgColor = const Color(0xFFDCFCE7); // Green 100
        textColor = const Color(0xFF15803D); // Green 700
        icon = Icons.check_circle_outline;
        break;
      case 'IN_PROGRESS':
      case 'IN PROGRESS':
      case 'INVESTIGATING':
        bgColor = const Color(0xFFE0F2FE); // Light Sky Blue
        textColor = const Color(0xFF0369A1); // Sky 700
        icon = Icons.pending_outlined;
        break;
      case 'REJECTED':
      case 'CANCELLED':
        bgColor = const Color(0xFFFEE2E2); // Red 100
        textColor = const Color(0xFFB91C1C); // Red 700
        icon = Icons.cancel_outlined;
        break;
      case 'REPORTED':
      default:
        bgColor = const Color(0xFFFEF3C7); // Amber 100
        textColor = const Color(0xFFB45309); // Amber 700
        icon = Icons.flag_outlined;
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
            normalized.replaceAll('_', ' '),
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
