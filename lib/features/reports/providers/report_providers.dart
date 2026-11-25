import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../core/providers/account_providers.dart';

class CashFlowReport {
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;

  CashFlowReport({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
  });
}

final cashFlowReportProvider = Provider<CashFlowReport>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final accounts = ref.watch(accountsStreamProvider).value ?? [];
  final enabledAccountIds = accounts
      .where((a) => a.isEnabled && !a.excludeFromTotal)
      .map((a) => a.id)
      .toSet();

  final now = DateTime.now();
  
  double income = 0;
  double expense = 0;

  for (var tx in transactions) {
    if (enabledAccountIds.isNotEmpty && !enabledAccountIds.contains(tx.accountId)) continue;
    // Skip internal transfers between accounts (ATM withdrawals & explicit self transfers)
    final bool isInternalTransfer = tx.categoryId == 'exp_transfer' ||
        (tx.categoryId == 'inc_transfer' && (tx.note.toLowerCase().contains('self transfer') || tx.note.toLowerCase().contains('transfer from')));
    if (isInternalTransfer) continue;

    if (tx.date.year == now.year && tx.date.month == now.month) {
      final amt = tx.amount.abs();
      if (tx.isIncome) {
        income += amt;
      } else {
        expense += amt;
      }
    }
  }

  return CashFlowReport(
    totalIncome: income,
    totalExpense: expense,
    netCashFlow: income - expense,
  );
});

class MonthlySummary {
  final DateTime month;
  final double income;
  final double expense;
  final int transactionCount;
  final List<TransactionModel> transactions;

  MonthlySummary({
    required this.month,
    required this.income,
    required this.expense,
    this.transactionCount = 0,
    this.transactions = const [],
  });

  /// Net savings / profit for the month (කීයක් ලාභයිද)
  double get netProfit => income - expense;
  
  /// Whether the month was profitable (retained more than spent)
  bool get isProfitable => netProfit >= 0;

  /// Percentage of income saved/retained
  double get savingsRate => income > 0 ? ((netProfit / income) * 100).clamp(-100.0, 100.0) : (expense > 0 ? -100.0 : 0.0);

  /// Percentage of income spent
  double get expenseRate => income > 0 ? ((expense / income) * 100).clamp(0.0, 100.0) : (expense > 0 ? 100.0 : 0.0);
}

/// Provides all monthly summaries sorted DESCENDING (newest month first)
final allMonthlySummariesProvider = Provider<List<MonthlySummary>>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final accounts = ref.watch(accountsStreamProvider).value ?? [];
  final enabledAccountIds = accounts
      .where((a) => a.isEnabled && !a.excludeFromTotal)
      .map((a) => a.id)
      .toSet();

  final now = DateTime.now();
  
  // Group transactions by "YYYY-MM"
  Map<String, List<TransactionModel>> grouped = {};
  
  // Ensure at least the last 6 months are initialized
  for (int i = 0; i < 6; i++) {
    final m = DateTime(now.year, now.month - i, 1);
    final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
    grouped[key] = [];
  }

  for (var tx in transactions) {
    // Only include enabled, non-excluded accounts in operational profit & cash flow
    if (enabledAccountIds.isNotEmpty && !enabledAccountIds.contains(tx.accountId)) continue;
    // Skip internal transfers between accounts (ATM withdrawals & explicit self transfers)
    final bool isInternalTransfer = tx.categoryId == 'exp_transfer' ||
        (tx.categoryId == 'inc_transfer' && (tx.note.toLowerCase().contains('self transfer') || tx.note.toLowerCase().contains('transfer from')));
    if (isInternalTransfer) continue;

    final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
    if (!grouped.containsKey(key)) {
      grouped[key] = [];
    }
    grouped[key]!.add(tx);
  }

  List<MonthlySummary> summaries = [];
  grouped.forEach((key, txList) {
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final date = DateTime(year, month, 1);

    double inc = 0;
    double exp = 0;
    for (var t in txList) {
      final amt = t.amount.abs();
      if (t.isIncome) {
        inc += amt;
      } else {
        exp += amt;
      }
    }

    // Sort transactions within month by date descending
    txList.sort((a, b) => b.date.compareTo(a.date));

    summaries.add(MonthlySummary(
      month: date,
      income: inc,
      expense: exp,
      transactionCount: txList.length,
      transactions: txList,
    ));
  });

  // Sort descending: newest month at index 0 (e.g. October 2026, then September 2026)
  summaries.sort((a, b) => b.month.compareTo(a.month));

  return summaries;
});

