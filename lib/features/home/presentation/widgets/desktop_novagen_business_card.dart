import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/providers/novagen_business_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import 'novagen_business_modal.dart';

class DesktopNovaGenBusinessCard extends ConsumerStatefulWidget {
  const DesktopNovaGenBusinessCard({super.key});

  @override
  ConsumerState<DesktopNovaGenBusinessCard> createState() => _DesktopNovaGenBusinessCardState();
}

class _DesktopNovaGenBusinessCardState extends ConsumerState<DesktopNovaGenBusinessCard> {
  bool _isQuickAddHovered = false;
  bool _isStatsHovered = false;

  @override
  Widget build(BuildContext context) {
    final bizState = ref.watch(novagenBusinessProvider);
    final currency = ref.watch(currencySymbolProvider);
    final decimalFormat = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);

    final emeraldPrimary = isDark ? AppColors.primary : AppColors.primaryLight;
    final emeraldTint = isDark ? AppColors.primary.withValues(alpha: 0.12) : AppColors.primaryLightTint;
    final textDark = AppColors.text(context);
    final textMuted = AppColors.muted(context);

    final accentBtnBg = isDark
        ? (_isQuickAddHovered ? AppColors.primary.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.14))
        : (_isQuickAddHovered ? AppColors.primaryLightTint : AppColors.primaryLightTint.withValues(alpha: 0.8));
    final accentBtnFg = isDark ? AppColors.primary : AppColors.primaryLight;

    final secondaryBtnBg = isDark
        ? (_isStatsHovered ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04))
        : (_isStatsHovered ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9));
    final secondaryBtnFg = isDark ? Colors.white : AppColors.text(context);

    return AppCard(
      withGlow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Brand & Net Profit
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: emeraldTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: emeraldPrimary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: emeraldPrimary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(LucideIcons.globe, size: 20, color: emeraldPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'NovaGen SpeedNet',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: emeraldPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: emeraldPrimary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: emeraldPrimary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: emeraldPrimary.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ONLINE',
                                style: TextStyle(
                                  color: emeraldPrimary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'VPN Business • Netcup VPS (152.53.236.30)',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${decimalFormat.format(bizState.netProfit)}',
                    style: TextStyle(
                      color: emeraldPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Net Profit',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (bizState.todayRevenue > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: emeraldPrimary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: emeraldPrimary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Today: +Rs ${decimalFormat.format(bizState.todayRevenue)}',
                            style: TextStyle(
                              color: emeraldPrimary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Executive Metrics Bar (Dark obsidian with hairline border)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: emeraldPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: emeraldPrimary.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Spent: Rs ${decimalFormat.format(bizState.totalExpenses)}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 14,
                  width: 1,
                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      bizState.isServerPaidThisCycle ? LucideIcons.checkCircle2 : LucideIcons.server,
                      size: 13,
                      color: emeraldPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      bizState.isServerPaidThisCycle
                          ? 'Paid • ${DateFormat('MMM dd').format(bizState.nextRenewalDate)} (${bizState.daysUntilRenewal}d left)'
                          : 'Due: ${DateFormat('MMM dd').format(bizState.nextRenewalDate)} • ${bizState.daysUntilRenewal}d left',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Quick Add & VPS Stats
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isQuickAddHovered = true),
                  onExit: (_) => setState(() => _isQuickAddHovered = false),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => NovaGenBusinessModal.show(context, initialTab: 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: accentBtnBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isQuickAddHovered
                              ? emeraldPrimary.withValues(alpha: 0.6)
                              : accentBtnFg.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: _isQuickAddHovered
                            ? [
                                BoxShadow(
                                  color: emeraldPrimary.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.plusCircle, size: 15, color: accentBtnFg),
                          const SizedBox(width: 7),
                          Text(
                            'Quick Add',
                            style: TextStyle(
                              color: accentBtnFg,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isStatsHovered = true),
                  onExit: (_) => setState(() => _isStatsHovered = false),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => NovaGenBusinessModal.show(context, initialTab: 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: secondaryBtnBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isStatsHovered
                              ? (isDark ? Colors.white30 : const Color(0xFF94A3B8))
                              : AppColors.borderColor(context),
                          width: 1,
                        ),
                        boxShadow: _isStatsHovered
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.server, size: 15, color: secondaryBtnFg),
                          const SizedBox(width: 7),
                          Text(
                            'VPS & Stats',
                            style: TextStyle(
                              color: secondaryBtnFg,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
