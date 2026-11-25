import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/account_providers.dart';
import '../../../../core/providers/novagen_business_provider.dart';
import '../../../../core/models/account_model.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/repositories/transaction_repository.dart';

class NovaGenBusinessModal extends ConsumerStatefulWidget {
  final int initialTab;
  const NovaGenBusinessModal({super.key, this.initialTab = 0});

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
            child: NovaGenBusinessModal(initialTab: initialTab),
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
            child: NovaGenBusinessModal(initialTab: initialTab),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<NovaGenBusinessModal> createState() => _NovaGenBusinessModalState();
}

class _NovaGenBusinessModalState extends ConsumerState<NovaGenBusinessModal> {
  late int _activeTab;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedTxType = 'client_payment'; // client_payment, drawing, server_cost
  String? _selectedAccountId;
  bool _isSubmitting = false;

  final List<double> _quickAmounts = [100, 150, 200, 250, 350, 400, 450, 500, 600];

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

  Future<void> _handleQuickAdd() async {
    final text = _amountController.text.trim();
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final accounts = ref.read(accountsStreamProvider).value ?? [];
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No accounts available to link transaction')),
      );
      return;
    }

    AccountModel? targetAccount;
    if (_selectedAccountId != null) {
      targetAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a?.id == _selectedAccountId,
        orElse: () => null,
      );
    }

    // Default account priority for NovaGen SpeedNet: Ez Cash SIM 2, then Dialog New, then Nations
    targetAccount ??= accounts.cast<AccountModel?>().firstWhere(
      (a) => a != null && (a.name.contains('769169810') || a.name.toLowerCase().contains('sim 2')),
      orElse: () => null,
    );
    targetAccount ??= accounts.cast<AccountModel?>().firstWhere(
      (a) => a != null && a.name.toLowerCase().contains('dialog') && a.name.toLowerCase().contains('new'),
      orElse: () => null,
    );
    targetAccount ??= accounts.first;

    setState(() => _isSubmitting = true);

    try {
      final bool isIncome = _selectedTxType == 'client_payment';
      final String categoryId = isIncome
          ? 'inc_novagen'
          : (_selectedTxType == 'server_cost' ? 'exp_novagen_server' : 'exp_novagen_draw');

      String defaultNote = 'NovaGen Client Subscription';
      if (_selectedTxType == 'server_cost') defaultNote = 'Netcup Server VPS Renewal';
      if (_selectedTxType == 'drawing') defaultNote = 'NovaGen Personal Drawing';

      final String finalNote = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : defaultNote;

      final txRepo = ref.read(transactionRepositoryProvider);
      final newTx = TransactionModel(
        id: const Uuid().v4(),
        userId: 'guest',
        accountId: targetAccount.id,
        amount: amount,
        categoryId: categoryId,
        note: finalNote,
        date: _selectedDate,
        isIncome: isIncome,
      );

      await txRepo.addTransaction(newTx);

      if (mounted) {
        _amountController.clear();
        _noteController.clear();
        final emerald = AppColors.isDark(context) ? const Color(0xFF00D9A8) : const Color(0xFF005A36);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: emerald,
            content: Text(
              'Successfully recorded Rs ' + amount.toStringAsFixed(2) + ' to ' + targetAccount.name + '!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        setState(() {
          _activeTab = 1; // Switch to stats tab to see the updated figures
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final businessState = ref.watch(novagenBusinessProvider);
    final currency = ref.watch(currencySymbolProvider);
    final decimalFormat = NumberFormat('#,##0.00');

    final containerBg = isDark ? const Color(0xFF061210) : Colors.white;
    final containerBorder = isDark ? const Color(0x3000D9A8) : const Color(0x35005A36);
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
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildTabBar(context, isDark),
            Expanded(
              child: IndexedStack(
                index: _activeTab,
                children: [
                  _buildQuickAddTab(context, isDark, currency),
                  _buildStatsTab(context, isDark, businessState, currency, decimalFormat),
                  _buildHistoryTab(context, isDark, businessState, currency, decimalFormat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final emeraldPrimary = isDark ? const Color(0xFF00D9A8) : const Color(0xFF005A36);
    final emeraldTint = isDark ? const Color(0x1F00D9A8) : const Color(0xFFE8F5ED);
    final textDark = isDark ? const Color(0xFFF2FAF6) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: emeraldTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: emeraldPrimary.withOpacity(0.25)),
                ),
                child: Icon(LucideIcons.globe, color: emeraldPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NovaGen SpeedNet',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'VPN Business & Netcup VPS Hub',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(LucideIcons.x, color: textMuted, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDark) {
    final emeraldPrimary = isDark ? const Color(0xFF00D9A8) : const Color(0xFF005A36);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _tabButton('Quick Add', LucideIcons.plusCircle, 0, emeraldPrimary),
            _tabButton('VPS & P&L', LucideIcons.server, 1, emeraldPrimary),
            _tabButton('History', LucideIcons.history, 2, emeraldPrimary),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String title, IconData icon, int index, Color emeraldPrimary) {
    final isActive = _activeTab == index;
    final isDark = AppColors.isDark(context);

    final activeBg = isDark ? emeraldPrimary.withOpacity(0.18) : emeraldPrimary;
    final activeFg = isDark ? emeraldPrimary : Colors.white;
    final inactiveFg = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive && !isDark
                ? [BoxShadow(color: emeraldPrimary.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? activeFg : inactiveFg,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? activeFg : inactiveFg,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddTab(BuildContext context, bool isDark, String currency) {
    final emeraldPrimary = isDark ? const Color(0xFF00D9A8) : const Color(0xFF005A36);
    final textDark = isDark ? const Color(0xFFF2FAF6) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);
    final accounts = ref.watch(accountsStreamProvider).value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Type Selector
          Text('TRANSACTION TYPE', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: [
              _typePill('client_payment', 'Client Payment', LucideIcons.arrowDownLeft, emeraldPrimary),
              const SizedBox(width: 8),
              _typePill('drawing', 'Personal Draw', LucideIcons.wallet, emeraldPrimary),
              const SizedBox(width: 8),
              _typePill('server_cost', 'Netcup VPS', LucideIcons.server, emeraldPrimary),
            ],
          ),
          const SizedBox(height: 18),

          // Amount Field
          Text('AMOUNT (RS)', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: 'Rs ',
              prefixStyle: TextStyle(color: emeraldPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              hintText: '0.00',
              hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: emeraldPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Suggestion Chips (100, 150, 200, 250, 350, 400, 450, 500, 600)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amt) {
              return GestureDetector(
                onTap: () {
                  _amountController.text = amt.toInt().toString();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    'Rs ' + amt.toInt().toString(),
                    style: TextStyle(
                      color: textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Note / Client description
          Text('CLIENT / NOTE', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            style: TextStyle(color: textDark, fontSize: 14),
            decoration: InputDecoration(
              hintText: _selectedTxType == 'client_payment' ? 'e.g. Angelo (0779040196) - Unlimited' : 'e.g. Netcup VPS Renewal',
              hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: emeraldPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 18),

          // Target Account selector
          Text('DEPOSIT / CHARGE ACCOUNT', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedAccountId ?? (accounts.isNotEmpty ? accounts.first.id : null),
                dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                items: accounts.map((acc) {
                  return DropdownMenuItem<String>(
                    value: acc.id,
                    child: Row(
                      children: [
                        Icon(LucideIcons.wallet, size: 14, color: emeraldPrimary),
                        const SizedBox(width: 8),
                        Text(acc.name, style: TextStyle(color: textDark, fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAccountId = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleQuickAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: emeraldPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Record NovaGen Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typePill(String typeKey, String label, IconData icon, Color emeraldPrimary) {
    final isSelected = _selectedTxType == typeKey;
    final isDark = AppColors.isDark(context);

    final activeBg = isDark ? emeraldPrimary.withOpacity(0.2) : emeraldPrimary;
    final activeFg = isDark ? emeraldPrimary : Colors.white;
    final inactiveFg = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTxType = typeKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? emeraldPrimary : Colors.transparent, width: 1.2),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? activeFg : inactiveFg),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeFg : inactiveFg,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(
    BuildContext context,
    bool isDark,
    NovaGenBusinessState state,
    String currency,
    NumberFormat decimalFormat,
  ) {
    final emeraldPrimary = isDark ? const Color(0xFF00D9A8) : const Color(0xFF005A36);
    final emeraldTint = isDark ? const Color(0x1F00D9A8) : const Color(0xFFE8F5ED);
    final textDark = isDark ? const Color(0xFFF2FAF6) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Netcup VPS Status Card in Clean Luxury Neutral & Emerald
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A1814) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0x3000D9A8) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: emeraldTint,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: emeraldPrimary.withOpacity(0.3)),
                          ),
                          child: Icon(LucideIcons.server, color: emeraldPrimary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Netcup VPS (152.53.236.30)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                            Text('Host: Port 5000 & 54321', style: TextStyle(color: textMuted, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: state.isServerPaidThisCycle ? const Color(0xFF10B981).withOpacity(0.12) : emeraldTint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: state.isServerPaidThisCycle
                              ? const Color(0xFF10B981).withOpacity(0.4)
                              : emeraldPrimary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.isServerPaidThisCycle) ...[
                            const Icon(LucideIcons.checkCircle2, size: 11, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            state.renewalStatusBadge,
                            style: TextStyle(
                              color: state.isServerPaidThisCycle ? const Color(0xFF10B981) : emeraldPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MONTHLY RENEWAL (EST.)', style: TextStyle(color: textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                        Text('~Rs ' + decimalFormat.format(state.monthlyServerFee), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                        Text('Every month on 22nd • Card FX', style: TextStyle(color: textMuted, fontSize: 9)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('TOTAL PAID TO DATE', style: TextStyle(color: textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                        Text('Rs ' + decimalFormat.format(state.totalServerCost), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                        Text('Dedicated hosting reserve', style: TextStyle(color: textMuted, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Revenue Velocity (Today, This Week, This Month)
          Text('REVENUE VELOCITY', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _velocityColumn('TODAY', 'Rs ' + decimalFormat.format(state.todayRevenue), emeraldPrimary, textDark, textMuted),
                Container(width: 1, height: 32, color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                _velocityColumn('THIS WEEK', 'Rs ' + decimalFormat.format(state.thisWeekRevenue), emeraldPrimary, textDark, textMuted),
                Container(width: 1, height: 32, color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                _velocityColumn('THIS MONTH', 'Rs ' + decimalFormat.format(state.thisMonthRevenue), emeraldPrimary, textDark, textMuted),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // P&L Summary Cards - All 4 numbers in unified authoritative black font
          Text('FINANCIAL PERFORMANCE', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  context,
                  'Total Revenue',
                  'Rs ' + decimalFormat.format(state.totalRevenue),
                  LucideIcons.trendingUp,
                  emeraldPrimary,
                  isDark,
                  textDark,
                  textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  context,
                  'Net Profit',
                  'Rs ' + decimalFormat.format(state.netProfit),
                  LucideIcons.gem,
                  emeraldPrimary,
                  isDark,
                  textDark,
                  textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  context,
                  'Personal Drawings',
                  'Rs ' + decimalFormat.format(state.totalExpenses),
                  LucideIcons.wallet,
                  emeraldPrimary,
                  isDark,
                  textDark,
                  textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  context,
                  'Hosting Costs',
                  'Rs ' + decimalFormat.format(state.totalServerCost),
                  LucideIcons.server,
                  emeraldPrimary,
                  isDark,
                  textDark,
                  textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Financial Health Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: emeraldTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: emeraldPrimary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.shieldCheck, color: emeraldPrimary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Business Profit Margin: ' + (state.totalRevenue > 0 ? (state.netProfit / state.totalRevenue * 100).toStringAsFixed(1) : '65.2') + '%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: emeraldPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        'NovaGen SpeedNet has generated Rs ' + decimalFormat.format(state.totalRevenue) + ' with Rs ' + decimalFormat.format(state.netProfit) + ' real net profit after server fees and personal drawings.',
                        style: TextStyle(color: textDark.withOpacity(0.85), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Widget _velocityColumn(String label, String value, Color emeraldPrimary, Color textDark, Color textMuted) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: textMuted, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: emeraldPrimary, fontSize: 14.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _metricBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
    bool isDark,
    Color textDark,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, size: 14, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textDark, // Clean, authoritative black font!
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    bool isDark,
    NovaGenBusinessState state,
    String currency,
    NumberFormat decimalFormat,
  ) {
    final emeraldPrimary = isDark ? const Color(0xFF00D9A8) : const Color(0xFF005A36);
    final textDark = isDark ? const Color(0xFFF2FAF6) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);
    final txList = state.businessTransactions;

    if (txList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileSpreadsheet, size: 40, color: textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('No NovaGen transactions recorded yet', style: TextStyle(color: textMuted, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Use Quick Add to log new client payments or expenses', style: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: txList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tx = txList[index];
        final isIncome = tx.isIncome;
        final noteLower = tx.note.toLowerCase();
        final isServer = tx.categoryId == 'exp_novagen_server' ||
            (!tx.isIncome && (noteLower.contains('netcup') || noteLower.contains('foreign pos')));
        final icon = isIncome ? LucideIcons.arrowDownLeft : (isServer ? LucideIcons.server : LucideIcons.wallet);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x1F00D9A8) : const Color(0xFFE8F5ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: emeraldPrimary.withOpacity(0.25)),
                ),
                child: Icon(icon, size: 16, color: emeraldPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.note.isNotEmpty ? tx.note : (isIncome ? 'Client Subscription' : 'Expense'),
                      style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(tx.date),
                      style: TextStyle(color: textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                (isIncome ? '+ ' : '- ') + currency + ' ' + decimalFormat.format(tx.amount),
                style: TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
