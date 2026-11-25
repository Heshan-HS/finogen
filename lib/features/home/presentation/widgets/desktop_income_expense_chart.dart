import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/providers/account_providers.dart';
import '../../../../core/models/transaction_model.dart';

class DesktopIncomeExpenseChart extends ConsumerStatefulWidget {
  const DesktopIncomeExpenseChart({super.key});

  @override
  ConsumerState<DesktopIncomeExpenseChart> createState() => _DesktopIncomeExpenseChartState();
}

class _ChartDataPoint {
  final String label;
  final String fullDate;
  final double income;
  final double expense;

  _ChartDataPoint({
    required this.label,
    required this.fullDate,
    required this.income,
    required this.expense,
  });
}

class _DesktopIncomeExpenseChartState extends ConsumerState<DesktopIncomeExpenseChart> {
  String _selectedFilter = 'This Month';
  final List<String> _filters = ['This Week', 'This Month', 'Last Month', '6 Months', 'This Year'];

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final decimalFormat = NumberFormat('#,##0.00');

    final allAccounts = accountsAsync.value ?? [];
    final enabledAccounts = allAccounts.where((acc) => acc.isEnabled && !acc.excludeFromTotal).toList();
    final enabledAccountIds = enabledAccounts.map((acc) => acc.id).toSet();

    final allTransactions = (transactionsAsync.value ?? [])
        .where((tx) => enabledAccountIds.contains(tx.accountId))
        .toList();

    final dataPoints = _generateChartData(allTransactions, rate);

    double totalIncome = 0;
    double totalExpense = 0;
    double maxAmount = 0;

    for (var p in dataPoints) {
      totalIncome += p.income;
      totalExpense += p.expense;
      if (p.income > maxAmount) maxAmount = p.income;
      if (p.expense > maxAmount) maxAmount = p.expense;
    }

    final double chartMaxY = maxAmount > 0 ? (maxAmount * 1.25) : 1000.0;

