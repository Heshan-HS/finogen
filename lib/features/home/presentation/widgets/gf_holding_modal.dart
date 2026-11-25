import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/account_providers.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/models/account_model.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/repositories/transaction_repository.dart';
import '../../../../core/repositories/account_repository.dart';

class GfHoldingModal extends ConsumerStatefulWidget {
  final int initialTab;
  const GfHoldingModal({super.key, this.initialTab = 0});

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    final isDesktop = MediaQuery.of(context).size.width > 680;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
            child: GfHoldingModal(initialTab: initialTab),
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
            child: GfHoldingModal(initialTab: initialTab),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<GfHoldingModal> createState() => _GfHoldingModalState();
}

class _GfHoldingModalState extends ConsumerState<GfHoldingModal> {
  late int _activeTab;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'This Month';
  DateTime _customMonth = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  AccountModel? _findGfAccount(List<AccountModel> accounts) {
    // Priority 1: Match specifically by name containing 'boc' or 'gf'
    for (var acc in accounts) {
      final lower = acc.name.toLowerCase();
      if (lower.contains('boc') || (lower.contains('gf') && lower.contains('holding'))) {
        return acc;
      }
    }
    // Priority 2: Exclude from total with holding in name
    for (var acc in accounts) {
      if (acc.excludeFromTotal && acc.name.toLowerCase().contains('holding')) {
        return acc;
      }
    }
    // Priority 3: Any excludeFromTotal account
    for (var acc in accounts) {
      if (acc.excludeFromTotal) {
        return acc;
      }
    }
    return null;
  }

