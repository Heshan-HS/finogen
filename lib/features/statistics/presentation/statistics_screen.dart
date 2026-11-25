import 'package:flutter/material.dart';
import '../../reports/presentation/income_expense_report_screen.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const IncomeExpenseReportScreen(isRootTab: true);
  }
}
