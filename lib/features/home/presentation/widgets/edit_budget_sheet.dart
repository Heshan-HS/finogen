import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/budget_providers.dart';
import '../../../../core/repositories/budget_repository.dart';
import '../../../../core/models/budget_model.dart';

class EditBudgetSheet extends ConsumerStatefulWidget {
  const EditBudgetSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditBudgetSheet(),
    );
  }

  @override
  ConsumerState<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<EditBudgetSheet> {
  late TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    // Delay slightly to let the stream emit if it hasn't
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentBudget = ref.read(currentMonthBudgetProvider).value?.overallLimit ?? 
                            ref.read(settingsProvider).value?.monthlyBudget ?? 50000.0;
      _amountController.text = currentBudget.toInt().toString();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 50000.0;
      final currentBudget = ref.read(currentMonthBudgetProvider).value;
      final budgetRepo = ref.read(budgetRepositoryProvider);
      
      if (currentBudget != null) {
        await budgetRepo.saveBudget(currentBudget.copyWith(overallLimit: amount));
      } else {
        final now = DateTime.now();
        await budgetRepo.saveBudget(BudgetModel(
          id: '',
          userId: '',
          month: now.month,
          year: now.year,
          overallLimit: amount,
          categoryLimits: {},
        ));
      }
      
      // Also update settings as a global default
      final settingsAsync = ref.read(settingsProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final currentSettings = settingsAsync.value;
      if (currentSettings != null) {
        final newSettings = currentSettings.copyWith(monthlyBudget: amount);
        await settingsRepo.updateSettings(newSettings);
      }
      
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Set Monthly Budget',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text(context),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.x, size: 20, color: AppColors.muted(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text(context)),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(fontSize: 16, color: AppColors.muted(context)),
                prefixText: '$currency ',
                prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borderColor(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borderColor(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.accent(context), width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.cardBg(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter amount';
                if (double.tryParse(val) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent(context),
                  foregroundColor: AppColors.accentFg(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Save Budget',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