  Future<void> _createGfAccount() async {
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(accountRepositoryProvider);
      final newAcc = AccountModel(
        id: '',
        userId: '',
        name: 'GF BOC (Holding)',
        type: AccountType.bank,
        balance: 0.0,
        creditLimit: 0.0,
        colorValue: 0xFFFFB300,
        isEnabled: true,
        excludeFromTotal: true,
      );
      await repo.addAccount(newAcc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GF BOC Holding Account activated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating account: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitQuickPayment(AccountModel gfAccount) async {
    final amtText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amtText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final note = _noteController.text.trim();
      final tx = TransactionModel(
        id: '',
        userId: '',
        accountId: gfAccount.id,
        amount: amount,
        categoryId: 'business_income',
        note: note.isEmpty ? 'Client Payment (GF BOC)' : note,
        date: _selectedDate,
        isIncome: true,
      );
      await repo.addTransaction(tx);
      _amountController.clear();
      _noteController.clear();
      _selectedDate = DateTime.now();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('Saved +Rs ${amount.toStringAsFixed(2)} to GF BOC Holding!'),
          ),
        );
        setState(() {
          _activeTab = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showTransferDialog(AccountModel gfAccount, double currentBalance) async {
    final isDark = AppColors.isDark(context);
    final accounts = ref.read(accountsStreamProvider).value ?? [];
    final otherAccounts = accounts.where((a) => a.id != gfAccount.id && a.isEnabled).toList();

    if (otherAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other active accounts available to transfer into')),
      );
      return;
    }

    String selectedDestId = otherAccounts.first.id;
    final transferAmtCtrl = TextEditingController(
      text: currentBalance > 0 ? currentBalance.toStringAsFixed(2) : '',
    );
    final transferNoteCtrl = TextEditingController();

    final dialogBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final dialogBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final inputBg = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? Colors.white12 : const Color(0xFFCBD5E1);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: dialogBorder),
          ),
          title: Row(
            children: [
              Icon(LucideIcons.arrowRightLeft, color: isDark ? AppColors.primary : AppColors.primaryLight, size: 20),
              const SizedBox(width: 10),
              Text(
                'Transfer to My Account',
                style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transfer funds held by GF into your main account.', style: TextStyle(color: AppColors.muted(context), fontSize: 12)),
              const SizedBox(height: 16),
              Text('Destination Account', style: TextStyle(color: AppColors.text(context), fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: inputBorder),
                ),
                child: DropdownButton<String>(
                  value: selectedDestId,
                  isExpanded: true,
                  dropdownColor: dialogBg,
                  underline: const SizedBox.shrink(),
                  items: otherAccounts.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name, style: TextStyle(color: AppColors.text(context))),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => selectedDestId = v);
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text('Amount to Transfer', style: TextStyle(color: AppColors.text(context), fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: transferAmtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: 'Rs ',
                  prefixStyle: TextStyle(color: isDark ? AppColors.primary : AppColors.primaryLight, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Text('Note (Optional)', style: TextStyle(color: AppColors.text(context), fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: transferNoteCtrl,
                style: TextStyle(color: AppColors.text(context), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. GF transferred cash to my account',
                  hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 13),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.primary : AppColors.primaryLight,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              onPressed: () async {
                final amt = double.tryParse(transferAmtCtrl.text.replaceAll(',', ''));
                if (amt == null || amt <= 0) return;

                final repo = ref.read(transactionRepositoryProvider);
                final destAcc = otherAccounts.firstWhere((a) => a.id == selectedDestId);
                final note = transferNoteCtrl.text.trim();
                final now = DateTime.now();

                // 1. Expense from GF BOC
                await repo.addTransaction(TransactionModel(
                  id: '',
                  userId: '',
                  accountId: gfAccount.id,
                  amount: amt,
                  categoryId: 'settlement_transfer',
                  note: note.isEmpty ? 'Transferred to ${destAcc.name}' : 'Transferred to ${destAcc.name} ($note)',
                  date: now,
                  isIncome: false,
                ));

                // 2. Income to Destination Account
                await repo.addTransaction(TransactionModel(
                  id: '',
                  userId: '',
                  accountId: destAcc.id,
                  amount: amt,
                  categoryId: 'settlement_transfer',
                  note: note.isEmpty ? 'From GF BOC Holding' : 'From GF BOC Holding ($note)',
                  date: now,
                  isIncome: true,
                ));

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully transferred Rs ${amt.toStringAsFixed(2)} to ${destAcc.name}!')),
                  );
                }
              },
              child: const Text('Confirm Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final currency = ref.watch(currencySymbolProvider);
    final decimalFormat = NumberFormat('#,##0.00');

    final containerBg = isDark ? const Color(0xFF090D16) : Colors.white;
    final containerBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final containerShadow = isDark
        ? const BoxShadow(color: Colors.black87, blurRadius: 30, offset: Offset(0, 10))
        : const BoxShadow(color: Color(0x180F172A), blurRadius: 28, offset: Offset(0, 8));

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: containerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: containerBorder),
        boxShadow: [containerShadow],
      ),
      child: accountsAsync.when(
        data: (accounts) {
          final gfAccount = _findGfAccount(accounts);
          if (gfAccount == null) {
            return _buildActivationView();
          }
          return _buildMainView(gfAccount, currency, decimalFormat);
        },
        loading: () => Center(child: CircularProgressIndicator(color: isDark ? AppColors.primary : AppColors.primaryLight)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
      ),
    ),
    );
  }

  Widget _buildActivationView() {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.amber.withOpacity(0.12) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.landmark, color: isDark ? Colors.amber : const Color(0xFFD97706), size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'GF BOC Holding Account',
            style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep client payments that enter your girlfriend\'s BOC account completely separate from your main personal balance.',
            style: TextStyle(color: AppColors.muted(context), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _isSubmitting
              ? CircularProgressIndicator(color: isDark ? AppColors.primary : AppColors.primaryLight)
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(LucideIcons.sparkles),
                  label: const Text('Activate GF BOC Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _createGfAccount,
                ),
        ],
      ),
    );
  }

  Widget _buildMainView(AccountModel gfAccount, String currency, NumberFormat decimalFormat) {
    final isDark = AppColors.isDark(context);
    final currentBalance = ref.watch(accountDerivedBalanceProvider(gfAccount.id));
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final allTx = (transactionsAsync.value ?? [])
        .where((t) => t.accountId == gfAccount.id || t.note.contains('(GF BOC)') || t.note.toLowerCase().contains('gf boc'))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);

    // Period calculations
    final List<TransactionModel> periodTx;
    switch (_selectedFilter) {
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        periodTx = allTx.where((t) => t.date.isAfter(weekAgo)).toList();
        break;
      case 'Last Month':
        periodTx = allTx.where((t) => t.date.year == prevMonth.year && t.date.month == prevMonth.month).toList();
        break;
      case 'Custom Month':
        periodTx = allTx.where((t) => t.date.year == _customMonth.year && t.date.month == _customMonth.month).toList();
        break;
      case 'This Month':
      default:
        periodTx = allTx.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
        break;
    }

    final double periodIncome = periodTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final int periodIncomeCount = periodTx.where((t) => t.isIncome).length;

    // Fast comparative metrics
    final double thisWeekIncome = allTx
        .where((t) => t.isIncome && t.date.isAfter(now.subtract(const Duration(days: 7))))
        .fold(0.0, (s, t) => s + t.amount);
    final double thisMonthIncome = allTx
        .where((t) => t.isIncome && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
    final double lastMonthIncome = allTx
        .where((t) => t.isIncome && t.date.year == prevMonth.year && t.date.month == prevMonth.month)
        .fold(0.0, (s, t) => s + t.amount);

    // Dynamic banner colors
    final amberIconBg = isDark ? Colors.amber.withOpacity(0.18) : const Color(0xFFFEF3C7);
    final amberColor = isDark ? Colors.amber : const Color(0xFFD97706);
    final bannerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB);
    final bannerBorder = isDark ? Colors.amber.withOpacity(0.3) : const Color(0xFFFDE68A);
    final bannerLabelColor = isDark ? Colors.amber : const Color(0xFFB45309);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: amberIconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(LucideIcons.landmark, color: amberColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gfAccount.name,
                        style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Custodial Holding • Excluded from Main Balance',
                        style: TextStyle(color: AppColors.muted(context), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Icon(LucideIcons.x, color: AppColors.muted(context), size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Live Held Balance Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bannerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bannerBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Currently With GF (Holding)', style: TextStyle(color: bannerLabelColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '$currency ${decimalFormat.format(currentBalance)}',
                      style: TextStyle(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white12 : Colors.white,
                    foregroundColor: AppColors.text(context),
                    elevation: isDark ? 0 : 1,
                    side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(LucideIcons.arrowRightLeft, size: 14, color: isDark ? AppColors.primary : AppColors.primaryLight),
                  label: const Text('Transfer to Me', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showTransferDialog(gfAccount, currentBalance),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Mode Navigation Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildNavTab(
                  index: 0,
                  icon: LucideIcons.zap,
                  label: 'Quick Add Payment',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNavTab(
                  index: 1,
                  icon: LucideIcons.barChart2,
                  label: 'Analytics & History',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(color: AppColors.borderColor(context), height: 1),

        // Tab Content
        Expanded(
          child: _activeTab == 0
              ? _buildQuickAddTab(gfAccount, currency)
              : _buildAnalyticsTab(
                  periodTx: periodTx,
                  periodIncome: periodIncome,
                  periodCount: periodIncomeCount,
                  thisWeekIncome: thisWeekIncome,
                  thisMonthIncome: thisMonthIncome,
                  lastMonthIncome: lastMonthIncome,
                  currency: currency,
                  decimalFormat: decimalFormat,
                ),
        ),
      ],
    );
  }

  Widget _buildNavTab({required int index, required IconData icon, required String label}) {
    final isDark = AppColors.isDark(context);
    final isSelected = _activeTab == index;
    final activeBg = isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primaryLightTint;
    final activeColor = isDark ? AppColors.primary : AppColors.primaryLight;
    final inactiveBg = isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF1F5F9);
    final inactiveBorder = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
    final inactiveColor = AppColors.muted(context);

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : inactiveBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : inactiveColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddTab(AccountModel gfAccount, String currency) {
    final isDark = AppColors.isDark(context);
    final inputBg = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? Colors.white12 : const Color(0xFFCBD5E1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount Received', style: TextStyle(color: AppColors.text(context), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            autofocus: false,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.text(context), fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '$currency ',
              prefixStyle: TextStyle(color: isDark ? AppColors.primary : AppColors.primaryLight, fontSize: 24, fontWeight: FontWeight.bold),
              hintText: '0.00',
              hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 28),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.primary : AppColors.primaryLight, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [100, 150, 200, 250, 350, 400, 450, 500, 600].map((amt) {
              final isSelected = _amountController.text.trim() == amt.toString();
              return ActionChip(
                backgroundColor: isSelected
                    ? (isDark ? AppColors.primary.withOpacity(0.2) : const Color(0xFFDCFCE7))
                    : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
                side: BorderSide(
                  color: isSelected
                      ? (isDark ? AppColors.primary : const Color(0xFF16A34A))
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1,
                ),
                label: Text(
                  'Rs $amt',
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                        : AppColors.text(context),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _amountController.text = amt.toString();
                    _amountController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _amountController.text.length),
                    );
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Optional Client Name
          Text('Client / Note (Optional)', style: TextStyle(color: AppColors.text(context), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            style: TextStyle(color: AppColors.text(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Kasun - SpeedNet 6M / Client Payment',
              hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 13),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.primary : AppColors.primaryLight, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Date / Time Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.clock, color: AppColors.muted(context), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Time: ${DateFormat('dd MMM yyyy • hh:mm a').format(_selectedDate)}',
                    style: TextStyle(color: AppColors.muted(context), fontSize: 11),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        _selectedDate.hour,
                        _selectedDate.minute,
                      );
                    });
                  }
                },
                child: Text('Change Date', style: TextStyle(color: isDark ? AppColors.primary : AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.primary : AppColors.primaryLight,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSubmitting
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.plusCircle, size: 18),
              label: const Text('Save to GF BOC (Holding)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: _isSubmitting ? null : () => _submitQuickPayment(gfAccount),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab({
    required List<TransactionModel> periodTx,
    required double periodIncome,
    required int periodCount,
    required double thisWeekIncome,
    required double thisMonthIncome,
    required double lastMonthIncome,
    required String currency,
    required NumberFormat decimalFormat,
  }) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Column(
      children: [
        // Filter Pills
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('This Month'),
                const SizedBox(width: 8),
                _buildFilterChip('This Week'),
                const SizedBox(width: 8),
                _buildFilterChip('Last Month'),
                const SizedBox(width: 8),
                _buildFilterChip('Custom Month'),
              ],
            ),
          ),
        ),

        // Quick Period Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Received in $_selectedFilter:',
                      style: TextStyle(color: AppColors.text(context), fontSize: 12),
                    ),
                    Text(
                      '$currency ${decimalFormat.format(periodIncome)}',
                      style: TextStyle(color: isDark ? AppColors.primary : AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$periodCount client payment(s)',
                      style: TextStyle(color: AppColors.muted(context), fontSize: 11),
                    ),
                    if (_selectedFilter == 'Custom Month')
                      Text(
                        DateFormat('MMMM yyyy').format(_customMonth),
                        style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: cardBorder, height: 1),
                const SizedBox(height: 8),

                // Comparative Badges
                Row(
                  children: [
                    Expanded(child: _buildStatMiniBadge('This Week', '$currency${decimalFormat.format(thisWeekIncome)}')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatMiniBadge('This Month', '$currency${decimalFormat.format(thisMonthIncome)}')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatMiniBadge('Last Month', '$currency${decimalFormat.format(lastMonthIncome)}')),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Transaction List Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transaction History', style: TextStyle(color: AppColors.text(context), fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${periodTx.length} items', style: TextStyle(color: AppColors.muted(context), fontSize: 11)),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: periodTx.isEmpty
              ? Center(
                  child: Text('No payments found in this period', style: TextStyle(color: AppColors.muted(context), fontSize: 12)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  itemCount: periodTx.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = periodTx[index];
                    final isInc = tx.isIncome;
                    final incColor = isDark ? AppColors.primary : AppColors.primaryLight;
                    final incBg = isDark ? AppColors.primary.withOpacity(0.12) : AppColors.primaryLightTint;
                    final outColor = isDark ? Colors.blueAccent : const Color(0xFF2563EB);
                    final outBg = isDark ? Colors.blueAccent.withOpacity(0.12) : const Color(0xFFEFF6FF);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isInc ? incBg : outBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInc ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                              color: isInc ? incColor : outColor,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.note.isEmpty ? 'Client Payment' : tx.note,
                                  style: TextStyle(color: AppColors.text(context), fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy • hh:mm a').format(tx.date),
                                  style: TextStyle(color: AppColors.muted(context), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isInc ? '+' : '-'}$currency ${decimalFormat.format(tx.amount)}',
                            style: TextStyle(
                              color: isInc ? incColor : outColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _deleteTx(tx.id),
                            child: Icon(LucideIcons.trash2, size: 14, color: AppColors.muted(context)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatMiniBadge(String title, String val) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppColors.muted(context), fontSize: 9)),
          const SizedBox(height: 1),
          Text(val, style: TextStyle(color: AppColors.text(context), fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isDark = AppColors.isDark(context);
    final isSelected = _selectedFilter == label;
    final activeBg = isDark ? AppColors.primary : AppColors.primaryLight;
    final activeFg = isDark ? Colors.black : Colors.white;
    final inactiveBg = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9);
    final inactiveBorder = isDark ? Colors.white12 : const Color(0xFFCBD5E1);

    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? activeFg : AppColors.text(context), fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: activeBg,
      backgroundColor: inactiveBg,
      side: BorderSide(color: isSelected ? activeBg : inactiveBorder),
      onSelected: (val) async {
        if (label == 'Custom Month') {
          final picked = await showDatePicker(
            context: context,
            initialDate: _customMonth,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            helpText: 'Select Month',
          );
          if (picked != null) {
            setState(() {
              _customMonth = picked;
              _selectedFilter = label;
            });
          }
        } else {
          setState(() => _selectedFilter = label);
        }
      },
    );
  }

  Future<void> _deleteTx(String id) async {
    final isDark = AppColors.isDark(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text('Delete Transaction', style: TextStyle(color: AppColors.text(context))),
        content: Text('Are you sure you want to delete this payment record?', style: TextStyle(color: AppColors.muted(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: AppColors.muted(context)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(transactionRepositoryProvider).deleteTransaction(id);
    }
  }
}
