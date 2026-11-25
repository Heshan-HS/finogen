import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_progress_bar.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/budget_providers.dart';
import '../../../core/models/transaction_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../home/presentation/widgets/edit_budget_sheet.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  String get currency => ref.watch(currencySymbolProvider);
  double get rate => ref.watch(currencyRateProvider);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final budget = ref.watch(currentMonthBudgetProvider).value;
    final categorySpent = ref.watch(monthlyCategorySpendingProvider);
    final totalSpent = ref.watch(currentMonthlyExpenseProvider);
    
    final overallLimit = budget?.overallLimit ?? settings?.monthlyBudget ?? 50000.0;
    final categoryLimits = budget?.categoryLimits ?? {};

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          EditBudgetSheet.show(context);
        },
        backgroundColor: AppColors.accent(context),
        icon: Icon(LucideIcons.edit3, color: AppColors.accentFg(context)),
        label: Text('Edit Budget', style: TextStyle(color: AppColors.accentFg(context), fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [
                      AppColors.primary.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    children: [
                      _overallBudgetCard(totalSpent, overallLimit),
                      const SizedBox(height: 32),
                      Text('Category Spending', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context))),
                      const SizedBox(height: 16),
                      if (categorySpent.isEmpty)
                        Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text('No expenses this month yet.', style: TextStyle(color: AppColors.muted(context))),
                          ),
                        ),
                      ...categorySpent.entries.map((entry) {
                        final catId = entry.key;
                        final spent = entry.value;
                        final limit = categoryLimits[catId] ?? (spent > 0 ? spent : 1000.0); // Fallback to spent if no limit
                        
                        final category = CategoryProvider.getExpenseCategories().firstWhere(
                          (c) => c.id == catId,
                          orElse: () => const TransactionCategory(id: 'unknown', name: 'Other', icon: LucideIcons.helpCircle, color: Colors.grey, isIncome: false),
                        );
                        
                        return _budgetCategory(category.name, spent, limit, category.icon, categoryLimits.containsKey(catId));
                      }),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AppCard(
              padding: const EdgeInsets.all(10),
              isDark: true,
              borderRadius: 12,
              child: Icon(LucideIcons.arrowLeft, color: AppColors.text(context), size: 20),
            ),
          ),
          Text('Budget Planner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text(context))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _overallBudgetCard(double spent, double limit) {
    final pct = limit > 0 ? (spent / limit) : 0.0;
    final isOver = pct > 1.0;
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    
    return AppCard(
      isDark: true,
      centerGlow: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('$monthName Budget', style: TextStyle(fontSize: 14, color: AppColors.muted(context))),
          const SizedBox(height: 8),
          Text('$currency${NumberFormat('#,##0').format(spent * rate)} / $currency${NumberFormat('#,##0').format(limit * rate)}', 
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text(context), letterSpacing: -1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOver ? const Color(0xFFFF5252).withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isOver ? 'Over Budget' : 'On Track', 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isOver ? const Color(0xFFFF5252) : AppColors.primary)),
          ),
          const SizedBox(height: 24),
          AppProgressBar(value: pct > 1.0 ? 1.0 : pct, height: 12),
        ],
      ),
    );
  }

  Widget _budgetCategory(String name, double spent, double limit, IconData icon, bool hasCustomLimit) {
    final pct = limit > 0 ? (spent / limit) : 0.0;
    final isOver = pct > 1.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        isDark: true,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOver ? const Color(0xFFFF5252).withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isOver ? const Color(0xFFFF5252) : AppColors.primary, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text(context))),
                      const SizedBox(height: 4),
                      Text('$currency${NumberFormat('#,##0').format(spent * rate)} ${hasCustomLimit ? 'of $currency${NumberFormat('#,##0').format(limit * rate)}' : ''}', 
                        style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                    ],
                  ),
                ),
                Text(hasCustomLimit ? '${(pct * 100).toStringAsFixed(0)}%' : '', 
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isOver ? const Color(0xFFFF5252) : AppColors.text(context))),
              ],
            ),
            const SizedBox(height: 16),
            AppProgressBar(value: pct > 1.0 ? 1.0 : pct, height: 8),
          ],
        ),
      ),
    );
  }
}
