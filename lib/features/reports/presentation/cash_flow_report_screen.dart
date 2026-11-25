import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/report_providers.dart';
import '../../../core/providers/transaction_providers.dart';

class CashFlowReportScreen extends ConsumerWidget {
  const CashFlowReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlow = ref.watch(cashFlowReportProvider);
    final formatter = NumberFormat('#,##0.00');
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());
    final isDark = AppColors.isDark(context);
    
    final txs = ref.watch(transactionsStreamProvider).value ?? [];
    final monthTxs = txs.where((t) => t.date.month == DateTime.now().month && t.date.year == DateTime.now().year).toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      isDark
                          ? AppColors.primary.withOpacity(0.18)
                          : AppColors.primaryLight.withOpacity(0.05),
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
                      Text('Summary for $monthName', style: TextStyle(color: AppColors.muted(context), fontSize: 14)),
                      const SizedBox(height: 16),
                      AppCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _summaryRow(context, 'Cash In', cashFlow.totalIncome, AppColors.positive(context)),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.borderColor(context))),
                            _summaryRow(context, 'Cash Out', cashFlow.totalExpense, AppColors.negative(context)),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.borderColor(context))),
                            _summaryRow(context, 'Net Cash Flow', cashFlow.netCashFlow, cashFlow.netCashFlow >= 0 ? AppColors.positive(context) : AppColors.negative(context), isBold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text('Transactions this month', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ...monthTxs.map((tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          isDark: isDark,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: tx.isIncome ? AppColors.positiveTint(context) : AppColors.negativeTint(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(tx.isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, 
                                  color: tx.isIncome ? AppColors.positive(context) : AppColors.negative(context), size: 18),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.note.isNotEmpty ? tx.note : tx.categoryId, style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('MMM dd, yyyy').format(tx.date), style: TextStyle(color: AppColors.muted(context), fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text(
                                '${tx.isIncome ? "+" : "-"}Rs ${formatter.format(tx.amount)}',
                                style: TextStyle(
                                  color: tx.isIncome ? AppColors.positive(context) : AppColors.negative(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                      if (monthTxs.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('No transactions found this month.', style: TextStyle(color: AppColors.muted(context))),
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, double amount, Color color, {bool isBold = false}) {
    final formatter = NumberFormat('#,##0.00');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.text(context), fontSize: isBold ? 16 : 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        Text('Rs ${formatter.format(amount)}', style: TextStyle(color: color, fontSize: isBold ? 18 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
      ],
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
              isDark: AppColors.isDark(context),
              borderRadius: 12,
              child: Icon(LucideIcons.arrowLeft, color: AppColors.text(context), size: 20),
            ),
          ),
          Text(
            'Cash Flow Statement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text(context)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
