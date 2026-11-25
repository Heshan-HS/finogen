import 'account_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getUserTransactions();
});

class BalanceState {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;

  BalanceState({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory BalanceState.initial() => BalanceState(totalBalance: 0, totalIncome: 0, totalExpense: 0);
}

final balanceProvider = Provider<BalanceState>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final accountsAsync = ref.watch(accountsStreamProvider);
  
  return transactionsAsync.when(
    data: (transactions) {
      final allAccounts = accountsAsync.value ?? [];
      final enabledAccounts = allAccounts.where((acc) => acc.isEnabled && !acc.excludeFromTotal).toList();
      final enabledAccountIds = enabledAccounts.map((acc) => acc.id).toSet();
      
      double totalBalance = 0;
      double totalIncome = 0;
      double totalExpense = 0;
      
      // Start with base balances from all enabled accounts
      for (var acc in enabledAccounts) {
        totalBalance += acc.balance;
      }

      for (var tx in transactions) {
        // Only include transactions belonging to enabled accounts
        if (enabledAccountIds.contains(tx.accountId)) {
          if (tx.isIncome) {
            totalIncome += tx.amount;
            totalBalance += tx.amount;
          } else {
            totalExpense += tx.amount;
            totalBalance -= tx.amount;
          }
        }
      }
      return BalanceState(
        totalBalance: totalBalance,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
      );
    },
    loading: () => BalanceState.initial(),
    error: (_, __) => BalanceState.initial(),
  );
});

// A provider to get the derived balance of a specific account
final accountDerivedBalanceProvider = Provider.family<double, String>((ref, accountId) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final account = ref.watch(accountByIdProvider(accountId));
  
  if (account == null) return 0.0;
  
  double balance = account.balance;
  for (var tx in transactions.where((t) => t.accountId == accountId)) {
    if (tx.isIncome) {
      balance += tx.amount;
    } else {
      balance -= tx.amount;
    }
  }
  return balance;
});

final currentMonthExpenseProvider = Provider<double>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final accountsAsync = ref.watch(accountsStreamProvider);
  
  return transactionsAsync.when(
    data: (transactions) {
      final allAccounts = accountsAsync.value ?? [];
      final enabledAccountIds = allAccounts.where((a) => a.isEnabled && !a.excludeFromTotal).map((a) => a.id).toSet();

      final now = DateTime.now();
      return transactions
          .where((tx) =>
              enabledAccountIds.contains(tx.accountId) &&
              !tx.isIncome &&
              tx.date.year == now.year &&
              tx.date.month == now.month)
          .fold(0.0, (sum, tx) => sum + tx.amount);
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final accountsAsync = ref.watch(accountsStreamProvider);
  
  return transactionsAsync.when(
    data: (transactions) {
      final allAccounts = accountsAsync.value ?? [];
      final enabledAccountIds = allAccounts.where((a) => a.isEnabled && !a.excludeFromTotal).map((a) => a.id).toSet();
      
      // Assuming transactions are already sorted by date descending from the stream
      return transactions
          .where((tx) => enabledAccountIds.contains(tx.accountId))
          .take(5)
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
