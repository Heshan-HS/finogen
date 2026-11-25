import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/models/transaction_category.dart';

class DesktopRecentTransactions extends ConsumerWidget {
  const DesktopRecentTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    final formatter = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final incomeColor = isDark ? AppColors.primary : AppColors.primaryLight;
    final expenseColor = isDark ? Colors.redAccent : const Color(0xFFDC2626);

    return AppCard(
      withGlow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Transactions', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('No transactions yet.', style: TextStyle(color: textMuted))));
              }

              // Take top 8 recent
              final recentTxs = transactions.take(8).toList();

              return Column(
                children: recentTxs.map((tx) {
                  final catList = tx.isIncome ? CategoryProvider.getIncomeCategories() : CategoryProvider.getExpenseCategories();
                  final cat = catList.firstWhere((c) => c.id == tx.categoryId, orElse: () => catList.first);
                  final amount = tx.amount * rate;
                  final dateStr = DateFormat('dd MMM yyyy • hh:mm a').format(tx.date);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildTransactionItem(
                      context,
                      tx.note.isNotEmpty ? tx.note : cat.name,
                      '${cat.name} - $dateStr',
                      amount,
                      cat.icon,
                      tx.isIncome ? incomeColor : expenseColor,
                      tx.isIncome,
                      currency,
                      formatter,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading transactions', style: const TextStyle(color: Colors.red))),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, String title, String subtitle, double amount, IconData icon, Color iconColor, bool isIncome, String currency, NumberFormat formatter) {
    final amountStr = '$currency${formatter.format(amount)}';
    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Text(
          '${isIncome ? '+' : '-'} $amountStr',
          style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
