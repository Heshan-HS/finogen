import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  String get currency => ref.watch(currencySymbolProvider);
  double get rate => ref.watch(currencyRateProvider);
  bool _isExpense = true;
  String _amount = "0.00";

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(top: 100, bottom: bottomInsets),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, -10)),
        ],
      ),
      child: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -50,
            left: 50,
            right: 50,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.accent(context).withOpacity(0.15), blurRadius: 100, spreadRadius: 50)
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Add Transaction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                
                // Toggle Type
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.elevated(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _typeBtn('Expense', true)),
                      Expanded(child: _typeBtn('Income', false)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Amount Input Mock
                Center(
                  child: Text(
                    '${currency}$_amount',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: _isExpense ? AppColors.text(context) : AppColors.accent(context),
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Category Selection
                Text('Category', style: TextStyle(fontSize: 13, color: AppColors.muted(context))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _catSelect(LucideIcons.shoppingBag, 'Shopping', true),
                    _catSelect(LucideIcons.utensilsCrossed, 'Food', false),
                    _catSelect(LucideIcons.home, 'Living', false),
                    _catSelect(LucideIcons.bus, 'Transport', false),
                  ],
                ),
                
                const SizedBox(height: 40),
                // Save Button
                AppCard(
                  isDark: false, // Use gradient
                  centerGlow: false,
                  onTap: () => Navigator.pop(context),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: 16,
                  child: Center(
                    child: Text('Save Transaction',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentFg(context))),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(String label, bool isExp) {
    final active = _isExpense == isExp;
    return GestureDetector(
      onTap: () => setState(() => _isExpense = isExp),
      child: Container(
        decoration: BoxDecoration(
          color: active ? (_isExpense ? const Color(0xFFFF5252).withOpacity(0.15) : AppColors.primary.withOpacity(0.15)) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active ? Border.all(color: _isExpense ? const Color(0xFFFF5252).withOpacity(0.3) : AppColors.primary.withOpacity(0.3)) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? (_isExpense ? const Color(0xFFFF5252) : AppColors.accent(context)) : AppColors.muted(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catSelect(IconData icon, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: active ? AppColors.accent(context).withOpacity(0.15) : AppColors.cardBg(context),
            shape: BoxShape.circle,
            border: Border.all(color: active ? AppColors.accent(context).withOpacity(0.3) : AppColors.borderColor(context)),
          ),
          child: Icon(icon, color: active ? AppColors.accent(context) : AppColors.muted(context), size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: active ? AppColors.text(context) : AppColors.muted(context))),
      ],
    );
  }
}
