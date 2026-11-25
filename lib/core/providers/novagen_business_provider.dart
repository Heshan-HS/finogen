import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import 'transaction_providers.dart';

class NovaGenBusinessState {
  final double baseRevenue;
  final double baseExpenses;
  final double historicalServerCost;
  final double monthlyServerFee;
  final int serverRenewalDay;
  final double baseNetProfit;

  final double dynamicRevenue;
  final double dynamicExpenses;
  final double dynamicServerCost;
  final List<TransactionModel> businessTransactions;

  final double todayRevenue;
  final double thisWeekRevenue;
  final double thisMonthRevenue;

  final bool isServerPaidThisCycle;
  final DateTime? lastServerPaymentDate;

  const NovaGenBusinessState({
    required this.baseRevenue,
    required this.baseExpenses,
    required this.historicalServerCost,
    required this.monthlyServerFee,
    required this.serverRenewalDay,
    this.baseNetProfit = 64611.12,
    this.dynamicRevenue = 0.0,
    this.dynamicExpenses = 0.0,
    this.dynamicServerCost = 0.0,
    this.businessTransactions = const [],
    this.todayRevenue = 0.0,
    this.thisWeekRevenue = 0.0,
    this.thisMonthRevenue = 0.0,
    this.isServerPaidThisCycle = false,
    this.lastServerPaymentDate,
  });

  double get totalRevenue => baseRevenue + dynamicRevenue;
  double get totalExpenses => baseExpenses + dynamicExpenses;
  double get totalServerCost => historicalServerCost + dynamicServerCost;

  // Real Net Profit = baseNetProfit + dynamicRevenue - dynamicServerCost
  // Strictly only Netcup server VPS expenses are business costs for NovaGen. All other personal expenses deduct only from Total Balance.
  double get netProfit => baseNetProfit + dynamicRevenue - dynamicServerCost;

  // Next Server Renewal Date (22nd of every month)
  DateTime get nextRenewalDate {
    final now = DateTime.now();
    if (isServerPaidThisCycle) {
      return DateTime(now.year, now.month + 1, serverRenewalDay);
    }
    DateTime next = DateTime(now.year, now.month, serverRenewalDay);
    if (now.isAfter(next) && now.day > serverRenewalDay) {
      next = DateTime(now.year, now.month + 1, serverRenewalDay);
    }
    return next;
  }

  // Days left until renewal
  int get daysUntilRenewal {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextRenewalDate.year, nextRenewalDate.month, nextRenewalDate.day);
    return target.difference(today).inDays;
  }

  // Status badge text
  String get renewalStatusBadge {
    if (isServerPaidThisCycle) {
      return 'Paid • ${daysUntilRenewal}d left';
    }
    if (daysUntilRenewal == 0) {
      return 'Due Today';
    } else if (daysUntilRenewal < 0) {
      return 'Overdue ${daysUntilRenewal.abs()}d';
    } else {
      return 'Due in ${daysUntilRenewal} days';
    }
  }

  NovaGenBusinessState copyWith({
    double? baseRevenue,
    double? baseExpenses,
    double? historicalServerCost,
    double? monthlyServerFee,
    int? serverRenewalDay,
    double? baseNetProfit,
    double? dynamicRevenue,
    double? dynamicExpenses,
    double? dynamicServerCost,
    List<TransactionModel>? businessTransactions,
    bool? isServerPaidThisCycle,
    DateTime? lastServerPaymentDate,
  }) {
    return NovaGenBusinessState(
      baseRevenue: baseRevenue ?? this.baseRevenue,
      baseExpenses: baseExpenses ?? this.baseExpenses,
      historicalServerCost: historicalServerCost ?? this.historicalServerCost,
      monthlyServerFee: monthlyServerFee ?? this.monthlyServerFee,
      serverRenewalDay: serverRenewalDay ?? this.serverRenewalDay,
      baseNetProfit: baseNetProfit ?? this.baseNetProfit,
      dynamicRevenue: dynamicRevenue ?? this.dynamicRevenue,
      dynamicExpenses: dynamicExpenses ?? this.dynamicExpenses,
      dynamicServerCost: dynamicServerCost ?? this.dynamicServerCost,
      businessTransactions: businessTransactions ?? this.businessTransactions,
      todayRevenue: todayRevenue,
      thisWeekRevenue: thisWeekRevenue,
      thisMonthRevenue: thisMonthRevenue,
      isServerPaidThisCycle: isServerPaidThisCycle ?? this.isServerPaidThisCycle,
      lastServerPaymentDate: lastServerPaymentDate ?? this.lastServerPaymentDate,
    );
  }
}

// Cutoff timestamp for dynamic transactions to ensure historical base numbers are preserved exactly
final DateTime novagenCutoffDate = DateTime(2026, 10, 17, 16, 0);

