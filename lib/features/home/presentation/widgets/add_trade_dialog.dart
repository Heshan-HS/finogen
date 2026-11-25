import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance/core/models/crypto_trade_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nova_finance/core/providers/crypto_trades_provider.dart';
import 'package:nova_finance/core/theme/app_colors.dart';
import 'package:uuid/uuid.dart';

class AddTradeDialog extends ConsumerStatefulWidget {
  const AddTradeDialog({super.key});

  @override
  ConsumerState<AddTradeDialog> createState() => _AddTradeDialogState();
}

class _AddTradeDialogState extends ConsumerState<AddTradeDialog> {
  final _pairController = TextEditingController();
  final _pnlController = TextEditingController();
  bool _isLong = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _pairController.dispose();
    _pnlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pairController.text.isEmpty || _pnlController.text.isEmpty) return;
    
    final pnlValue = double.tryParse(_pnlController.text);
    if (pnlValue == null) return;

    setState(() { _isLoading = true; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _isLoading = false; });
      return;
    }

    final trade = CryptoTradeModel(
      id: const Uuid().v4(),
      userId: user.uid,
      pair: _pairController.text.toUpperCase(),
      pnl: pnlValue,
      isLong: _isLong,
      date: DateTime.now(),
    );

    try {
      await ref.read(cryptoTradesRepositoryProvider).addTrade(trade);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderColor(context)),
      ),
      title: Text('Log Futures Trade', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trading Pair', style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _pairController,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                hintText: 'e.g. BTC/USDT',
                hintStyle: TextStyle(color: AppColors.muted(context)),
                filled: true,
                fillColor: AppColors.elevated(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderColor(context))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderColor(context))),
              ),
            ),
            const SizedBox(height: 16),
            Text('PnL Amount', style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _pnlController,
              style: TextStyle(color: AppColors.text(context)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                hintText: '+50.0 or -20.0',
                hintStyle: TextStyle(color: AppColors.muted(context)),
                filled: true,
                fillColor: AppColors.elevated(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderColor(context))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderColor(context))),
              ),
            ),
            const SizedBox(height: 16),
            Text('Position Type', style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isLong = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isLong ? Colors.green.withValues(alpha: 0.2) : AppColors.elevated(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _isLong ? Colors.green : AppColors.borderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('LONG', style: TextStyle(color: _isLong ? Colors.green : AppColors.muted(context), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isLong = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isLong ? Colors.red.withValues(alpha: 0.2) : AppColors.elevated(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: !_isLong ? Colors.red : AppColors.borderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('SHORT', style: TextStyle(color: !_isLong ? Colors.red : AppColors.muted(context), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent(context),
            foregroundColor: AppColors.accentFg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentFg(context))) : Text('Save Trade', style: TextStyle(color: AppColors.accentFg(context))),
        ),
      ],
    );
  }
}
