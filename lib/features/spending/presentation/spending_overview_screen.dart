import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_progress_bar.dart';
import '../../../core/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpendingOverviewScreen extends ConsumerWidget {
  const SpendingOverviewScreen({super.key});

  static const _cats = [
    _Cat(LucideIcons.utensilsCrossed, 'Food & Groceries', 12, 520.80, 1000, 0.52),
    _Cat(LucideIcons.shoppingBag,     'Shopping',          8, 320.40, 1000, 0.32),
    _Cat(LucideIcons.home,            'Living & Housing',  4, 780.90, 1000, 0.78),
    _Cat(LucideIcons.bus,             'Transport',         6, 260.50, 1000, 0.26),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          _header(context),
          const SizedBox(height: 16),
          ..._cats.map((c) => _catCard(context, c, rate, currency)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
      child: Row(
        children: [
          _logo(),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Spending', style: TextStyle(fontSize: 13, color: AppColors.muted(context))),
            Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text(context), height: 1.1, letterSpacing: -0.5)),
          ]),
          const Spacer(),
          _iconBtn(context, LucideIcons.slidersHorizontal),
          const SizedBox(width: 10),
          _iconBtn(context, LucideIcons.bell),
        ],
      ),
    );
  }

  Widget _logo() {
    const s = 14.0;
    const r = Radius.circular(3);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: s, height: s, decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.all(r))),
        const SizedBox(width: 2),
        Container(width: s, height: s, decoration: const BoxDecoration(color: Color(0x4000D9A8), borderRadius: BorderRadius.all(r))),
      ]),
      const SizedBox(height: 2),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: s, height: s, decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.all(r))),
        const SizedBox(width: 2),
        Container(width: s, height: s, decoration: const BoxDecoration(color: Color(0x4000D9A8), borderRadius: BorderRadius.all(r))),
      ]),
    ]);
  }

  Widget _iconBtn(BuildContext context, IconData icon) => AppCard(
    padding: EdgeInsets.zero,
    child: SizedBox(width: 44, height: 44,
      child: Icon(icon, color: AppColors.text(context).withOpacity(0.8), size: 20)),
  );

  // CategoryCard.tsx - withGlow=true (gradient-glow at top-left)
  Widget _catCard(BuildContext context, _Cat c, double rate, String currency) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: AppCard(
        padding: EdgeInsets.zero,
        withGlow: true,
        child: Column(children: [
          // Top row: icon | name + transactions | amount
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.elevated(context).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor(context)),
                ),
                child: Icon(c.icon, size: 20, color: AppColors.text(context).withOpacity(0.85)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.text(context))),
                const SizedBox(height: 2),
                Text('${c.txCount} Transactions', style: TextStyle(fontSize: 11, color: AppColors.muted(context))),
              ])),
              Text('$currency${(c.amount * rate).toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.accent(context))),
            ]),
          ),
          // Bottom row: progress bar | pct | budget (border-t)
          const AppDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              SizedBox(
                width: 120,
                child: AppProgressBar(value: c.pct),
              ),
              const SizedBox(width: 10),
              Text('${(c.pct * 100).toInt()}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text(context))),
              const Spacer(),
              Text('Budget $currency${(c.budget * rate).toInt()}',
                  style: TextStyle(fontSize: 11, color: AppColors.muted(context))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Cat {
  const _Cat(this.icon, this.name, this.txCount, this.amount, this.budget, this.pct);
  final IconData icon;
  final String name;
  final int txCount;
  final double amount;
  final double budget;
  final double pct;
}
