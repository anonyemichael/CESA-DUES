import 'package:flutter/material.dart';

/// Official Authentic Google 'G' 4-Color Logo Widget.
class GoogleLogoWidget extends StatelessWidget {
  const GoogleLogoWidget({super.key, this.size = 22.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.g_mobiledata,
        color: Color(0xFF4285F4),
        size: 26,
      ),
    );
  }
}
