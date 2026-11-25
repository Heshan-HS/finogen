import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/models/transaction_category.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/repositories/transaction_repository.dart';
import 'category_selector_sheet.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/account_providers.dart';
import '../../../../core/models/account_model.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  final bool isExpense;
  final TransactionModel? transactionToEdit;

  const AddTransactionModal({super.key, required this.isExpense, this.transactionToEdit});

  static Future<void> show(BuildContext context, {bool isExpense = true, TransactionModel? transaction}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(isExpense: isExpense, transactionToEdit: transaction),
    );
  }

  @override
  ConsumerState<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  String get currency => ref.watch(currencySymbolProvider);
  double get rate => ref.watch(currencyRateProvider);
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  TransactionCategory? _selectedCategory;
  DateTime _date = DateTime.now();
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final categories = widget.isExpense ? CategoryProvider.getExpenseCategories() : CategoryProvider.getIncomeCategories();
    
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _amountController.text = tx.amount.toString();
      _descController.text = tx.note;
      _date = tx.date;
      _selectedAccountId = tx.accountId;
      _selectedCategory = categories.firstWhere((c) => c.id == tx.categoryId, orElse: () => categories.first);
    } else if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0.0;
    
    if (amount <= 0) return;
    
    final tx = TransactionModel(
      id: widget.transactionToEdit?.id ?? '',
      userId: '', // Set by repository
      accountId: _selectedAccountId ?? '',
      amount: amount,
      categoryId: _selectedCategory!.id,
      note: _descController.text.trim(),
      date: _date,
      isIncome: widget.isExpense ? false : true,
    );
    
    try {
      if (mounted) Navigator.pop(context);
      if (widget.transactionToEdit != null) {
        await ref.read(transactionRepositoryProvider).updateTransaction(tx);
      } else {
        await ref.read(transactionRepositoryProvider).addTransaction(tx);
      }
    } catch (e) {
      debugPrint('Error saving transaction: $e');
    }
  }

  Widget _accountOption(AccountModel account) {
    final isSelected = _selectedAccountId == account.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccountId = account.id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.elevated(context) : AppColors.elevated(context).withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.accent(context).withOpacity(0.5) : AppColors.borderColor(context)),
        ),
        child: Opacity(
          opacity: isSelected ? 1.0 : 0.6,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(account.type == AccountType.creditCard ? LucideIcons.creditCard : (account.type == AccountType.bank ? LucideIcons.building : LucideIcons.wallet), size: 14, color: AppColors.accent(context)),
              const SizedBox(width: 8),
              Text(account.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text(context)),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
      cursorColor: AppColors.primary,
    );
  }

  Widget _detailRow(String label, {String? valueText, Widget? valueWidget, Widget? customInput, bool showArrow = false, IconData? icon, bool isLast = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: AppColors.text(context).withOpacity(0.9))),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (valueText != null)
                    Text(valueText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text(context))),
                  if (valueWidget != null)
                    valueWidget,
                  if (customInput != null)
                    Expanded(child: customInput),
                  if (showArrow)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(LucideIcons.chevronRight, size: 18, color: AppColors.text(context)),
                    ),
                  if (icon != null)
                    Icon(icon, size: 20, color: AppColors.text(context)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.transactionToEdit != null 
                    ? (widget.isExpense ? 'Edit Expense' : 'Edit Income') 
                    : (widget.isExpense ? 'Add Expense' : 'Add Income'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              if (widget.transactionToEdit != null)
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.red),
                  onPressed: () {
                    ref.read(transactionRepositoryProvider).deleteTransaction(widget.transactionToEdit!.id);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Amount Row
          Row(
            children: [
              Text('${currency}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text(context))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.text(context), letterSpacing: -1),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(color: AppColors.muted(context)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Wallet
          AppCard(
            isDark: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 16,
            child: Consumer(
              builder: (context, ref, child) {
                final accountsAsync = ref.watch(accountsStreamProvider);
                return accountsAsync.when(
                  data: (accounts) {
                    if (accounts.isEmpty) return const SizedBox.shrink();
                    
                    // Default to primary if not set
                    if (_selectedAccountId == null && accounts.isNotEmpty) {
                      Future.microtask(() => setState(() => _selectedAccountId = accounts.first.id));
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text(context))),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: accounts.map((acc) => _accountOption(acc)).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Details
          AppCard(
            isDark: true,
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              children: [
                _detailRow(
                  widget.isExpense ? 'Expense Category' : 'Income Category', 
                  valueWidget: _selectedCategory != null ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_selectedCategory!.icon, size: 16, color: _selectedCategory!.color),
                      const SizedBox(width: 8),
                      Text(_selectedCategory!.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text(context))),
                    ],
                  ) : null,
                  showArrow: true, 
                  onTap: () async {
                    final cat = await CategorySelectorSheet.show(context, isIncome: !widget.isExpense);
                    if (cat != null) setState(() => _selectedCategory = cat);
                  }
                ),
                _detailRow('Description', customInput: _buildTextField(_descController)),
                _detailRow('Date', valueText: _formatDate(_date), onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                }),
                _detailRow('Note', customInput: _buildTextField(_noteController), isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Save Button
          GestureDetector(
            onTap: _saveTransaction,
            child: Container(
              height: 60,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.accent(context).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Text(
                widget.transactionToEdit != null 
                    ? 'Update ${widget.isExpense ? 'Expense' : 'Income'}' 
                    : 'Create ${widget.isExpense ? 'Expense' : 'Income'}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentFg(context)),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
