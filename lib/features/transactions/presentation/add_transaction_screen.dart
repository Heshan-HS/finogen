import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../core/providers/account_providers.dart';
import '../../../core/models/transaction_model.dart';
import 'widgets/add_transaction_modal.dart';
import '../../../core/providers/settings_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final bool isExpense;

  const AddTransactionScreen({super.key, this.isExpense = true});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  String? _selectedWalletId;

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    final title = widget.isExpense ? 'Expense Overview' : 'Income Overview';
    final txAsync = ref.watch(transactionsStreamProvider);
    
    // Filter transactions
    var transactions = txAsync.value?.where((t) => t.isIncome == !widget.isExpense).toList() ?? [];
    
    if (_selectedWalletId != null) {
      transactions = transactions.where((t) => t.accountId == _selectedWalletId).toList();
    }
    
    // Calculate total
    final total = transactions.fold(0.0, (sum, item) => sum + item.amount);
    final formatter = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // Ambient glow
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [
                      AppColors.accent(context).withOpacity(AppColors.isDark(context) ? 0.25 : 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  _header(context, title),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                        _totalCard(context, currency, formatter.format(total * rate)),
                        const SizedBox(height: 24),
                        Text('Recent Transactions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 16),
                        ...transactions.map((tx) => _buildTxItem(context, tx, currency, rate, ref)),
                        if (transactions.isEmpty)
                          Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Text('No transactions yet.',
                                style: TextStyle(color: AppColors.muted(context)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          AddTransactionModal.show(context, isExpense: widget.isExpense);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.accent(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlow(context),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.plus, color: AppColors.accentFg(context), size: 24),
              const SizedBox(width: 8),
              Text(
                widget.isExpense ? 'Add Expense' : 'Add Income',
                style: TextStyle(
                  color: AppColors.accentFg(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTxItem(BuildContext context, TransactionModel tx, String currency, double rate, WidgetRef ref) {
    final account = ref.watch(accountByIdProvider(tx.accountId));
    final defaultDesc = account?.name ?? 'No Description';
    final isDark = AppColors.isDark(context);
    final isExpense = widget.isExpense;
    final accentGreen = AppColors.accent(context);
    final expenseColor = isDark ? const Color(0xFFFF5252) : const Color(0xFFDC2626);
    final color = isExpense ? expenseColor : accentGreen;
    final iconBg = isExpense
        ? (isDark ? expenseColor.withOpacity(0.12) : const Color(0xFFFEE2E2))
        : (isDark ? accentGreen.withOpacity(0.12) : AppColors.primaryLightTint);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          AddTransactionModal.show(context, isExpense: widget.isExpense, transaction: tx);
        },
        child: AppCard(
          isDark: false,
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(
                  widget.isExpense ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(tx.date),
                      style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.isExpense ? '-' : '+'}$currency ${(tx.amount * rate).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
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
              child: Icon(LucideIcons.chevronLeft, color: AppColors.text(context), size: 24),
            ),
          ),
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text(context))),
          AppCard(
            padding: const EdgeInsets.all(10),
            isDark: true,
            borderRadius: 12,
            child: Icon(LucideIcons.moreVertical, color: AppColors.text(context), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _totalCard(BuildContext context, String currency, String amountText) {
    return Stack(
      children: [
        ClipPath(
          clipper: CutoutClipper(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AppColors.isDark(context) ? AppColors.elevated(context).withOpacity(0.85) : Colors.white,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.08),
                            Colors.transparent,
                          ],
                          radius: 0.8,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 20,
                    right: 180, 
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, AppColors.primary.withOpacity(0.5), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 40,
                    right: 40,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, AppColors.primary.withOpacity(0.4), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: CutoutBorderPainter(color: AppColors.borderColor(context)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text(context))),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(currency, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.muted(context))),
                              const SizedBox(width: 8),
                              Text(amountText, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text(context), letterSpacing: -1)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(children: [ Icon(LucideIcons.calendarDays, size: 18, color: AppColors.text(context)),
                              SizedBox(width: 8),
                              Expanded(child: Text('This Month', style: TextStyle(fontSize: 14, color: AppColors.text(context)))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _showWalletSelector(context),
                            child: Row(
                              children: [
                                Icon(LucideIcons.wallet, size: 18, color: AppColors.text(context)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_getWalletName(), style: TextStyle(fontSize: 14, color: AppColors.text(context)))),
                                Icon(LucideIcons.chevronDown, size: 18, color: AppColors.text(context)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 16,
          child: Text(
            'FinoGen',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.accent(context).withOpacity(0.15),
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  String _getWalletName() {
    if (_selectedWalletId == null) return 'All Wallets';
    final account = ref.watch(accountByIdProvider(_selectedWalletId!));
    return account?.name ?? 'All Wallets';
  }

  void _showWalletSelector(BuildContext context) {
    final accounts = ref.read(accountsStreamProvider).value ?? [];
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
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('Select Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('All Wallets', style: TextStyle(color: AppColors.text(context))),
                leading: Icon(LucideIcons.wallet, color: AppColors.accent(context)),
                trailing: _selectedWalletId == null ? Icon(LucideIcons.check, color: AppColors.accent(context)) : null,
                onTap: () {
                  setState(() => _selectedWalletId = null);
                  Navigator.pop(context);
                },
              ),
              ...accounts.map((acc) => ListTile(
                title: Text(acc.name, style: TextStyle(color: AppColors.text(context))),
                leading: Icon(LucideIcons.creditCard, color: AppColors.text(context)),
                trailing: _selectedWalletId == acc.id ? Icon(LucideIcons.check, color: AppColors.accent(context)) : null,
                onTap: () {
                  setState(() => _selectedWalletId = acc.id);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}

class CutoutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = 24.0;
    final depth = 48.0; 
    final startX = w * 0.50;

    path.moveTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    
    path.lineTo(startX, 0);
    path.cubicTo(
      startX + 20, 0, 
      startX + 20, depth, 
      startX + 50, depth
    );
    
    path.lineTo(w - r, depth);
    path.arcToPoint(Offset(w, depth + r), radius: Radius.circular(r));
    
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class CutoutBorderPainter extends CustomPainter {
  final Color color;
  CutoutBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = 24.0;
    final depth = 48.0; 
    final startX = w * 0.50;

    path.moveTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    
    path.lineTo(startX, 0);
    path.cubicTo(
      startX + 20, 0, 
      startX + 20, depth, 
      startX + 50, depth
    );
    
    path.lineTo(w - r, depth);
    path.arcToPoint(Offset(w, depth + r), radius: Radius.circular(r));
    
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
