import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/models/transaction_category.dart';

class DesktopSpendingOverview extends ConsumerWidget {
  const DesktopSpendingOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    final formatter = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final popupBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return AppCard(
      withGlow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spending Overview', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              PopupMenuButton<String>(
                color: popupBg,
                onSelected: (value) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: popupBg,
                      title: Text('Filter Changed', style: TextStyle(color: textPrimary)),
                      content: Text('Dashboard data has been filtered by $value.', style: TextStyle(color: textMuted)),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: TextStyle(color: AppColors.accent(context))))],
                    ),
                  );
                },
                itemBuilder: (context) => ['This Week', 'This Month', 'Last Month', 'This Year']
                    .map((e) => PopupMenuItem(value: e, child: Text(e, style: TextStyle(color: textPrimary, fontSize: 13))))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Text('This Month', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF022B1E), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.chevronDown, color: isDark ? Colors.white54 : const Color(0xFF005A36), size: 14),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          transactionsAsync.when(
            data: (transactions) {
              final now = DateTime.now();
              final thisMonthTxs = transactions.where((t) => t.date.year == now.year && t.date.month == now.month && t.isIncome == false).toList();
              
              if (thisMonthTxs.isEmpty) { return Center(child: Text('No transactions yet.', style: TextStyle(color: textMuted))); } else if (false) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildCategoryItem(context, 'Food & Groceries', '12 Transactions', '\$520.80', 0.52, LucideIcons.shoppingCart, '\$1,000'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildCategoryItem(context, 'Shopping', '8 Transactions', '\$320.40', 0.32, LucideIcons.shoppingBag, '\$1,000'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildCategoryItem(context, 'Living & Housing', '4 Transactions', '\$780.90', 0.78, LucideIcons.home, '\$1,000'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildCategoryItem(context, 'Transport', '6 Transactions', '\$260.50', 0.26, LucideIcons.bus, '\$1,000'),
                    ),
                  ]
                );
              }

              double totalExpense = 0;
              for (var tx in thisMonthTxs) {
                totalExpense += tx.amount * rate;
              }

              final sortedTxs = thisMonthTxs.toList()..sort((a, b) => b.date.compareTo(a.date));
              final topTxs = sortedTxs.take(4).toList();

              return Column(
                children: topTxs.map((tx) {
                  final catId = tx.categoryId;
                  final cat = CategoryProvider.getExpenseCategories().firstWhere((c) => c.id == catId, orElse: () => CategoryProvider.getExpenseCategories().first);
                  final amount = tx.amount * rate;
                  final percentage = totalExpense > 0 ? (amount / totalExpense) : 0.0;
                  final title = tx.note.isNotEmpty ? tx.note : cat.name;
                  final subtitle = DateFormat('MMM dd, yyyy • hh:mm a').format(tx.date);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildCategoryItem(
                      context,
                      title,
                      subtitle,
                      '$currency${formatter.format(amount)}',
                      percentage,
                      cat.icon,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String name, String subtitle, String amount, double progress, IconData icon, [String budget = '']) {
    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final accent = AppColors.positive(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isDark ? Colors.white70 : accent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(amount, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(subtitle, style: TextStyle(color: textMuted, fontSize: 11)),
                  if (budget.isNotEmpty) Text('Budget $budget', style: TextStyle(color: textMuted, fontSize: 11))
                  else Icon(LucideIcons.chevronRight, color: textMuted, size: 14),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(color: isDark ? Colors.white70 : textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
