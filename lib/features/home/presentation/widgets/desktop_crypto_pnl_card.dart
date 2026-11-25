import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nova_finance/core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import 'package:nova_finance/core/providers/crypto_trades_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import 'package:nova_finance/features/home/presentation/widgets/add_trade_dialog.dart';
import 'package:nova_finance/core/providers/navigation_providers.dart';

class DesktopCryptoPnlCard extends ConsumerWidget {
  const DesktopCryptoPnlCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final rate = 1.0;
    final tradesAsync = ref.watch(cryptoTradesProvider);
    final formatter = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? Colors.white54 : AppColors.textMutedLight;
    final accent = AppColors.accent(context);

    return AppCard(
      withGlow: true,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? null : Colors.transparent,
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.01),
                  ],
                )
              : null,
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
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(LucideIcons.trendingUp, color: isDark ? Colors.white : const Color(0xFF005A36), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text('Futures Day Trading', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        ref.read(mainNavIndexProvider.notifier).state = 9;
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.transparent : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
                        ),
                        child: Text('View All', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AddTradeDialog(),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF022B1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF005A36)),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.plus, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Log Trade', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            tradesAsync.when(
              data: (trades) {
                final now = DateTime.now();
                final todayTrades = trades.where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day).toList();
                
                double totalPnl = 0;
                int winCount = 0;
                for (var t in todayTrades) {
                  totalPnl += t.pnl;
                  if (t.pnl > 0) winCount++;
                }
                
                double winRate = todayTrades.isEmpty ? 0 : (winCount / todayTrades.length) * 100;
                final isProfit = totalPnl >= 0;
                final pnlColor = isProfit ? (isDark ? Colors.greenAccent : const Color(0xFF059669)) : const Color(0xFFDC2626);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            pnlColor.withValues(alpha: 0.08),
                            isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's PnL", style: TextStyle(color: textMuted, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: isProfit ? "+" : "-",
                                      style: TextStyle(
                                        color: pnlColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$currency ',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : AppColors.textMutedLight,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: formatter.format(totalPnl.abs() * rate),
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: pnlColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: pnlColor.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    winRate.toStringAsFixed(0) + "% WR",
                                    style: TextStyle(color: pnlColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Recent Trades", style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (todayTrades.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(child: Text("No trades logged today.", style: TextStyle(color: textMuted, fontSize: 12))),
                      )
                    else
                      ...todayTrades.take(3).map((trade) {
                        final tradeIsProfit = trade.pnl >= 0;
                        final tradePnlColor = tradeIsProfit ? (isDark ? Colors.greenAccent : const Color(0xFF059669)) : const Color(0xFFDC2626);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: trade.isLong ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    trade.isLong ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                                    color: trade.isLong ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(trade.pair, style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text(DateFormat('hh:mm a').format(trade.date), style: TextStyle(color: textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(
                                (tradeIsProfit ? "+" : "-") + currency + formatter.format(trade.pnl.abs() * rate),
                                style: TextStyle(
                                  color: tradePnlColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
              loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
              error: (e, s) => Center(child: Text('Error: ' + e.toString(), style: const TextStyle(color: Colors.red))),
            ),
          ],
        ),
      ),
    );
  }
}


