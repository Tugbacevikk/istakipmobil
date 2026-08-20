import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MobileFrameWrapper extends StatelessWidget {
  final Widget child;

  const MobileFrameWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktopOrWeb = kIsWeb || mediaQuery.size.width > 500;

    if (!isDesktopOrWeb) {
      return child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17), // Deep dark background outside phone frame
      body: Center(
        child: Container(
          width: 440,
          height: 880,
          margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFF334155), width: 8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}
