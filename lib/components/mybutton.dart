import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPress; // Changed to nullable
  final IconData? icon;
  final Color color;
  final Color? foregroundColor; // Made nullable to match usage
  final Widget? leadingIcon;
  final Widget? child; // Added child parameter

  const MyButton({
    required this.text,
    required this.color,
    this.onPress,
    this.foregroundColor,
    this.icon,
    this.leadingIcon,
    this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPress,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: color,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: child ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
    );
  }
}
