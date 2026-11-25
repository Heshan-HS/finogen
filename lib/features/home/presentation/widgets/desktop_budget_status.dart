import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/providers/budget_providers.dart';
import '../../../../core/providers/settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/budget_model.dart';
import '../../../../core/repositories/budget_repository.dart';
import 'dart:ui';

class DesktopBudgetStatus extends ConsumerWidget {
  const DesktopBudgetStatus({super.key});

  void _showEditBudgetDialog(BuildContext context, WidgetRef ref, double currentLimit, BudgetModel? existingBudget) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(2));
    final isDark = AppColors.isDark(context);
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? Colors.white54 : AppColors.textMutedLight;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
            ),
            title: Text('Edit Monthly Budget', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textPrimary, fontSize: 18),
              decoration: InputDecoration(
                prefixText: ref.read(currencySymbolProvider),
                prefixStyle: TextStyle(color: textMuted, fontSize: 18),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final val = double.tryParse(controller.text) ?? 0.0;
                  final repo = ref.read(budgetRepositoryProvider);
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
                  
                  final newBudget = existingBudget?.copyWith(overallLimit: val) ?? BudgetModel(
                    id: '', 
                    userId: uid,
                    month: DateTime.now().month,
                    year: DateTime.now().year,
                    overallLimit: val,
                    categoryLimits: {},
                  );
                  
                  await repo.saveBudget(newBudget);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    final formatter = NumberFormat('#,##0.00');
    final budgetAsync = ref.watch(currentMonthBudgetProvider);
    final budgetData = budgetAsync.value;
    final double monthlyBudget = (budgetData?.overallLimit ?? ref.watch(settingsProvider).value?.monthlyBudget ?? 50000.0) * rate; 
    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? Colors.white54 : AppColors.textMutedLight;
    final textMuted70 = isDark ? Colors.white70 : AppColors.textMutedLight;
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
              Row(
                children: [
                  Text('Budget Status', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showEditBudgetDialog(context, ref, budgetData?.overallLimit ?? (monthlyBudget/rate), budgetData),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFe8eefb),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(LucideIcons.edit2, color: AppColors.accent(context), size: 14),
                    ),
                  ),
                ]
              ),
              PopupMenuButton<String>(
                color: popupBg,
                onSelected: (value) {},
                itemBuilder: (context) => ['This Month']
                    .map((e) => PopupMenuItem(value: e, child: Text(e, style: TextStyle(color: textPrimary))))
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
          Text('Overall Budget', style: TextStyle(color: textMuted70, fontSize: 12)),
          const SizedBox(height: 8),
          
          transactionsAsync.when(
            data: (transactions) {
              final now = DateTime.now();
              final thisMonthTxs = transactions.where((t) => t.date.year == now.year && t.date.month == now.month && !t.isIncome).toList();
              
              double spent = 0;
              for (var tx in thisMonthTxs) {
                spent += tx.amount * rate;
              }

              final progress = monthlyBudget > 0 ? (spent / monthlyBudget).clamp(0.0, 1.0) : 0.0;
              final remaining = monthlyBudget - spent;
              
              final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
              final daysLeft = daysInMonth - now.day;
              final dailyLeft = daysLeft > 0 ? (remaining > 0 ? remaining / daysLeft : 0) : remaining;

              final isOvertTack = progress < 0.85;
              final isWarning = progress >= 0.85 && progress < 1.0;
              final statusText = progress >= 1.0 ? "Budget Exceeded!" : (isWarning ? "Nearing budget limit!" : "You're on track!");
              final statusIcon = progress >= 1.0 ? LucideIcons.alertTriangle : (isWarning ? LucideIcons.alertCircle : LucideIcons.trendingUp);
              final statusColor = progress >= 1.0 ? Colors.redAccent : (isWarning ? Colors.orangeAccent : AppColors.accent(context));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$currency${formatter.format(spent)} / $currency${formatter.format(monthlyBudget)}', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                      Text('${(progress * 100).toInt()}%', style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: Stack(
                    children: [
                      Container(height: 8, decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4))),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, child) {
                          return FractionallySizedBox(
                            widthFactor: val,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 8, 
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [statusColor.withOpacity(0.5), statusColor]),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)
                                ]
                              )
                            ),
                          );
                        }
                      ),
                    ],
                  )),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Remaining', style: TextStyle(color: textMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$currency${formatter.format(remaining > 0 ? remaining : 0)}', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Daily Left', style: TextStyle(color: textMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$currency${formatter.format(dailyLeft > 0 ? dailyLeft : 0)}', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), shape: BoxShape.circle),
                          child: Icon(statusIcon, color: statusColor, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(statusText, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(progress >= 1.0 ? "You have exceeded your monthly budget." : "You have ${((1 - progress) * 100).toInt()}% of your budget remaining.", style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textMutedLight, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
            loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SizedBox(height: 150, child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red)))),
          ),
        ],
      ),
    );
  }
}
