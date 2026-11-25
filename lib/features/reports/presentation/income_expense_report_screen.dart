import '../../../core/models/transaction_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/models/transaction_model.dart';
import '../providers/report_providers.dart';
import '../services/export_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/analytics_providers.dart';

class IncomeExpenseReportScreen extends ConsumerStatefulWidget {
  final bool isRootTab;
  const IncomeExpenseReportScreen({super.key, this.isRootTab = false});

  @override
  ConsumerState<IncomeExpenseReportScreen> createState() => _IncomeExpenseReportScreenState();
}

class _IncomeExpenseReportScreenState extends ConsumerState<IncomeExpenseReportScreen> {
  bool _filterActiveOnly = false;
  int _selectedView = 0; // 0 = Cash Flow & Trends, 1 = Categories

  @override
  Widget build(BuildContext context) {
    final allSummaries = ref.watch(allMonthlySummariesProvider);
    final chartSummaries = ref.watch(sixMonthReportProvider);
    final overview = ref.watch(monthlyStatsOverviewProvider);
    final isDark = AppColors.isDark(context);

    // Filter summaries if user only wants active months
    final displayedSummaries = _filterActiveOnly
        ? allSummaries.where((s) => s.income > 0 || s.expense > 0).toList()
        : allSummaries;

    // Calculate max value for chart Y-axis
    double maxAmount = 0;
    for (var s in chartSummaries) {
      if (s.income > maxAmount) maxAmount = s.income;
      if (s.expense > maxAmount) maxAmount = s.expense;
    }
    maxAmount = maxAmount * 1.25;
    if (maxAmount == 0) maxAmount = 1000;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // Ambient soft glow on top
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, -0.8),
                    radius: 1.4,
                    colors: [
                      isDark
                          ? AppColors.primary.withOpacity(0.18)
                          : AppColors.primaryLight.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                if (widget.isRootTab) _buildSegmentSwitcher(context),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, widget.isRootTab ? 120 : 32),
                    children: _selectedView == 0
                        ? [
                            // 1. Hero Net Profit & Savings Card
                            _buildHeroProfitCard(context, overview),
                            const SizedBox(height: 20),

                            // 2. Bar Chart (Last 6 Months Trend)
                            _buildChartCard(context, chartSummaries, maxAmount),
                            const SizedBox(height: 24),

                            // 3. Monthly Breakdown Header with Toggle
                            _buildSectionHeader(context, displayedSummaries.length),
                            const SizedBox(height: 14),

                            // 4. Monthly Breakdown List (Descending order)
                            ...displayedSummaries.map((s) => _buildMonthlySummaryCard(context, s)),

                            const SizedBox(height: 32),
                          ]
                        : [
                            _buildCategoryPieCard(context),
                            const SizedBox(height: 24),
                            _buildCategoryBreakdown(context),
                            const SizedBox(height: 32),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!widget.isRootTab && Navigator.canPop(context)) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: AppCard(
                    padding: const EdgeInsets.all(10),
                    isDark: isDark,
                    borderRadius: 12,
                    child: Icon(LucideIcons.arrowLeft, color: AppColors.text(context), size: 20),
                  ),
                ),
                const SizedBox(width: 14),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primaryLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.barChart3, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                'Income & Expenses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              final txs = ref.read(allMonthlySummariesProvider).expand((s) => s.transactions).toList();
              await ExportService.exportTransactionsToCsv(txs, 'Monthly_Financial_Report');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Financial report exported successfully!')),
                );
              }
            },
            child: AppCard(
              padding: const EdgeInsets.all(10),
              isDark: isDark,
              borderRadius: 12,
              child: Icon(LucideIcons.download, color: AppColors.accent(context), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentSwitcher(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedView = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _selectedView == 0
                        ? (isDark ? AppColors.primary.withValues(alpha: 0.22) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _selectedView == 0 && !isDark
                        ? [const BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.barChart3,
                        size: 15,
                        color: _selectedView == 0 ? AppColors.primary : AppColors.muted(context),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Cash Flow & Trends',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _selectedView == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedView == 0 ? AppColors.primary : AppColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedView = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _selectedView == 1
                        ? (isDark ? AppColors.primary.withValues(alpha: 0.22) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _selectedView == 1 && !isDark
                        ? [const BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.pieChart,
                        size: 15,
                        color: _selectedView == 1 ? AppColors.primary : AppColors.muted(context),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _selectedView == 1 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedView == 1 ? AppColors.primary : AppColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieCard(BuildContext context) {
    final rate = ref.watch(currencyRateProvider);
    final currency = ref.watch(currencySymbolProvider);
    final totals = ref.watch(monthlyTotalsProvider);
    final income = (totals['income'] ?? 0) * rate;
    final expense = (totals['expense'] ?? 0) * rate;
    final total = income + expense;

    double incomePct = total == 0 ? 0 : (income / total) * 100;
    double expensePct = total == 0 ? 0 : (expense / total) * 100;
    final isDark = AppColors.isDark(context);

    return AppCard(
      isDark: isDark,
      centerGlow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text(context))),
              Icon(LucideIcons.pieChart, color: AppColors.muted(context), size: 20),
            ],
          ),
          const SizedBox(height: 30),
          if (total == 0)
            SizedBox(
              height: 180,
              child: Center(child: Text('No transactions this month.', style: TextStyle(color: AppColors.muted(context)))),
            )
          else
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 75,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: AppColors.primary,
                          value: income,
                          title: '',
                          radius: 16,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFFF5252),
                          value: expense,
                          title: '',
                          radius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total Spent', style: TextStyle(fontSize: 11, color: AppColors.muted(context))),
                    const SizedBox(height: 4),
                    Text('$currency${NumberFormat('#,##0').format(expense)}',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                            letterSpacing: -0.5)),
                  ],
                )
              ],
            ),
          const SizedBox(height: 30),
          if (total > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _chartLegendItem(context, 'Income', AppColors.primary, '${incomePct.toStringAsFixed(1)}%'),
                _chartLegendItem(context, 'Expense', const Color(0xFFFF5252), '${expensePct.toStringAsFixed(1)}%'),
              ],
            )
        ],
      ),
    );
  }

  Widget _chartLegendItem(BuildContext context, String label, Color color, String pct) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.muted(context))),
        const SizedBox(width: 8),
        Text(pct, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context))),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    final rate = ref.watch(currencyRateProvider);
    final currency = ref.watch(currencySymbolProvider);
    final catExpenses = ref.watch(categoryExpensesProvider);
    final totals = ref.watch(monthlyTotalsProvider);
    final totalExpense = (totals['expense'] ?? 0) * rate;
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Categories (This Month)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
        ),
        const SizedBox(height: 16),
        if (catExpenses.isEmpty)
          AppCard(
            isDark: isDark,
            padding: const EdgeInsets.all(20),
            child: Center(child: Text('No expenses recorded.', style: TextStyle(color: AppColors.muted(context)))),
          )
        else
          ...catExpenses.entries.map((e) {
            final val = e.value * rate;
            final pct = totalExpense > 0 ? val / totalExpense : 0.0;
            return _catItem(context, _getIconForCategory(e.key), _getCategoryName(e.key), val, pct, currency);
          }),
      ],
    );
  }

  String _getCategoryName(String id) {
    final allCats = CategoryProvider.getExpenseCategories();
    for (var c in allCats) {
      if (c.id == id) return c.name;
    }
    switch (id) {
      case 'exp_bills': return 'Bills & Utilities';
      case 'exp_novagen_server': return 'Netcup Server VPS';
      case 'exp_novagen_draw': return 'NovaGen Drawing';
      case 'exp_food': return 'Food & Dining';
      case 'exp_transport': return 'Transport';
      case 'exp_shopping': return 'Shopping';
      case 'exp_entertainment': return 'Entertainment';
      case 'exp_health': return 'Health & Medical';
      case 'exp_transfer': return 'Transfer Out';
      default:
        if (id.startsWith('exp_')) {
          final clean = id.substring(4);
          return clean[0].toUpperCase() + clean.substring(1);
        }
        return id;
    }
  }

  IconData _getIconForCategory(String category) {
    final allCats = CategoryProvider.getExpenseCategories();
    for (var c in allCats) {
      if (c.id == category) return c.icon;
    }
    switch (category) {
      case 'exp_food':
      case 'Food & Dining': return LucideIcons.utensilsCrossed;
      case 'exp_shopping':
      case 'Shopping': return LucideIcons.shoppingBag;
      case 'exp_transport':
      case 'Transportation': return LucideIcons.bus;
      case 'exp_entertainment':
      case 'Entertainment': return LucideIcons.gamepad2;
      case 'exp_bills':
      case 'Housing':
      case 'Utilities': return LucideIcons.zap;
      case 'exp_health':
      case 'Medical': return LucideIcons.stethoscope;
      case 'exp_novagen_server': return LucideIcons.server;
      case 'exp_novagen_draw': return LucideIcons.wallet;
      default: return LucideIcons.creditCard;
    }
  }

  Widget _catItem(BuildContext context, IconData icon, String name, double amount, double pct, String currency) {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        isDark: isDark,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevated(context).withValues(alpha: 0.7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor(context)),
              ),
              child: Icon(icon, size: 20, color: AppColors.text(context).withValues(alpha: 0.85)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text(context))),
                      Text('$currency${NumberFormat('#,##0.00').format(amount)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Hero Card: Current Month Net Profit & Overall Financial Health
  Widget _buildHeroProfitCard(BuildContext context, MonthlyStatsOverview overview) {
    final formatter = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);
    final currentMonth = overview.currentMonth;
    final netProfit = currentMonth?.netProfit ?? 0.0;
    final isProfitable = netProfit >= 0;
    final savingsRate = currentMonth?.savingsRate ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF042018), const Color(0xFF02120E)]
              : [const Color(0xFF00643F), const Color(0xFF00442B)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.primary : const Color(0xFF00643F)).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Soft decorative corner circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF55FFBA),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentMonth != null
                                ? DateFormat('MMMM yyyy').format(currentMonth.month)
                                : 'This Month',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                        ),
                        child: Text(
                          isProfitable
                              ? '+'+savingsRate.toStringAsFixed(1)+'% Saved'
                              : savingsRate.toStringAsFixed(1)+'% Deficit',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Net Profit / Savings',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isProfitable ? '+Rs ' : '-Rs ',
                        style: TextStyle(
                          color: isProfitable ? const Color(0xFF55FFBA) : const Color(0xFFFF8585),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatter.format(netProfit.abs()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Inflow & Outflow mini cards
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.arrowDownLeft, color: Color(0xFF55FFBA), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Total Income',
                                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs ' + formatter.format(currentMonth?.income ?? 0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.white.withOpacity(0.15)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.arrowUpRight, color: Color(0xFFFF8585), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Total Expense',
                                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs ' + formatter.format(currentMonth?.expense ?? 0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. 6-Month Comparison Bar Chart
  Widget _buildChartCard(BuildContext context, List<MonthlySummary> summaries, double maxAmount) {
    final isDark = AppColors.isDark(context);

    return AppCard(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6-Month Cash Flow Trend',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monthly Income vs Expenses',
                    style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                  ),
                ],
              ),
              Icon(LucideIcons.barChart2, color: AppColors.accent(context), size: 20),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => isDark ? const Color(0xFF0C1815) : Colors.white,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final summary = summaries[group.x.toInt()];
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        DateFormat('MMM yyyy').format(summary.month) + '\n' + (isIncome ? 'In: Rs ' : 'Out: Rs ') + NumberFormat('#,##0').format(rod.toY),
                        TextStyle(
                          color: isIncome ? AppColors.accent(context) : const Color(0xFFFF5252),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < summaries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MMM').format(summaries[idx].month),
                              style: TextStyle(
                                color: AppColors.muted(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxAmount / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderColor(context).withOpacity(0.6),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: summaries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final summary = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: summary.income,
                        color: isDark ? AppColors.primary : AppColors.primaryLight,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                      BarChartRodData(
                        toY: summary.expense,
                        color: isDark ? const Color(0xFFFF5252) : const Color(0xFFDC2626),
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('Income (Cash In)', isDark ? AppColors.primary : AppColors.primaryLight),
              const SizedBox(width: 24),
              _legendItem('Expense (Cash Out)', isDark ? const Color(0xFFFF5252) : const Color(0xFFDC2626)),
            ],
          )
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 3. Section Header with Filter
  Widget _buildSectionHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Monthly Breakdown',
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentTint(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: AppColors.accent(context),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _filterActiveOnly = !_filterActiveOnly;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _filterActiveOnly ? AppColors.accent(context) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor(context)),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.filter,
                  size: 12,
                  color: _filterActiveOnly ? Colors.white : AppColors.muted(context),
                ),
                const SizedBox(width: 4),
                Text(
                  _filterActiveOnly ? 'Active Only' : 'All Months',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _filterActiveOnly ? Colors.white : AppColors.muted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 4. Monthly Card: Detailed breakdown of each month with Net Profit
  Widget _buildMonthlySummaryCard(BuildContext context, MonthlySummary summary) {
    final formatter = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);
    final now = DateTime.now();
    final isCurrentMonth = summary.month.year == now.year && summary.month.month == now.month;
    final netProfit = summary.netProfit;
    final isProfitable = netProfit >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        isDark: isDark,
        padding: const EdgeInsets.all(18),
        onTap: () => _showMonthTransactionsSheet(context, summary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Month Name & This Month badge & Net Profit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(summary.month),
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (isCurrentMonth) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentTint(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.accent(context).withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            color: AppColors.accent(context),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Profit / Loss Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isProfitable ? AppColors.positiveTint(context) : AppColors.negativeTint(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isProfitable ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                        size: 13,
                        color: isProfitable ? AppColors.positive(context) : AppColors.negative(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isProfitable ? 'Profit' : 'Deficit',
                        style: TextStyle(
                          color: isProfitable ? AppColors.positive(context) : AppColors.negative(context),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Middle: Net Profit amount (කීයක් ලාභයිද)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Savings / Profit',
                      style: TextStyle(color: AppColors.muted(context), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (isProfitable ? '+Rs ' : '-Rs ') + formatter.format(netProfit.abs()),
                      style: TextStyle(
                        color: isProfitable ? AppColors.positive(context) : AppColors.negative(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Text(
                  summary.income > 0
                      ? summary.savingsRate.toStringAsFixed(1) + '% Retained'
                      : (summary.expense > 0 ? '100% Spent' : '0.0%'),
                  style: TextStyle(
                    color: AppColors.muted(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Dual Mini Cash Flow Metrics
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevated(context) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Income', style: TextStyle(color: AppColors.muted(context), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs ' + formatter.format(summary.income),
                          style: TextStyle(
                            color: AppColors.positive(context),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: AppColors.borderColor(context)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expense', style: TextStyle(color: AppColors.muted(context), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          'Rs ' + formatter.format(summary.expense),
                          style: TextStyle(
                            color: AppColors.negative(context),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: AppColors.muted(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet showing all transactions for a specific month
  void _showMonthTransactionsSheet(BuildContext context, MonthlySummary summary) {
    final formatter = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);
    final txs = summary.transactions;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.card : AppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppColors.borderColor(context)),
          ),
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.muted(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(summary.month),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      Text(
                        txs.length.toString() + ' Transactions • Net: ' + (summary.isProfitable ? '+Rs ' : '-Rs ') + formatter.format(summary.netProfit.abs()),
                        style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, color: AppColors.muted(context)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: txs.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions recorded for this month.',
                          style: TextStyle(color: AppColors.muted(context)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: txs.length,
                        separatorBuilder: (_, __) => Divider(color: AppColors.borderColor(context), height: 1),
                        itemBuilder: (context, idx) {
                          final tx = txs[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: tx.isIncome ? AppColors.positiveTint(context) : AppColors.negativeTint(context),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    tx.isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                                    size: 18,
                                    color: tx.isIncome ? AppColors.positive(context) : AppColors.negative(context),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.note.isNotEmpty ? tx.note : (tx.categoryId.isNotEmpty ? tx.categoryId : 'Transaction'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(tx.date),
                                        style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  (tx.isIncome ? '+Rs ' : '-Rs ') + formatter.format(tx.amount),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: tx.isIncome ? AppColors.positive(context) : AppColors.negative(context),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
