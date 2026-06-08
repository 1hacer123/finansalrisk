import 'package:flutter/material.dart';
import '../core/constants.dart';

enum ButtonType {
  Primary,
  Secondary,
}

class NavigationButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;

  const NavigationButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.Primary,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    if (type == ButtonType.Primary) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),

          /// Dark mode primary button
          gradient: isEnabled
              ? const LinearGradient(
            colors: [kPrimaryColor, kSecondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,

          /// Disabled = koyu gri ton
          color: isEnabled ? null : Colors.grey.shade800,
        ),
        child: MaterialButton(
          padding: const EdgeInsets.symmetric(vertical: 16),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              color: isEnabled ? Colors.white : Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // SECONDARY BUTTON (dark theme uyumlu)
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isEnabled ? const Color(0xFF1E1E20) : Colors.grey.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isEnabled ? Colors.white : Colors.white38,
          fontSize: 16,
        ),
      ),
    );
  }
}
