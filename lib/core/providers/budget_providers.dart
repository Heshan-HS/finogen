import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';
import 'transaction_providers.dart';

final currentMonthBudgetProvider = StreamProvider<BudgetModel?>((ref) {
  final now = DateTime.now();
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getBudgetForMonth(now.month, now.year);
});

final monthlyCategorySpendingProvider = Provider<Map<String, double>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final transactions = transactionsAsync.value ?? [];
  final now = DateTime.now();
  
  Map<String, double> categorySpent = {};
  for (var tx in transactions) {
    if (!tx.isIncome && tx.date.month == now.month && tx.date.year == now.year && tx.categoryId != 'exp_transfer') {
      categorySpent[tx.categoryId] = (categorySpent[tx.categoryId] ?? 0.0) + tx.amount;
    }
  }
  return categorySpent;
});

final currentMonthlyExpenseProvider = Provider<double>((ref) {
  final categorySpent = ref.watch(monthlyCategorySpendingProvider);
  return categorySpent.values.fold(0.0, (sum, val) => sum + val);
});
