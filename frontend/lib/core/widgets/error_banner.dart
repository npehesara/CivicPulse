import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ErrorBanner extends StatelessWidget {
  final String? message;
  final bool isSuccess;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    this.isSuccess = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    final bgColor = isSuccess ? AppColors.successBackground : AppColors.errorBackground;
    final borderColor = isSuccess ? AppColors.successBorder : AppColors.errorBorder;
    final textColor = isSuccess ? AppColors.success : AppColors.error;
    final icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: textColor, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
