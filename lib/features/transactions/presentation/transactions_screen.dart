import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../core/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/account_providers.dart';
import '../../../core/models/transaction_category.dart';
import 'widgets/add_transaction_modal.dart';


class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String get currency => ref.watch(currencySymbolProvider);
      int _selectedFilterIndex = 0;
  
  final List<String> _filters = ['All', 'Today', 'Income', 'Expense', 'This Week', 'This Month'];

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsStreamProvider);
    final rate = ref.watch(currencyRateProvider);
    var transactions = txAsync.value ?? [];
    
    // Apply filters
    final now = DateTime.now();
    switch (_selectedFilterIndex) {
      case 1: // Today
        transactions = transactions.where((t) =>
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day
        ).toList();
        break;
      case 2: // Income
        transactions = transactions.where((t) => t.isIncome).toList();
        break;
      case 3: // Expense
        transactions = transactions.where((t) => !t.isIncome).toList();
        break;
      case 4: // This Week
        final weekAgo = now.subtract(const Duration(days: 7));
        transactions = transactions.where((t) => t.date.isAfter(weekAgo)).toList();
        break;
      case 5: // This Month
        transactions = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
        break;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110), // space for floating nav
        children: [
          _header(),
          const SizedBox(height: 16),
          _filterChips(),
          _periodSummaryBar(transactions, rate),
          const SizedBox(height: 14),
          if (txAsync.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (transactions.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Text('No transactions found', style: TextStyle(color: AppColors.muted(context)))),
            )
          else
            ...transactions.map((tx) => _buildTxItem(tx, rate)),
        ],
      ),
    );
  }

  Widget _periodSummaryBar(List<TransactionModel> txs, double rate) {
    if (_selectedFilterIndex == 0) return const SizedBox.shrink(); // All

    final formatter = NumberFormat('#,##0.00');
    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final enabledAccountIds = accounts
        .where((a) => a.isEnabled && !a.excludeFromTotal)
        .map((a) => a.id)
        .toSet();

    // Sum active main wallet transactions so period income matches Home Cash Flow exactly
    final activeTxs = txs.where((t) => enabledAccountIds.contains(t.accountId)).toList();
    final income = activeTxs.where((t) => t.isIncome).fold<double>(0.0, (sum, t) => sum + t.amount) * rate;
    final expense = activeTxs.where((t) => !t.isIncome).fold<double>(0.0, (sum, t) => sum + t.amount) * rate;
    final isDark = AppColors.isDark(context);
    final emeraldPrimary = isDark ? const Color(0xFF00D9A8) : const Color(0xFF005A36);
    final periodName = _filters[_selectedFilterIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.arrowDownLeft, size: 14, color: emeraldPrimary),
                const SizedBox(width: 5),
                Text('$periodName Income: Rs ${formatter.format(income)}',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: emeraldPrimary)),
              ],
            ),
            if (expense > 0)
              Row(
                children: [
                  const Icon(LucideIcons.arrowUpRight, size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 5),
                  Text('Expense: Rs ${formatter.format(expense)}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Recent', style: TextStyle(fontSize: 13, color: AppColors.muted(context))),
              Text('Transactions',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                      height: 1.1,
                      letterSpacing: -0.5)),
            ],
          ),
          Row(
            children: [
              _iconBtn(LucideIcons.search),
              const SizedBox(width: 10),
              _iconBtn(LucideIcons.listFilter),
            ],
          )
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return AppCard(
      padding: EdgeInsets.zero,
      isDark: true,
      centerGlow: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: AppColors.text(context).withOpacity(0.8), size: 20),
      ),
    );
  }

  Widget _filterChips() {
    final isDark = AppColors.isDark(context);
    final accentGreen = AppColors.accent(context);

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final active = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? accentGreen
                    : (isDark
                        ? (isDark ? AppColors.cardElevated.withOpacity(0.7) : const Color(0xFFF1F5F9))
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? accentGreen
                      : (isDark
                          ? AppColors.border
                          : AppColors.borderLight),
                  width: 1,
                ),
                boxShadow: active
                    ? [BoxShadow(color: AppColors.accentGlow(context), blurRadius: 14, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Center(
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active
                        ? Colors.white
                        : (isDark
                            ? (isDark ? AppColors.textPrimary.withOpacity(0.8) : AppColors.textMutedLight)
                            : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTxItem(TransactionModel tx, double rate) {
    final isExpense = !tx.isIncome;
    final isDark = AppColors.isDark(context);
    final accentGreen = AppColors.accent(context);
    final expenseColor = isDark ? const Color(0xFFFF5252) : const Color(0xFFDC2626);
    final color = isExpense ? expenseColor : accentGreen;
    final iconBg = isExpense
        ? (isDark ? expenseColor.withOpacity(0.12) : const Color(0xFFFEE2E2))
        : (isDark ? accentGreen.withOpacity(0.12) : AppColors.primaryLightTint);
    final icon = isExpense ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft;
    
    final allCategories = [...CategoryProvider.getIncomeCategories(), ...CategoryProvider.getExpenseCategories()];
    final categoryName = allCategories.firstWhere((c) => c.id == tx.categoryId, orElse: () => allCategories.first).name;

    final account = ref.watch(accountByIdProvider(tx.accountId));
    final defaultDesc = account?.name ?? categoryName;
    final dateFormatted = '${categoryName.isNotEmpty ? '$categoryName \u2022 ' : ''}${DateFormat('MMM dd, yyyy').format(tx.date)} \u2022 ${DateFormat('hh:mm a').format(tx.date)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      child: GestureDetector(
        onTap: () => AddTransactionModal.show(context, isExpense: isExpense, transaction: tx),
        child: AppCard(
          isDark: false,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.note.isNotEmpty ? tx.note : defaultDesc,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(dateFormatted, style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${isExpense ? '-' : '+'}${currency}${(tx.amount.abs() * rate).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
