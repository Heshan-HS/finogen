import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 3-stop gradient progress bar matching Lovable's --gradient-progress.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.height = 8});

  /// 0.0 â€“ 1.0
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          // bg-secondary (muted dark track)
          color: AppColors.isDark(context) ? AppColors.cardElevated : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: c.maxWidth * value.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              gradient: const LinearGradient(
                colors: [AppColors.gradA, AppColors.gradB, AppColors.gradC],
              ),
            ),
          ),
        ),
      );
    });
  }
}
