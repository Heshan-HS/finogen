import '../../../../core/models/account_model.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/providers/account_providers.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../transactions/presentation/widgets/add_transaction_modal.dart';
import '../../../transfer/presentation/transfer_screen.dart';
import '../../../bills/presentation/bills_screen.dart';
import '../../../accounts/presentation/accounts_screen.dart';
import '../../../reports/presentation/reports_screen.dart';
import 'gf_holding_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DesktopQuickActions extends ConsumerWidget {
  const DesktopQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final incomeColor = AppColors.positive(context);
    final expenseColor = AppColors.negative(context);
    final neutralIconColor = isDark ? Colors.white70 : AppColors.muted(context);

    return AppCard(
      withGlow: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SizedBox(height: 64, child: _buildActionCard(context, 'Income', LucideIcons.plus, incomeColor, () => AddTransactionModal.show(context, isExpense: false)))),
              const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 64, child: _buildActionCard(context, 'Expense', LucideIcons.minus, expenseColor, () => AddTransactionModal.show(context, isExpense: true)))),
              const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 64, child: _buildActionCard(context, 'Transfer', LucideIcons.arrowLeftRight, neutralIconColor, () => ref.read(mainNavIndexProvider.notifier).setIndex(2)))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: SizedBox(height: 64, child: _buildActionCard(context, 'Bills', LucideIcons.receipt, neutralIconColor, () => ref.read(mainNavIndexProvider.notifier).setIndex(3)))),
              const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 64, child: _buildActionCard(context, 'Accounts', LucideIcons.wallet, neutralIconColor, () => ref.read(mainNavIndexProvider.notifier).setIndex(4)))),
              const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 64, child: _buildActionCard(context, 'Reports', LucideIcons.pieChart, neutralIconColor, () => ref.read(mainNavIndexProvider.notifier).setIndex(5)))),
            ],
          ),
          const SizedBox(height: 12),
          _buildGfHoldingCard(context, ref),
        ],
      ),
    );
  }

  Widget _buildGfHoldingCard(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final currency = ref.watch(currencySymbolProvider);
    final decimalFormat = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);

    AccountModel? gfAccount = accounts.cast<AccountModel?>().firstWhere(
      (a) => a != null && (a.name.toLowerCase().contains('boc') || (a.name.toLowerCase().contains('gf') && a.name.toLowerCase().contains('holding'))),
      orElse: () => null,
    );
    if (gfAccount == null) {
      gfAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && a.excludeFromTotal && a.name.toLowerCase().contains('holding'),
        orElse: () => null,
      );
    }
    if (gfAccount == null) {
      gfAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && a.excludeFromTotal,
        orElse: () => null,
      );
    }

    final double holdingBalance = gfAccount != null ? ref.watch(accountDerivedBalanceProvider(gfAccount.id)) : 0.0;

    final amberIconBg = isDark ? Colors.amber.withOpacity(0.18) : const Color(0xFFFEF3C7);
    final amberColor = isDark ? Colors.amber : const Color(0xFFD97706);
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? Colors.amber.withOpacity(0.35) : const Color(0xFFFDE68A);
    final accentBtnBg = isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primaryLightTint;
    final accentBtnFg = isDark ? AppColors.primary : AppColors.primaryLight;
    final secondaryBtnBg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFFFFFFF);
    final secondaryBtnFg = isDark ? Colors.white70 : AppColors.text(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: amberIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.landmark, color: amberColor, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GF BOC Holding', style: TextStyle(color: AppColors.text(context), fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('Excluded from Main Total', style: TextStyle(color: AppColors.muted(context), fontSize: 9)),
                    ],
                  ),
                ],
              ),
              Text(
                '$currency ${decimalFormat.format(holdingBalance)}',
                style: TextStyle(color: amberColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => GfHoldingModal.show(context, initialTab: 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: accentBtnBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentBtnFg.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.plusCircle, size: 12, color: accentBtnFg),
                        const SizedBox(width: 4),
                        Text('Quick Add', style: TextStyle(color: accentBtnFg, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () => GfHoldingModal.show(context, initialTab: 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: secondaryBtnBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.barChart2, size: 12, color: secondaryBtnFg),
                        const SizedBox(width: 4),
                        Text('History / Stats', style: TextStyle(color: secondaryBtnFg, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
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

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: textPrimary, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
