import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/account_providers.dart';
import '../../../../core/repositories/goal_repository.dart';
import '../../../../core/repositories/transaction_repository.dart';
import '../../../../core/models/goal_model.dart';
import '../../../../core/models/transaction_model.dart';
import '../helpers/goal_category_helper.dart';

enum FundAction { deposit, withdraw, adjust }

class AddFundsSheet extends ConsumerStatefulWidget {
  final GoalModel goal;
  final FundAction initialAction;
  final bool initialWithdraw;

  const AddFundsSheet({
    super.key,
    required this.goal,
    this.initialAction = FundAction.deposit,
    this.initialWithdraw = false,
  });

  static Future<void> show(
    BuildContext context,
    GoalModel goal, {
    FundAction initialAction = FundAction.deposit,
    bool isWithdraw = false,
  }) {
    final action = isWithdraw ? FundAction.withdraw : initialAction;
    final isDesktop = MediaQuery.of(context).size.width > 700;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
            child: AddFundsSheet(goal: goal, initialAction: action),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: AddFundsSheet(goal: goal, initialAction: action),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends ConsumerState<AddFundsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late FundAction _currentAction;
  String? _selectedAccountId;
  bool _isSubmitting = false;

  // Dark emerald palette
  static const Color darkEmeraldDeep = Color(0xFF005A36);
  static const Color darkEmeraldLight = Color(0xFF007A4D);

  @override
  void initState() {
    super.initState();
    _currentAction = widget.initialWithdraw ? FundAction.withdraw : widget.initialAction;
    if (_currentAction == FundAction.adjust) {
      _amountController.text = widget.goal.currentAmount > 0
          ? (widget.goal.currentAmount % 1 == 0
              ? widget.goal.currentAmount.toInt().toString()
              : widget.goal.currentAmount.toStringAsFixed(2))
          : '0';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;

    if (_currentAction != FundAction.adjust && enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    if (_currentAction == FundAction.withdraw && enteredAmount > widget.goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot withdraw more than current savings (${widget.goal.currentAmount})')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final goalRepo = ref.read(goalRepositoryProvider);
      final txRepo = ref.read(transactionRepositoryProvider);

      double newCurrentAmount;
      double accountTxAmount = enteredAmount;
      bool isIncomeForAccount = false;

      if (_currentAction == FundAction.deposit) {
        newCurrentAmount = widget.goal.currentAmount + enteredAmount;
        isIncomeForAccount = false; // Expense from account
      } else if (_currentAction == FundAction.withdraw) {
        newCurrentAmount = (widget.goal.currentAmount - enteredAmount).clamp(0.0, double.infinity);
        isIncomeForAccount = true; // Refund back to account
      } else {
        // Adjust / Set exact balance
        newCurrentAmount = enteredAmount.clamp(0.0, double.infinity);
        final diff = newCurrentAmount - widget.goal.currentAmount;
        accountTxAmount = diff.abs();
        isIncomeForAccount = diff < 0; // If decreased, refund to account; if increased, charge account
      }

      // 1. Update Goal Amount
      final updatedGoal = widget.goal.copyWith(currentAmount: newCurrentAmount);
      await goalRepo.updateGoal(updatedGoal);

      // 2. If an account is selected and there's a non-zero financial flow, log transaction
      if (_selectedAccountId != null && _selectedAccountId != 'none' && accountTxAmount > 0) {
        final tx = TransactionModel(
          id: const Uuid().v4(),
          userId: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
          amount: accountTxAmount,
          isIncome: isIncomeForAccount,
          categoryId: 'transfer',
          date: DateTime.now(),
          accountId: _selectedAccountId!,
          note: _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : (_currentAction == FundAction.deposit
                  ? 'Savings Deposit • ${widget.goal.name}'
                  : (_currentAction == FundAction.withdraw
                      ? 'Savings Withdrawal • ${widget.goal.name}'
                      : 'Balance Correction • ${widget.goal.name}')),
        );
        await txRepo.addTransaction(tx);
      }

      if (mounted) {
        Navigator.pop(context);
        final bool reached = newCurrentAmount >= widget.goal.targetAmount && widget.goal.targetAmount > 0;
        final currency = ref.read(currencySymbolProvider);

        String successMsg;
        if (_currentAction == FundAction.deposit) {
          successMsg = 'Successfully deposited $currency ${NumberFormat('#,##0.00').format(enteredAmount)}!';
        } else if (_currentAction == FundAction.withdraw) {
          successMsg = 'Successfully withdrawn $currency ${NumberFormat('#,##0.00').format(enteredAmount)}!';
        } else {
          successMsg = 'Goal balance adjusted to $currency ${NumberFormat('#,##0.00').format(newCurrentAmount)}!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: reached ? const Color(0xFF00D4AA) : const Color(0xFF1E293B),
            content: Text(
              reached
                  ? '👑 Congratulations! You hit your goal for ${widget.goal.name}!'
                  : successMsg,
              style: TextStyle(
                color: reached ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final isDark = AppColors.isDark(context);
    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final decimalFormat = NumberFormat('#,##0.00');

    final categoryDef = GoalCategoryHelper.getCategory(widget.goal.category);

    // Calculate dynamic difference for adjust mode
    final currentVal = widget.goal.currentAmount;
    final enteredVal = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final diff = enteredVal - currentVal;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: darkEmeraldDeep.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: darkEmeraldDeep.withValues(alpha: 0.35)),
                      ),
                      child: Icon(
                        GoalCategoryHelper.getIcon(widget.goal.iconName, widget.goal.category),
                        color: darkEmeraldDeep,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.goal.name,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          categoryDef.label,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    LucideIcons.x,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3-Mode Segmented Switcher: Deposit / Withdraw / Fix Balance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildModeTab('Deposit (+)', LucideIcons.arrowDownLeft, FundAction.deposit, isDark),
                  _buildModeTab('Withdraw (-)', LucideIcons.arrowUpRight, FundAction.withdraw, isDark),
                  _buildModeTab('Fix Balance (=)', LucideIcons.sliders, FundAction.adjust, isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Scrollable Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Progress Preview Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Balance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currency ${decimalFormat.format(widget.goal.currentAmount)}',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : darkEmeraldDeep,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Target Vault',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currency ${decimalFormat.format(widget.goal.targetAmount)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_currentAction == FundAction.adjust) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: diff == 0
                                  ? Colors.grey.withValues(alpha: 0.15)
                                  : (diff > 0
                                      ? darkEmeraldDeep.withValues(alpha: 0.14)
                                      : Colors.redAccent.withValues(alpha: 0.14)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  diff == 0
                                      ? LucideIcons.equal
                                      : (diff > 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown),
                                  size: 13,
                                  color: diff == 0
                                      ? Colors.grey
                                      : (diff > 0 ? darkEmeraldDeep : Colors.redAccent),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  diff == 0
                                      ? 'No change in balance'
                                      : (diff > 0
                                          ? 'Correction: +$currency ${decimalFormat.format(diff)}'
                                          : 'Correction: -$currency ${decimalFormat.format(diff.abs())}'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: diff == 0
                                        ? Colors.grey
                                        : (diff > 0 ? darkEmeraldDeep : Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Amount Input
                  Text(
                    _currentAction == FundAction.adjust
                        ? 'ENTER NEW EXACT BALANCE'
                        : (_currentAction == FundAction.deposit ? 'DEPOSIT AMOUNT' : 'WITHDRAW AMOUNT'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : const Color(0xFF475569),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => setState(() {}),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _currentAction == FundAction.adjust
                          ? (isDark ? Colors.white : darkEmeraldDeep)
                          : (_currentAction == FundAction.deposit
                              ? (isDark ? Colors.white : darkEmeraldDeep)
                              : Colors.redAccent),
                    ),
                    decoration: InputDecoration(
                      prefixText: '$currency ',
                      prefixStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _currentAction == FundAction.withdraw ? Colors.redAccent : darkEmeraldDeep,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.replaceAll(',', ''));
                      if (n == null) return 'Invalid amount';
                      if (_currentAction != FundAction.adjust && n <= 0) return 'Must be greater than 0';
                      if (_currentAction == FundAction.withdraw && n > widget.goal.currentAmount) {
                        return 'Cannot exceed saved balance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quick Chips Row
                  if (_currentAction == FundAction.adjust)
                    Row(
                      children: [
                        _buildQuickSetChip('Reset (Rs 0)', 0),
                        const SizedBox(width: 8),
                        if (widget.goal.targetAmount > 0) ...[
                          _buildQuickSetChip('50% Target', widget.goal.targetAmount * 0.5),
                          const SizedBox(width: 8),
                          _buildQuickSetChip('100% Target', widget.goal.targetAmount),
                        ],
                      ],
                    )
                  else
                    Row(
                      children: [
                        _buildQuickChip('+1,000', 1000),
                        const SizedBox(width: 8),
                        _buildQuickChip('+5,000', 5000),
                        const SizedBox(width: 8),
                        _buildQuickChip('+10,000', 1000),
                        if (_currentAction == FundAction.withdraw && widget.goal.currentAmount > 0) ...[
                          const SizedBox(width: 8),
                          _buildQuickChip('All', widget.goal.currentAmount),
                        ],
                      ],
                    ),
                  const SizedBox(height: 18),

                  // Link Account Selector
                  Text(
                    _currentAction == FundAction.adjust
                        ? 'SYNC WITH ACCOUNT (OPTIONAL)'
                        : (_currentAction == FundAction.deposit ? 'PAY FROM ACCOUNT (OPTIONAL)' : 'DEPOSIT INTO ACCOUNT (OPTIONAL)'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : const Color(0xFF475569),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAccountId,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Select account (optional)',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'none',
                        child: Text('Do not sync with an account'),
                      ),
                      ...accounts.map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.name} ($currency ${decimalFormat.format(a.balance)})'),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  ),
                  const SizedBox(height: 18),

                  // Optional Note
                  Text(
                    'NOTE / REFERENCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : const Color(0xFF475569),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: _currentAction == FundAction.adjust
                          ? 'e.g. Corrected accidental deposit'
                          : 'e.g. Monthly salary savings',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: _currentAction == FundAction.adjust
                          ? const Color(0xFF1E293B)
                          : (_currentAction == FundAction.deposit ? darkEmeraldDeep : Colors.redAccent),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _currentAction == FundAction.adjust
                                    ? LucideIcons.checkCheck
                                    : (_currentAction == FundAction.deposit ? LucideIcons.plusCircle : LucideIcons.arrowUpRight),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _currentAction == FundAction.adjust
                                    ? 'Confirm Balance Correction'
                                    : (_currentAction == FundAction.deposit ? 'Confirm Deposit' : 'Confirm Withdrawal'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, IconData icon, FundAction action, bool isDark) {
    final isSelected = _currentAction == action;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentAction = action;
            if (action == FundAction.adjust) {
              _amountController.text = widget.goal.currentAmount > 0
                  ? (widget.goal.currentAmount % 1 == 0
                      ? widget.goal.currentAmount.toInt().toString()
                      : widget.goal.currentAmount.toStringAsFixed(2))
                  : '0';
            } else {
              _amountController.clear();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected && action == FundAction.deposit
                ? const LinearGradient(colors: [darkEmeraldLight, darkEmeraldDeep])
                : null,
            color: isSelected
                ? (action == FundAction.withdraw
                    ? Colors.redAccent
                    : (action == FundAction.adjust ? const Color(0xFF334155) : null))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, double value) {
    final isDark = AppColors.isDark(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _amountController.text = value.toStringAsFixed(0);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSetChip(String label, double value) {
    final isDark = AppColors.isDark(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _amountController.text = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
