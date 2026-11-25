import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/account_providers.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/account_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/repositories/transaction_repository.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  String? _sourceAccountId;
  String? _destAccountId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _executeTransfer() async {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (_sourceAccountId == null || _destAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select source and destination accounts')));
      return;
    }
    if (_sourceAccountId == _destAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source and destination cannot be the same')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      
      final sourceAccount = ref.read(accountByIdProvider(_sourceAccountId!));
      final destAccount = ref.read(accountByIdProvider(_destAccountId!));
      final sourceName = sourceAccount?.name ?? 'Account';
      final destName = destAccount?.name ?? 'Account';
      
      final customNote = _noteController.text.trim();
      final expenseNote = customNote.isEmpty ? 'Transfer to $destName' : 'Transfer to $destName ($customNote)';
      final incomeNote = customNote.isEmpty ? 'Transfer from $sourceName' : 'Transfer from $sourceName ($customNote)';
      
      final now = DateTime.now();
      
      // Expense from source
      final expenseTx = TransactionModel(
        id: '',
        userId: '',
        accountId: _sourceAccountId!,
        amount: amount,
        categoryId: 'exp_transfer', // Implicit transfer category
        note: expenseNote,
        date: now,
        isIncome: false,
      );

      // Income to destination
      final incomeTx = TransactionModel(
        id: '',
        userId: '',
        accountId: _destAccountId!,
        amount: amount,
        categoryId: 'inc_transfer', // Implicit transfer category
        note: incomeNote,
        date: now,
        isIncome: true,
      );

      await repo.addTransaction(expenseTx);
      await repo.addTransaction(incomeTx);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer successful')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transfer failed: ')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final accounts = accountsAsync.value ?? [];

    if (accounts.isNotEmpty && _sourceAccountId == null && _destAccountId == null) {
      _sourceAccountId = accounts.first.id;
      if (accounts.length > 1) {
        _destAccountId = accounts[1].id;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [
                      AppColors.primary.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    children: [
                      _accountSelectionCard(accounts),
                      const SizedBox(height: 32),
                      Center(
                        child: IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(context),
                              letterSpacing: -1,
                            ),
                            decoration: InputDecoration(
                              prefixText: currency,
                              prefixStyle: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text(context),
                                letterSpacing: -1,
                              ),
                              hintText: '0.00',
                              hintStyle: TextStyle(color: AppColors.muted(context).withOpacity(0.5)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _sourceAccountId != null ? 'Available: $currency${NumberFormat('#,##0.00').format(ref.watch(accountDerivedBalanceProvider(_sourceAccountId!)) * rate)}' : '',
                          style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      AppCard(
                        isDark: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Icon(LucideIcons.messageSquare, color: AppColors.muted(context), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _noteController,
                                style: TextStyle(color: AppColors.text(context), fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Add a note...',
                                  hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 14),
                                  border: InputBorder.none,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _isLoading ? null : _executeTransfer,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isLoading ? AppColors.primary.withOpacity(0.5) : AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppColors.accent(context).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg(context)))
                            : Text('Confirm Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.bg(context))),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AppCard(
              padding: const EdgeInsets.all(10),
              isDark: true,
              borderRadius: 12,
              child: Icon(LucideIcons.arrowLeft, color: AppColors.text(context), size: 20),
            ),
          ),
          Text('Transfer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text(context))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _accountSelectionCard(List<AccountModel> accounts) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            _accountItem('From', _sourceAccountId, accounts, (id) => setState(() => _sourceAccountId = id)),
            const SizedBox(height: 8),
            _accountItem('To', _destAccountId, accounts, (id) => setState(() => _destAccountId = id)),
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              final temp = _sourceAccountId;
              _sourceAccountId = _destAccountId;
              _destAccountId = temp;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.elevated(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderColor(context)),
              boxShadow: [
                BoxShadow(color: AppColors.isDark(context) ? Colors.black54 : const Color(0x10000000), blurRadius: 10),
              ],
            ),
            child: Icon(LucideIcons.arrowDownUp, color: AppColors.accent(context), size: 20),
          ),
        )
      ],
    );
  }

  Widget _accountItem(String label, String? selectedId, List<AccountModel> accounts, Function(String) onSelect) {
    final account = accounts.firstWhere((a) => a.id == selectedId, orElse: () => AccountModel(id: '', userId: '', name: 'Select Account', type: AccountType.bank, balance: 0, colorValue: 0));
    
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.bg(context),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Select  Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  ),
                  const SizedBox(height: 16),
                  ...accounts.map((acc) => ListTile(
                    title: Text(acc.name, style: TextStyle(color: AppColors.text(context))),
                    leading: Icon(LucideIcons.creditCard, color: AppColors.text(context)),
                    trailing: selectedId == acc.id ? Icon(LucideIcons.check, color: AppColors.accent(context)) : null,
                    onTap: () {
                      onSelect(acc.id);
                      Navigator.pop(context);
                    },
                  )),
                ],
              ),
            );
          },
        );
      },
      child: AppCard(
        isDark: true,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent(context).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.wallet, color: AppColors.accent(context), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                  const SizedBox(height: 2),
                  Text(account.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text(context))),
                ],
              ),
            ),
            Icon(LucideIcons.chevronDown, color: AppColors.muted(context), size: 20),
          ],
        ),
      ),
    );
  }
}
