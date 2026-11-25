import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';

/// Floating bottom nav - theme-aware for dark & light modes
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: LucideIcons.home,           label: 'Overview'),
    (icon: LucideIcons.receipt,        label: 'Transactions'),
    (icon: LucideIcons.barChart3,      label: 'Statistics'),
    (icon: LucideIcons.settings2,      label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          borderRadius: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(context, 0),
              _navItem(context, 1),
              _fab(context),
              _navItem(context, 2),
              _navItem(context, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index) {
    final item = _items[index];
    final active = currentIndex == index;
    final accent = AppColors.accent(context);
    final mutedColor = AppColors.muted(context);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: active ? accent : mutedColor,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9.5,
                color: active ? accent : mutedColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fab(BuildContext context) {
    final accent = AppColors.accent(context);
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen(isExpense: true))),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardElevated : accent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? accent.withOpacity(0.4) : Colors.white,
            width: isDark ? 1.3 : 2.0,
          ),
          boxShadow: isDark
              ? [BoxShadow(color: AppColors.primaryGlow, blurRadius: 34, offset: const Offset(0, 12))]
              : [
                  BoxShadow(color: accent.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                  const BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
                ],
        ),
        child: Icon(LucideIcons.plus, color: isDark ? accent : Colors.white, size: 22),
      ),
    );
  }
}
