import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/report_providers.dart';
import '../../../core/providers/transaction_providers.dart';
import '../services/export_service.dart';
import 'cash_flow_report_screen.dart';
import 'income_expense_report_screen.dart';
import 'tax_report_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
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
                      _buildCashFlowCard(context, ref),
                      _buildIncomeExpenseCard(context, ref),
                      _buildTaxReportCard(context, ref),
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
              isDark: AppColors.isDark(context),
              borderRadius: 12,
              child: Icon(LucideIcons.arrowLeft, color: AppColors.text(context), size: 20),
            ),
          ),
          Text(
            'Financial Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCashFlowCard(BuildContext context, WidgetRef ref) {
    final cashFlow = ref.watch(cashFlowReportProvider);
    final formatter = NumberFormat('#,##0.00');
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());
    
    return _reportCard(
      context, 
      title: 'Cash Flow Statement',
      subtitle: '$monthName • Net: Rs ' + formatter.format(cashFlow.netCashFlow),
      icon: LucideIcons.barChart,
      highlight: true,
      onView: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CashFlowReportScreen()));
      },
      onExport: () async {
        final txs = ref.read(transactionsStreamProvider).value ?? [];
        final monthTxs = txs.where((t) => t.date.month == DateTime.now().month && t.date.year == DateTime.now().year).toList();
        await ExportService.exportTransactionsToCsv(monthTxs, 'CashFlow_$monthName');
      },
    );
  }

  Widget _buildIncomeExpenseCard(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(sixMonthReportProvider);
    double totalIncome = summaries.fold(0.0, (s, e) => s + e.income);
    double totalExpense = summaries.fold(0.0, (s, e) => s + e.expense);
    final formatter = NumberFormat('#,##0.00');
    
    return _reportCard(
      context, 
      title: 'Income & Expenses',
      subtitle: 'Last 6 Months • In: Rs ' + formatter.format(totalIncome) + ' | Out: Rs ' + formatter.format(totalExpense),
      icon: LucideIcons.pieChart,
      highlight: false,
      onView: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeExpenseReportScreen()));
      },
      onExport: () async {
        final txs = ref.read(transactionsStreamProvider).value ?? [];
        final sixMonthsAgo = DateTime(DateTime.now().year, DateTime.now().month - 5, 1);
        final filteredTxs = txs.where((t) => t.date.isAfter(sixMonthsAgo) || t.date.isAtSameMomentAs(sixMonthsAgo)).toList();
        await ExportService.exportTransactionsToCsv(filteredTxs, 'IncomeExpense_Last6Months');
      },
    );
  }

  Widget _buildTaxReportCard(BuildContext context, WidgetRef ref) {
    final tax = ref.watch(annualTaxReportProvider);
    final formatter = NumberFormat('#,##0.00');
    final year = DateTime.now().year;
    
    return _reportCard(
      context, 
      title: 'Tax Report $year',
      subtitle: 'Annual • Taxable: Rs ' + formatter.format(tax.taxableIncome),
      icon: LucideIcons.fileText,
      highlight: false,
      onView: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TaxReportScreen()));
      },
      onExport: () async {
        final txs = ref.read(transactionsStreamProvider).value ?? [];
        final yearTxs = txs.where((t) => t.date.year == year).toList();
        await ExportService.exportTransactionsToCsv(yearTxs, 'TaxReport_$year');
      },
    );
  }

  Widget _reportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool highlight,
    required VoidCallback onView,
    required VoidCallback onExport,
  }) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        isDark: isDark,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: highlight
                        ? AppColors.accentTint(context)
                        : (isDark ? AppColors.cardElevated.withOpacity(0.5) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: highlight ? AppColors.accent(context).withOpacity(0.3) : AppColors.borderColor(context),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: highlight ? AppColors.accent(context) : AppColors.text(context),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onView,
                    child: AppCard(
                      isDark: isDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      borderRadius: 8,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.eye, size: 16, color: AppColors.text(context)),
                            const SizedBox(width: 8),
                            Text(
                              'View',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text(context),
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
                  child: GestureDetector(
                    onTap: onExport,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: AppColors.accent(context)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.download, size: 16, color: AppColors.accent(context)),
                            const SizedBox(width: 8),
                            Text(
                              'Export',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
