import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/report_providers.dart';

class TaxReportScreen extends ConsumerWidget {
  const TaxReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tax = ref.watch(annualTaxReportProvider);
    final year = DateTime.now().year;
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
                _header(context, year),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    children: [
                      Text('Annual Tax Summary', style: TextStyle(color: AppColors.muted(context), fontSize: 14)),
                      const SizedBox(height: 16),
                      AppCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _summaryRow(context, 'Gross Income', tax.taxableIncome, AppColors.positive(context)),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.borderColor(context))),
                            _summaryRow(context, 'Deductible Expenses', tax.deductibleExpenses, AppColors.negative(context)),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.borderColor(context))),
                            _summaryRow(context, 'Estimated Taxable Income', (tax.taxableIncome - tax.deductibleExpenses).clamp(0.0, double.infinity), AppColors.text(context), isBold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppCard(
                        isDark: isDark,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.alertCircle, color: AppColors.muted(context), size: 20),
                                const SizedBox(width: 12),
                                Text('Disclaimer', style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This is an automated estimate based on categorized income and business-related expense transactions. It does not replace professional tax advisory services.',
                              style: TextStyle(color: AppColors.muted(context), fontSize: 13, height: 1.5),
                            )
                          ],
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
        Text('Rs ' + formatter.format(amount), style: TextStyle(color: color, fontSize: isBold ? 18 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }

  Widget _header(BuildContext context, int year) {
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
          Text('Tax Report $year',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text(context))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