    // Responsive bar geometry based on data count
    final int count = dataPoints.length;
    final double barWidth = count <= 7
        ? 12.0
        : count <= 14
            ? 8.0
            : count <= 31
                ? 4.0
                : 3.5;
    final double barsSpace = count <= 7 ? 4.0 : 2.0;

    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? Colors.white54 : AppColors.textMutedLight;
    final incomeColor = AppColors.positive(context);
    final expenseColor = AppColors.negative(context);
    final popupBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return AppCard(
      withGlow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title, Period Summary, and Filter Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income vs Expenses',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Inc: $currency ${decimalFormat.format(totalIncome)}',
                        style: TextStyle(
                          color: incomeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Exp: $currency ${decimalFormat.format(totalExpense)}',
                        style: TextStyle(
                          color: expenseColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                color: popupBg,
                initialValue: _selectedFilter,
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
                itemBuilder: (context) => _filters
                    .map(
                      (e) => PopupMenuItem(
                        value: e,
                        child: Row(
                          children: [
                            if (e == _selectedFilter)
                              Icon(LucideIcons.check, color: incomeColor, size: 14)
                            else
                              const SizedBox(width: 14),
                            const SizedBox(width: 8),
                            Text(
                              e,
                              style: TextStyle(
                                color: e == _selectedFilter ? incomeColor : textPrimary,
                                fontWeight: e == _selectedFilter ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilter,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF022B1E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.chevronDown, color: isDark ? Colors.white54 : const Color(0xFF005A36), size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legends
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem('Income', incomeColor, textMuted),
              const SizedBox(width: 16),
              _buildLegendItem('Expenses', expenseColor, textMuted),
            ],
          ),
          const SizedBox(height: 18),

          // Chart Display
          Expanded(
            child: dataPoints.isEmpty
                ? const Center(
                    child: Text('No transaction data available', style: TextStyle(color: Colors.white38)),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => isDark ? const Color(0xFF0F172A) : Colors.white,
                          tooltipBorder: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), width: 1),
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex < 0 || groupIndex >= dataPoints.length) return null;
                            final point = dataPoints[groupIndex];
                            final diff = point.income - point.expense;
                            final diffColor = diff >= 0 ? incomeColor : expenseColor;
                            final diffSign = diff >= 0 ? '+' : '';

                            return BarTooltipItem(
                              '${point.fullDate}\n',
                              TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: '• Income: $currency ${decimalFormat.format(point.income)}\n',
                                  style: TextStyle(color: incomeColor, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: '• Expense: $currency ${decimalFormat.format(point.expense)}\n',
                                  style: TextStyle(color: expenseColor, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: '• Net: $diffSign$currency ${decimalFormat.format(diff)}',
                                  style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= dataPoints.length) {
                                return const SizedBox.shrink();
                              }

                              bool shouldShow = false;
                              if (count <= 7) {
                                shouldShow = true;
                              } else if (count <= 14) {
                                shouldShow = index % 2 == 0;
                              } else if (count <= 31) {
                                shouldShow = (index == 0) ||
                                    (index == count - 1) ||
                                    ((index + 1) % 5 == 0 && index < count - 3);
                              } else {
                                shouldShow = index % 3 == 0;
                              }

                              if (!shouldShow) return const SizedBox.shrink();

                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  dataPoints[index].label,
                                  style: TextStyle(color: textMuted, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) {
                                return Text('0', style: TextStyle(color: textMuted, fontSize: 10));
                              }
                              if (value == meta.max && value > chartMaxY * 0.95) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                _formatCompactAmount(value, currency),
                                style: TextStyle(color: textMuted, fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (chartMaxY / 4).clamp(1.0, double.infinity),
                        getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: dataPoints.asMap().entries.map((entry) {
                        return _buildBarGroup(
                          entry.key,
                          entry.value.income,
                          entry.value.expense,
                          barWidth,
                          barsSpace,
                          incomeColor,
                          expenseColor,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatCompactAmount(double value, String currency) {
    if (value >= 1000000) {
      return '$currency${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '$currency${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '$currency${value.toInt()}';
    }
  }

  List<_ChartDataPoint> _generateChartData(List<TransactionModel> transactions, double rate) {
    final now = DateTime.now();
    final List<_ChartDataPoint> points = [];

    switch (_selectedFilter) {
      case 'This Week':
        for (int i = 6; i >= 0; i--) {
          final dayDate = DateTime(now.year, now.month, now.day - i);
          double inc = 0;
          double exp = 0;

          for (var tx in transactions) {
            if (tx.date.year == dayDate.year &&
                tx.date.month == dayDate.month &&
                tx.date.day == dayDate.day) {
              final amt = tx.amount * rate;
              if (tx.isIncome) {
                inc += amt;
              } else {
                exp += amt;
              }
            }
          }

          points.add(_ChartDataPoint(
            label: DateFormat('E').format(dayDate),
            fullDate: DateFormat('dd MMM yyyy').format(dayDate),
            income: inc,
            expense: exp,
          ));
        }
        break;

      case 'Last Month':
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final totalDays = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;

        for (int day = 1; day <= totalDays; day++) {
          final dayDate = DateTime(prevMonth.year, prevMonth.month, day);
          double inc = 0;
          double exp = 0;

          for (var tx in transactions) {
            if (tx.date.year == dayDate.year &&
                tx.date.month == dayDate.month &&
                tx.date.day == dayDate.day) {
              final amt = tx.amount * rate;
              if (tx.isIncome) {
                inc += amt;
              } else {
                exp += amt;
              }
            }
          }

          points.add(_ChartDataPoint(
            label: '$day ${DateFormat('MMM').format(dayDate)}',
            fullDate: DateFormat('dd MMM yyyy').format(dayDate),
            income: inc,
            expense: exp,
          ));
        }
        break;

      case '6 Months':
        for (int i = 5; i >= 0; i--) {
          final mDate = DateTime(now.year, now.month - i, 1);
          double inc = 0;
          double exp = 0;

          for (var tx in transactions) {
            if (tx.date.year == mDate.year && tx.date.month == mDate.month) {
              final amt = tx.amount * rate;
              if (tx.isIncome) {
                inc += amt;
              } else {
                exp += amt;
              }
            }
          }

          points.add(_ChartDataPoint(
            label: DateFormat('MMM').format(mDate),
            fullDate: DateFormat('MMMM yyyy').format(mDate),
            income: inc,
            expense: exp,
          ));
        }
        break;

      case 'This Year':
        for (int month = 1; month <= 12; month++) {
          final mDate = DateTime(now.year, month, 1);
          double inc = 0;
          double exp = 0;

          for (var tx in transactions) {
            if (tx.date.year == now.year && tx.date.month == month) {
              final amt = tx.amount * rate;
              if (tx.isIncome) {
                inc += amt;
              } else {
                exp += amt;
              }
            }
          }

          points.add(_ChartDataPoint(
            label: DateFormat('MMM').format(mDate),
            fullDate: DateFormat('MMMM yyyy').format(mDate),
            income: inc,
            expense: exp,
          ));
        }
        break;

      case 'This Month':
      default:
        final totalDays = DateTime(now.year, now.month + 1, 0).day;
        for (int day = 1; day <= totalDays; day++) {
          final dayDate = DateTime(now.year, now.month, day);
          double inc = 0;
          double exp = 0;

          for (var tx in transactions) {
            if (tx.date.year == dayDate.year &&
                tx.date.month == dayDate.month &&
                tx.date.day == dayDate.day) {
              final amt = tx.amount * rate;
              if (tx.isIncome) {
                inc += amt;
              } else {
                exp += amt;
              }
            }
          }

          points.add(_ChartDataPoint(
            label: '$day ${DateFormat('MMM').format(dayDate)}',
            fullDate: DateFormat('dd MMM yyyy').format(dayDate),
            income: inc,
            expense: exp,
          ));
        }
        break;
    }

    return points;
  }

  Widget _buildLegendItem(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: textColor, fontSize: 12)),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(
    int x,
    double income,
    double expense,
    double barWidth,
    double barsSpace,
    Color incomeColor,
    Color expenseColor,
  ) {
    return BarChartGroupData(
      x: x,
      barsSpace: barsSpace,
      barRods: [
        BarChartRodData(
          toY: income,
          color: incomeColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(2),
        ),
        BarChartRodData(
          toY: expense,
          color: expenseColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}
