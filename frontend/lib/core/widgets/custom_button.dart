import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget buttonWidget;
    if (isOutlined) {
      buttonWidget = OutlinedButton(
        onPressed: effectiveOnPressed,
        child: buttonChild,
      );
    } else {
      buttonWidget = ElevatedButton(
        onPressed: effectiveOnPressed,
        child: buttonChild,
      );
    }

    if (width != null) {
      return SizedBox(
        width: width,
        height: 48,
        child: buttonWidget,
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: buttonWidget,
    );
  }
}
