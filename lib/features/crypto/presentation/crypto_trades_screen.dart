import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/providers/crypto_trades_provider.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/providers/settings_provider.dart';
import 'widgets/edit_trade_dialog.dart';
import '../../home/presentation/widgets/add_trade_dialog.dart';

class CryptoTradesScreen extends ConsumerWidget {
  const CryptoTradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final rate = 1.0;
    final tradesAsync = ref.watch(cryptoTradesProvider);
    final formatter = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Crypto Futures', style: TextStyle(color: AppColors.text(context), fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Manage and track your day trading history', style: TextStyle(color: AppColors.muted(context), fontSize: 14)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(context: context, builder: (context) => const AddTradeDialog());
                  },
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Log Trade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: tradesAsync.when(
                data: (trades) {
                  if (trades.isEmpty) {
                    return const Center(child: Text('No trades found. Start logging your trades!', style: TextStyle(color: Colors.white54)));
                  }
                  
                  return AppCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: trades.length,
                      separatorBuilder: (context, index) => const AppDivider(),
                      itemBuilder: (context, index) {
                        final trade = trades[index];
                        final isProfit = trade.pnl >= 0;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: trade.isLong ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(
                                    trade.isLong ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                                    color: trade.isLong ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(trade.pair, style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM dd, yyyy • hh:mm a').format(trade.date),
                                      style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                (isProfit ? "+" : "-") + currency + formatter.format(trade.pnl.abs() * rate),
                                style: TextStyle(
                                  color: isProfit ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.edit2, color: Colors.white54, size: 18),
                                    onPressed: () {
                                      showDialog(context: context, builder: (context) => EditTradeDialog(trade: trade));
                                    },
                                    tooltip: 'Edit Trade',
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                                    onPressed: () {
                                      _showDeleteConfirmation(context, ref, trade.id);
                                    },
                                    tooltip: 'Delete Trade',
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String tradeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Trade', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this trade record? This action cannot be undone.', style: TextStyle(color: AppColors.muted(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cryptoTradesRepositoryProvider).deleteTrade(tradeId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trade deleted successfully'), backgroundColor: Colors.redAccent));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
