import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/novagen_business_provider.dart';
import '../../../core/providers/account_providers.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/repositories/transaction_repository.dart';

class NovaGenHubScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const NovaGenHubScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<NovaGenHubScreen> createState() => _NovaGenHubScreenState();
}

class _NovaGenHubScreenState extends ConsumerState<NovaGenHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedTxType = 'client_payment'; // client_payment, drawing, server_cost
  String? _selectedAccountId;
  String _historyFilter = 'all'; // all, income, server, draw
  String _searchQuery = '';
  bool _isSubmitting = false;

  final List<double> _quickAmounts = [100, 150, 200, 250, 350, 400, 450, 500, 600, 1000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleQuickAdd() async {
    final text = _amountController.text.trim();
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final accounts = ref.read(accountsStreamProvider).value ?? [];
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No accounts available to link transaction'),
          behavior: SnackBarBehavior.floating,
        ),
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

    // Default account priority for NovaGen SpeedNet: eZ Cash SIM 2, Dialog New, then Nations Trust
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
      HapticFeedback.mediumImpact();

      if (mounted) {
        _amountController.clear();
        _noteController.clear();
        FocusScope.of(context).unfocus();

        final emerald = AppColors.isDark(context) ? const Color(0xFF00D9A8) : const Color(0xFF005A36);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: emerald,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recorded Rs ${amount.toStringAsFixed(2)} to ${targetAccount.name}!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );

        setState(() {
          _isSubmitting = false;
        });
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final businessState = ref.watch(novagenBusinessProvider);
    final currency = ref.watch(currencySymbolProvider);
    final decimalFormat = NumberFormat('#,##0.00');

    final bg = AppColors.bg(context);
    final emeraldPrimary = isDark ? const Color(0xFF00D9A8) : const Color(0xFF005A36);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, isDark, emeraldPrimary),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: _buildCommandHero(context, isDark, businessState, decimalFormat, emeraldPrimary),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabDelegate(
                        child: _buildSegmentTabs(context, isDark, emeraldPrimary),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildControllerTab(context, isDark, businessState, decimalFormat, emeraldPrimary),
                    _buildQuickLoggerTab(context, isDark, emeraldPrimary, currency),
                    _buildLedgerTab(context, isDark, businessState, decimalFormat, emeraldPrimary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, Color emeraldPrimary) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Icon(LucideIcons.arrowLeft, size: 18, color: textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.zap, size: 16, color: Color(0xFF00E5A3)),
                    const SizedBox(width: 6),
                    Text(
                      'NovaGen SpeedNet',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'VPN Business Engine & Controller',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x1F00D9A8) : const Color(0xFFE8F5ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: emeraldPrimary.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E5A3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Netcup Live',
                  style: TextStyle(
                    color: emeraldPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(LucideIcons.refreshCw, size: 18, color: textDark.withOpacity(0.7)),
            onPressed: () {
              ref.refresh(transactionsStreamProvider);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('NovaGen SpeedNet stats synced!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommandHero(
    BuildContext context,
    bool isDark,
    NovaGenBusinessState state,
    NumberFormat decimalFormat,
    Color emeraldPrimary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF003822),
                  const Color(0xFF004D2E),
                  const Color(0xFF001A10),
                ]
              : [
                  const Color(0xFF005A36),
                  const Color(0xFF007A4B),
                  const Color(0xFF004429),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005A36).withOpacity(isDark ? 0.35 : 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF00E5A3).withOpacity(0.25),
          width: 1.2,
        ),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF00E5A3), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SPEEDNET COMMAND CENTER',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5A3).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E5A3).withOpacity(0.4)),
                ),
                child: const Text(
                  '152.53.236.30',
                  style: TextStyle(
                    color: Color(0xFF00E5A3),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'Live Net Profit',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Rs ',
                  style: TextStyle(
                    color: Color(0xFF00E5A3),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  decimalFormat.format(state.netProfit),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 9.5)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Rs ${decimalFormat.format(state.todayRevenue)}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white.withOpacity(0.15)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('This Week', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 9.5)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Rs ${decimalFormat.format(state.thisWeekRevenue)}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white.withOpacity(0.15)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('This Month', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 9.5)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Rs ${decimalFormat.format(state.thisMonthRevenue)}',
                            style: const TextStyle(color: Color(0xFF00E5A3), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.calendarClock, size: 13, color: Color(0xFF00E5A3)),
                  const SizedBox(width: 6),
                  Text(
                    state.isServerPaidThisCycle
                        ? 'Netcup VPS Paid • Next: ${DateFormat('MMM dd').format(state.nextRenewalDate)} (${state.daysUntilRenewal}d)'
                        : 'Netcup VPS Due: ${DateFormat('MMM dd').format(state.nextRenewalDate)} • ${state.daysUntilRenewal}d left',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '~Rs ${decimalFormat.format(state.monthlyServerFee)}',
                style: const TextStyle(
                  color: Color(0xFF00E5A3),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTabs(BuildContext context, bool isDark, Color emeraldPrimary) {
    final bg = isDark ? const Color(0xFF061210) : const Color(0xFFF1F5F9);

    return Container(
      color: AppColors.bg(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: isDark ? emeraldPrimary.withOpacity(0.2) : emeraldPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!isDark)
                BoxShadow(color: emeraldPrimary.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          labelColor: isDark ? emeraldPrimary : Colors.white,
          unselectedLabelColor: isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B),
          labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(LucideIcons.server, size: 15), text: 'Controller'),
            Tab(icon: Icon(LucideIcons.plusCircle, size: 15), text: 'Quick Log'),
            Tab(icon: Icon(LucideIcons.history, size: 15), text: 'Ledger'),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerTab(
    BuildContext context,
    bool isDark,
    NovaGenBusinessState state,
    NumberFormat decimalFormat,
    Color emeraldPrimary,
  ) {
    final textDark = isDark ? const Color(0xFFF2FAF6) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF0A1814) : Colors.white;
    final cardBorder = isDark ? const Color(0x3000D9A8) : const Color(0xFFE2E8F0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: emeraldPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: emeraldPrimary.withOpacity(0.3)),
                        ),
                        child: Icon(LucideIcons.server, size: 20, color: emeraldPrimary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Netcup Server Instance',
                            style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '152.53.236.30',
                            style: TextStyle(color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _copyToClipboard('152.53.236.30', 'Netcup VPS IP copied to clipboard!'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.copy, size: 12, color: emeraldPrimary),
                          const SizedBox(width: 5),
                          Text('Copy IP', style: TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _vpsSpecItem('API Port', '5000 (PM2)', LucideIcons.radio, textDark, textMuted),
                  ),
                  Expanded(
                    child: _vpsSpecItem('VPN Core', '54321 (Xray)', LucideIcons.shield, textDark, textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _vpsSpecItem('Uptime', '99.98% Healthy', LucideIcons.checkCheck, textDark, textMuted),
                  ),
                  Expanded(
                    child: _vpsSpecItem('Monthly Cost', 'Rs 2,460.94', LucideIcons.creditCard, textDark, textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'FINANCIAL LEDGER STATS',
          style: TextStyle(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _bentoStatCard(
                'Total Revenue',
                'Rs ${decimalFormat.format(state.totalRevenue)}',
                'Gross Client Subscriptions',
                LucideIcons.trendingUp,
                const Color(0xFF00E5A3),
                isDark,
                textDark,
                textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bentoStatCard(
                'Net Profit',
                'Rs ${decimalFormat.format(state.netProfit)}',
                '~65.2% Margin',
                LucideIcons.sparkles,
                emeraldPrimary,
                isDark,
                textDark,
                textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _bentoStatCard(
                'Server Cost',
                'Rs ${decimalFormat.format(state.totalServerCost)}',
                'Netcup Hosting Fees',
                LucideIcons.server,
                const Color(0xFF00B4D8),
                isDark,
                textDark,
                textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bentoStatCard(
                'Personal Spent',
                'Rs ${decimalFormat.format(state.totalExpenses)}',
                'Owner Drawings',
                LucideIcons.wallet,
                const Color(0xFFFFB703),
                isDark,
                textDark,
                textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _selectedTxType = 'client_payment');
                  _tabController.animateTo(1);
                },
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: const Text('Add Client Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: emeraldPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _selectedTxType = 'server_cost');
                  _amountController.text = '2460.94';
                  _noteController.text = 'Netcup Server VPS Renewal';
                  _tabController.animateTo(1);
                },
                icon: const Icon(LucideIcons.server, size: 16),
                label: const Text('Log Server Bill'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textDark,
                  side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _vpsSpecItem(String label, String value, IconData icon, Color textDark, Color textMuted) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textMuted),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: textMuted, fontSize: 10)),
            Text(value, style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _bentoStatCard(
    String title,
    String amount,
    String subtitle,
    IconData icon,
    Color accentColor,
    bool isDark,
    Color textDark,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1814) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0x2800D9A8) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: accentColor.withOpacity(0.9), fontSize: 9.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickLoggerTab(BuildContext context, bool isDark, Color emeraldPrimary, String currency) {
    final textDark = isDark ? const Color(0xFFF2FAF6) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);
    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final decimalFormat = NumberFormat('#,##0.00');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        Text(
          'TRANSACTION TYPE',
          style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
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

        Text(
          'AMOUNT',
          style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: emeraldPrimary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((amt) {
            return GestureDetector(
              onTap: () {
                _amountController.text = amt.toInt().toString();
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  'Rs ${amt.toInt()}',
                  style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        Text(
          'CLIENT NAME & PHONE / NOTE',
          style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          style: TextStyle(color: textDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: _selectedTxType == 'client_payment'
                ? 'e.g. Angelo_0779040196 - Unlimited'
                : (_selectedTxType == 'server_cost' ? 'Netcup Server VPS Renewal' : 'Personal Drawing'),
            hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: emeraldPrimary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'DEPOSIT / CHARGE ACCOUNT',
          style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
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
                      Icon(LucideIcons.wallet, size: 15, color: emeraldPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          acc.name,
                          style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Rs ${decimalFormat.format(acc.balance)}',
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
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
        const SizedBox(height: 20),

        Text(
          'TRANSACTION DATE',
          style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 15, color: emeraldPrimary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(_selectedDate),
                      style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text('Change', style: TextStyle(color: emeraldPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleQuickAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: emeraldPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: emeraldPrimary.withOpacity(0.4),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.zap, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Log NovaGen Record',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _typePill(String typeKey, String label, IconData icon, Color emeraldPrimary) {
    final isSelected = _selectedTxType == typeKey;
    final isDark = AppColors.isDark(context);

    Color activeColor = emeraldPrimary;
    if (typeKey == 'drawing') activeColor = const Color(0xFFFFB703);
    if (typeKey == 'server_cost') activeColor = const Color(0xFF00B4D8);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTxType = typeKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? activeColor.withOpacity(0.2) : activeColor.withOpacity(0.12))
                : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? activeColor : (isDark ? Colors.white60 : Colors.black54)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black87),
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerTab(
    BuildContext context,
    bool isDark,
    NovaGenBusinessState state,
    NumberFormat decimalFormat,
    Color emeraldPrimary,
  ) {
    final textDark = isDark ? const Color(0xFFF2FAF6) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF0A1814) : Colors.white;
    final cardBorder = isDark ? const Color(0x3000D9A8) : const Color(0xFFE2E8F0);

    final rawTxList = state.businessTransactions;

    final filtered = rawTxList.where((tx) {
      final noteLower = tx.note.toLowerCase();
      final isServerTx = tx.categoryId == 'exp_novagen_server' ||
          (!tx.isIncome && (noteLower.contains('netcup') || noteLower.contains('foreign pos')));

      if (_historyFilter == 'income' && !tx.isIncome) return false;
      if (_historyFilter == 'server' && !isServerTx) return false;
      if (_historyFilter == 'draw' && tx.categoryId != 'exp_novagen_draw') return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchNote = tx.note.toLowerCase().contains(query);
        final matchAmount = tx.amount.toString().contains(query);
        if (!matchNote && !matchAmount) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: TextStyle(color: textDark, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search client name, phone or note...',
                  hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 12),
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All Logs (${rawTxList.length})', emeraldPrimary),
                    const SizedBox(width: 8),
                    _filterChip('income', 'Client Payments', const Color(0xFF00E5A3)),
                    const SizedBox(width: 8),
                    _filterChip('server', 'Netcup VPS', const Color(0xFF00B4D8)),
                    const SizedBox(width: 8),
                    _filterChip('draw', 'Drawings', const Color(0xFFFFB703)),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.fileSpreadsheet, size: 42, color: textMuted.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text('No matching records found', style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Use Quick Log tab to record client payments or VPS bills', style: TextStyle(color: textMuted, fontSize: 11)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    final isIncome = tx.isIncome;
                    final noteLower = tx.note.toLowerCase();
                    final isServer = tx.categoryId == 'exp_novagen_server' ||
                        (!tx.isIncome && (noteLower.contains('netcup') || noteLower.contains('foreign pos')));

                    Color iconColor = const Color(0xFF00E5A3);
                    IconData icon = LucideIcons.arrowDownLeft;
                    String badgeLabel = 'Client Payment';

                    if (isServer) {
                      iconColor = const Color(0xFF00B4D8);
                      icon = LucideIcons.server;
                      badgeLabel = 'VPS Server';
                    } else if (!isIncome) {
                      iconColor = const Color(0xFFFFB703);
                      icon = LucideIcons.wallet;
                      badgeLabel = 'Drawing';
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: iconColor.withOpacity(0.3)),
                            ),
                            child: Icon(icon, size: 16, color: iconColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badgeLabel,
                                        style: TextStyle(color: iconColor, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        DateFormat('MMM dd, yyyy').format(tx.date),
                                        style: TextStyle(color: textMuted, fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tx.note,
                                  style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${isIncome ? '+' : '-'}Rs ${decimalFormat.format(tx.amount)}',
                            style: TextStyle(
                              color: isIncome ? const Color(0xFF00E5A3) : (isServer ? const Color(0xFF00B4D8) : const Color(0xFFFFB703)),
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _filterChip(String key, String label, Color activeColor) {
    final isSelected = _historyFilter == key;
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: () => setState(() => _historyFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.18)
              : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : (isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B)),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverTabDelegate({required this.child});

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverTabDelegate oldDelegate) => true;
}