final novagenBusinessProvider = Provider<NovaGenBusinessState>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final allTx = transactionsAsync.value ?? [];

  // Base numbers verified by Heshan
  const double baseRev = 99060.0;
  const double baseExp = 35500.0;
  const double baseServer = 8948.88;
  const int renewalDay = 22;

  double dynRev = 0.0;
  double dynExp = 0.0;
  double dynServer = 0.0;
  final List<TransactionModel> bizTx = [];

  for (var tx in allTx) {
    final noteLower = tx.note.toLowerCase();

    // Check if this is Father's allowance
    final bool isFatherTx = tx.categoryId == 'inc_salary' ||
        noteLower.contains('father') ||
        noteLower.contains('standing instruction') ||
        noteLower.contains('sallery') ||
        ((tx.amount - 10000.0).abs() < 1.0 && tx.isIncome);

    // STRICT RULE: ONLY Netcup Server expenses are business expenses for NovaGen SpeedNet
    final bool isNetcupTx = !tx.isIncome && (
        tx.categoryId == 'exp_novagen_server' ||
        noteLower.contains('netcup') ||
        noteLower.contains('foreign pos')
    );

    // Strict Rule: No client payment exceeds Rs 600.
    // Self-transfers (e.g. eZ Cash to NTB of Rs 13,900) or bank interest must NEVER be counted as business revenue
    final bool isInternalTransfer = tx.amount > 600.0 ||
        noteLower.contains('self transfer') ||
        noteLower.contains('internal transfer') ||
        noteLower.contains('int.pd') ||
        noteLower.contains('wtax');

    // Business income: Real client payments arriving via NTB, eZ Cash, or BOC (All 3 channels, <= Rs 600)
    final bool isBusinessIncome = tx.isIncome && !isFatherTx && !isInternalTransfer && tx.amount <= 600.0 && (
        tx.categoryId == 'inc_novagen' ||
        tx.categoryId == 'business_income' ||
        tx.categoryId == 'inc_transfer' ||
        tx.note.contains('(GF BOC)') ||
        noteLower.contains('gf boc') ||
        noteLower.contains('boc') ||
        noteLower.contains('novagen') ||
        noteLower.contains('speednet') ||
        noteLower.contains('ez cash') ||
        noteLower.contains('cefts') ||
        noteLower.contains('fund trf') ||
        noteLower.contains('nations') ||
        noteLower.contains('ntb')
    );

    // Explicit manual drawing recorded via NovaGen Quick Add
    final bool isManualDraw = !tx.isIncome && tx.categoryId == 'exp_novagen_draw';

    // Only business revenue, Netcup server hosting expenses, and explicit manual drawings belong to NovaGen SpeedNet
    if (isBusinessIncome || isNetcupTx || isManualDraw) {
      bizTx.add(tx);

      // Dynamic accumulation for transactions occurring after cutoff
      if (tx.date.isAfter(novagenCutoffDate)) {
        if (isNetcupTx) {
          dynServer += tx.amount;
        } else if (isBusinessIncome) {
          dynRev += tx.amount;
        } else if (isManualDraw) {
          dynExp += tx.amount;
        }
      }
    }
  }

  bizTx.sort((a, b) => b.date.compareTo(a.date));

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

  double todaySpeedNet = 0.0;
  double weekSpeedNet = 0.0;
  double monthSpeedNet = 0.0;

  for (var tx in bizTx) {
    if (!tx.isIncome) continue;
    if (tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day) {
      todaySpeedNet += tx.amount;
    }
    if (tx.date.isAfter(weekStart) || tx.date.isAtSameMomentAs(weekStart)) {
      weekSpeedNet += tx.amount;
    }
    if (tx.date.year == now.year && tx.date.month == now.month) {
      monthSpeedNet += tx.amount;
    }
  }

  // Dynamic tracking of Netcup Server VPS renewal from actual bank foreign POS transactions
  double effectiveMonthlyServer = 2504.33; // Default to latest known foreign POS rate
  DateTime? latestServerPaymentDate;

  for (var tx in bizTx) {
    final noteLower = tx.note.toLowerCase();
    final bool isNetcupTx = !tx.isIncome && (
        tx.categoryId == 'exp_novagen_server' ||
        noteLower.contains('netcup') ||
        noteLower.contains('foreign pos')
    );
    if (isNetcupTx) {
      if (latestServerPaymentDate == null || tx.date.isAfter(latestServerPaymentDate)) {
        latestServerPaymentDate = tx.date;
        effectiveMonthlyServer = tx.amount;
      }
    }
  }

  // Determine if server fee has been paid for the current monthly cycle (22nd)
  bool serverPaidThisCycle = false;
  if (latestServerPaymentDate != null) {
    final bool sameMonthPaid = latestServerPaymentDate.year == now.year &&
        latestServerPaymentDate.month == now.month &&
        latestServerPaymentDate.day >= 20;
    final int daysAgo = now.difference(latestServerPaymentDate).inDays;
    if (sameMonthPaid || (daysAgo >= 0 && daysAgo < 28)) {
      serverPaidThisCycle = true;
    }
  }

  return NovaGenBusinessState(
    baseRevenue: baseRev,
    baseExpenses: baseExp,
    historicalServerCost: baseServer,
    monthlyServerFee: effectiveMonthlyServer,
    serverRenewalDay: renewalDay,
    baseNetProfit: 64611.12,
    dynamicRevenue: dynRev,
    dynamicExpenses: dynExp,
    dynamicServerCost: dynServer,
    businessTransactions: bizTx,
    todayRevenue: todaySpeedNet,
    thisWeekRevenue: weekSpeedNet,
    thisMonthRevenue: monthSpeedNet,
    isServerPaidThisCycle: serverPaidThisCycle,
    lastServerPaymentDate: latestServerPaymentDate,
  );
});
