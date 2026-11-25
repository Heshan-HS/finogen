import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/providers/settings_provider.dart';

class DesktopMetricsRow extends ConsumerWidget {
  const DesktopMetricsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceState = ref.watch(balanceProvider);
    final rate = ref.watch(currencyRateProvider);
    final currency = ref.watch(currencySymbolProvider);
    final formatter = NumberFormat('#,##0.00');
    
    final totalBalance = formatter.format(balanceState.totalBalance * rate);
    final totalIncome = formatter.format(balanceState.totalIncome * rate);
    final totalExpense = formatter.format(balanceState.totalExpense * rate);
    final savings = formatter.format((balanceState.totalIncome - balanceState.totalExpense) * rate);

    return Row(
      children: [
        Expanded(child: _buildMetricCard(context, 'Total Balance', currency, totalBalance, '+12.5%', true, LucideIcons.layers)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(context, 'Total Income', currency, totalIncome, '+8.2%', true, LucideIcons.wallet)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(context, 'Total Expense', currency, totalExpense, '+5.1%', false, LucideIcons.creditCard)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(context, 'Savings', currency, savings, '+15.3%', true, LucideIcons.piggyBank)),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String currency, String amount, String pct, bool isPositive, IconData icon) {
    final bool isTotalBalance = title == 'Total Balance';
    
    if (isTotalBalance) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.55, 1.0],
            colors: [
              Color(0xFF054A34), // Emerald dark bright
              Color(0xFF022E1F), // Emerald deep mid
              Color(0xFF00150E), // Almost black green
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 32,
              spreadRadius: -4,
              offset: const Offset(0, 14),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        child: Stack(
          children: [
            // Glass Reflection Sheen
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.3, 0.6, 1.0],
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                      Colors.white.withOpacity(0.01),
                    ],
                  ),
                ),
              ),
            ),
            // Corner Glow Orb
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(20), child: _buildCardContent(context, title, currency, amount, pct, isPositive, icon, isTotalBalance, true)),
          ],
        ),
      );
    }
    
    return AppCard(
      withGlow: true,
      padding: const EdgeInsets.all(20),
      child: _buildCardContent(context, title, currency, amount, pct, isPositive, icon, isTotalBalance, false),
    );
  }

  Widget _buildCardContent(BuildContext context, String title, String currency, String amount, String pct, bool isPositive, IconData icon, bool isTotalBalance, bool isPremium) {
    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final accentColor = AppColors.accent(context);

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPremium ? Colors.white.withOpacity(0.15) : accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isPremium ? Colors.white : accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isPremium ? Colors.white70 : textMuted, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$currency ',
                            style: TextStyle(
                              color: isPremium ? Colors.white70 : textMuted,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextSpan(
                            text: amount,
                            style: TextStyle(
                              color: isPremium ? Colors.white : textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isTotalBalance) ...[
                      const SizedBox(width: 12),
                      Icon(LucideIcons.eye, color: isPremium ? Colors.white54 : textMuted, size: 18),
                    ]
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isPositive ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                      color: isPositive ? accentColor : AppColors.negative(context),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(pct, style: TextStyle(color: isPositive ? accentColor : AppColors.negative(context), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text('from last month', style: TextStyle(color: isPremium ? Colors.white70 : textMuted, fontSize: 12)),
                  ],
                )
              ],
            ),
          )
        ],
    );
  }
}