/// Chronological 6-month report for bar charts (oldest month to newest: left to right)
final sixMonthReportProvider = Provider<List<MonthlySummary>>((ref) {
  final allSummaries = ref.watch(allMonthlySummariesProvider);
  final now = DateTime.now();

  List<MonthlySummary> sixMonths = [];
  for (int i = 5; i >= 0; i--) {
    final targetMonth = DateTime(now.year, now.month - i, 1);
    final found = allSummaries.firstWhere(
      (s) => s.month.year == targetMonth.year && s.month.month == targetMonth.month,
      orElse: () => MonthlySummary(month: targetMonth, income: 0, expense: 0),
    );
    sixMonths.add(found);
  }

  return sixMonths;
});

class MonthlyStatsOverview {
  final double totalIncome;
  final double totalExpense;
  final double totalProfit;
  final double overallSavingsRate;
  final double avgMonthlyProfit;
  final MonthlySummary? currentMonth;
  final MonthlySummary? bestMonth;

  MonthlyStatsOverview({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalProfit,
    required this.overallSavingsRate,
    required this.avgMonthlyProfit,
    this.currentMonth,
    this.bestMonth,
  });
}

final monthlyStatsOverviewProvider = Provider<MonthlyStatsOverview>((ref) {
  final summaries = ref.watch(allMonthlySummariesProvider);
  final now = DateTime.now();

  double totalInc = 0;
  double totalExp = 0;
  MonthlySummary? current;
  MonthlySummary? best;
  int activeMonthsCount = 0;

  for (var s in summaries) {
    totalInc += s.income;
    totalExp += s.expense;
    if (s.income > 0 || s.expense > 0) {
      activeMonthsCount++;
    }

    if (s.month.year == now.year && s.month.month == now.month) {
      current = s;
    }

    if (best == null || s.netProfit > best.netProfit) {
      best = s;
    }
  }

  final totalProf = totalInc - totalExp;
  final savingsRate = totalInc > 0 ? ((totalProf / totalInc) * 100).clamp(-100.0, 100.0) : 0.0;
  final divisor = activeMonthsCount > 0 ? activeMonthsCount : 1;
  final avgProfit = totalProf / divisor;

  return MonthlyStatsOverview(
    totalIncome: totalInc,
    totalExpense: totalExp,
    totalProfit: totalProf,
    overallSavingsRate: savingsRate,
    avgMonthlyProfit: avgProfit,
    currentMonth: current,
    bestMonth: best,
  );
});

class TaxReport {
  final double taxableIncome;
  final double deductibleExpenses;
  
  TaxReport({required this.taxableIncome, required this.deductibleExpenses});
}

final annualTaxReportProvider = Provider<TaxReport>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final accounts = ref.watch(accountsStreamProvider).value ?? [];
  final enabledAccountIds = accounts
      .where((a) => a.isEnabled && !a.excludeFromTotal)
      .map((a) => a.id)
      .toSet();

  final now = DateTime.now();
  
  double income = 0;
  double expense = 0;

  for (var tx in transactions) {
    if (enabledAccountIds.isNotEmpty && !enabledAccountIds.contains(tx.accountId)) continue;
    final bool isInternalTransfer = tx.categoryId == 'exp_transfer' ||
        (tx.categoryId == 'inc_transfer' && (tx.note.toLowerCase().contains('self transfer') || tx.note.toLowerCase().contains('transfer from')));
    if (isInternalTransfer) continue;

    if (tx.date.year == now.year) {
      final amt = tx.amount.abs();
      if (tx.isIncome) {
        income += amt;
      } else {
        expense += amt;
      }
    }
  }

  return TaxReport(
    taxableIncome: income,
    deductibleExpenses: expense,
  );
});
