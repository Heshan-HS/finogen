import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import 'transaction_providers.dart';
import 'account_providers.dart';

// Provides transactions filtered by the current month (and year) for enabled accounts (excluding internal transfers)
final currentMonthTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final allTransactions = ref.watch(transactionsStreamProvider).value ?? [];
  final accounts = ref.watch(accountsStreamProvider).value ?? [];
  final enabledAccountIds = accounts
      .where((a) => a.isEnabled && !a.excludeFromTotal)
      .map((a) => a.id)
      .toSet();
  final now = DateTime.now();
  
  return allTransactions.where((t) {
    if (enabledAccountIds.isNotEmpty && !enabledAccountIds.contains(t.accountId)) return false;
    final bool isInternalTransfer = t.categoryId == 'exp_transfer' ||
        (t.categoryId == 'inc_transfer' && (t.note.toLowerCase().contains('self transfer') || t.note.toLowerCase().contains('transfer from')));
    if (isInternalTransfer) return false;
    return t.date.year == now.year && t.date.month == now.month;
  }).toList();
});

// Provides Total Income and Total Expense for the current month
final monthlyTotalsProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(currentMonthTransactionsProvider);
  double income = 0;
  double expense = 0;

  for (var t in transactions) {
    final amt = t.amount.abs();
    if (t.isIncome) {
      income += amt;
    } else {
      expense += amt;
    }
  }

  return {'income': income, 'expense': expense};
});

// Provides Expense totals grouped by category for the current month
final categoryExpensesProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(currentMonthTransactionsProvider);
  final Map<String, double> categoryTotals = {};

  for (var t in transactions) {
    if (!t.isIncome) {
      final cat = t.categoryId;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount.abs();
    }
  }

  // Sort by highest amount
  var sortedEntries = categoryTotals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
    
  return Map.fromEntries(sortedEntries);
});

// ─── Financial Velocity (Today, This Week, This Month, All Time) ───

class CashFlowPeriodSummary {
  final double income;
  final double expense;
  final int count;

  const CashFlowPeriodSummary({
    this.income = 0.0,
    this.expense = 0.0,
    this.count = 0,
  });

  double get net => income - expense;
}

class FinancialVelocityState {
  final CashFlowPeriodSummary today;
  final CashFlowPeriodSummary thisWeek;
  final CashFlowPeriodSummary thisMonth;
  final CashFlowPeriodSummary allTime;

  const FinancialVelocityState({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.allTime,
  });

  factory FinancialVelocityState.initial() {
    return const FinancialVelocityState(
      today: CashFlowPeriodSummary(),
      thisWeek: CashFlowPeriodSummary(),
      thisMonth: CashFlowPeriodSummary(),
      allTime: CashFlowPeriodSummary(),
    );
  }
}

final financialVelocityProvider = Provider<FinancialVelocityState>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final accounts = ref.watch(accountsStreamProvider).value ?? [];

  final enabledAccountIds = accounts
      .where((a) => a.isEnabled && !a.excludeFromTotal)
      .map((a) => a.id)
      .toSet();

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

  double todayIn = 0, todayOut = 0;
  int todayCount = 0;

  double weekIn = 0, weekOut = 0;
  int weekCount = 0;

  double monthIn = 0, monthOut = 0;
  int monthCount = 0;

  double allIn = 0, allOut = 0;
  int allCount = 0;

  for (var tx in transactions) {
    if (!enabledAccountIds.contains(tx.accountId)) continue;
    final bool isInternalTransfer = tx.categoryId == 'exp_transfer' ||
        (tx.categoryId == 'inc_transfer' && (tx.note.toLowerCase().contains('self transfer') || tx.note.toLowerCase().contains('transfer from')));
    if (isInternalTransfer) continue;

    final amt = tx.amount.abs();
    allCount++;
    if (tx.isIncome) {
      allIn += amt;
    } else {
      allOut += amt;
    }

    // Month check
    if (tx.date.year == now.year && tx.date.month == now.month) {
      monthCount++;
      if (tx.isIncome) {
        monthIn += amt;
      } else {
        monthOut += amt;
      }
    }

    // Week check (calendar week from Monday to Sunday)
    if (tx.date.isAfter(weekStart) || tx.date.isAtSameMomentAs(weekStart)) {
      weekCount++;
      if (tx.isIncome) {
        weekIn += amt;
      } else {
        weekOut += amt;
      }
    }

    // Today check
    if (tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day) {
      todayCount++;
      if (tx.isIncome) {
        todayIn += amt;
      } else {
        todayOut += amt;
      }
    }
  }

  return FinancialVelocityState(
    today: CashFlowPeriodSummary(income: todayIn, expense: todayOut, count: todayCount),
    thisWeek: CashFlowPeriodSummary(income: weekIn, expense: weekOut, count: weekCount),
    thisMonth: CashFlowPeriodSummary(income: monthIn, expense: monthOut, count: monthCount),
    allTime: CashFlowPeriodSummary(income: allIn, expense: allOut, count: allCount),
  );
});
