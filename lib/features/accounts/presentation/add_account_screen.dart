import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/account_model.dart';
import '../../../../core/repositories/account_repository.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/providers/settings_provider.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  final AccountModel? accountToEdit;
  const AddAccountScreen({super.key, this.accountToEdit});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  String get currency => ref.watch(currencySymbolProvider);
  double get rate => ref.watch(currencyRateProvider);
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();
  
  AccountType _selectedType = AccountType.cash;
  bool _excludeFromTotal = false;
  int _selectedColor = 0xFF00D9A8;

  final List<int> _colors = [
    0xFF00D9A8, // Primary green
    0xFF4A90E2, // Blue
    0xFFFF5252, // Red
    0xFFFF9F00, // Orange
    0xFF9B51E0, // Purple
    0xFFE91E63, // Pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      final acc = widget.accountToEdit!;
      _nameController.text = acc.name;
      _balanceController.text = acc.balance.abs().toString();
      _creditLimitController.text = acc.creditLimit.toString();
      _selectedType = acc.type;
      _selectedColor = acc.colorValue;
      _excludeFromTotal = acc.excludeFromTotal;
    }
  }

  void _showColorPicker() {
    Color tempColor = Color(_selectedColor);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bg(context),
          title: Text('Pick a color', style: TextStyle(color: AppColors.text(context))),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent(context)),
              child: const Text('Select', style: TextStyle(color: Colors.black)),
              onPressed: () {
                setState(() {
                  _selectedColor = tempColor.value;
                  if (!_colors.contains(_selectedColor)) {
                    _colors.add(_selectedColor);
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAccount() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an account name')));
      return;
    }

    double balance = double.tryParse(_balanceController.text.replaceAll(',', '')) ?? 0.0;
    final double creditLimit = double.tryParse(_creditLimitController.text.replaceAll(',', '')) ?? 0.0;

    if (_selectedType == AccountType.creditCard && balance > 0) {
      balance = -balance;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    final account = AccountModel(
      id: widget.accountToEdit?.id ?? '',
      userId: uid,
      name: name,
      type: _selectedType,
      balance: balance,
      creditLimit: creditLimit,
      colorValue: _selectedColor,
      isEnabled: widget.accountToEdit?.isEnabled ?? true,
      excludeFromTotal: _excludeFromTotal,
    );

    try {
      final repo = ref.read(accountRepositoryProvider);
      if (widget.accountToEdit != null) {
        await repo.updateAccount(account);
      } else {
        await repo.addAccount(account);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving account: $e')));
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (widget.accountToEdit == null) return;
    final acc = widget.accountToEdit!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Account', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${acc.name}"? This action cannot be undone.', style: TextStyle(color: AppColors.muted(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(accountRepositoryProvider).deleteAccount(acc.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.accountToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Account' : 'Add Account', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Input
            AppCard(
              isDark: true,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              borderRadius: 24,
              child: Column(
                children: [
                  Text(_selectedType == AccountType.creditCard ? 'Outstanding Balance' : 'Current Balance', style: TextStyle(fontSize: 14, color: AppColors.muted(context))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(currency, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.accent(context))),
                      const SizedBox(width: 8),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _balanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: AppColors.muted(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Type Selection
            Text('Account Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text(context))),
            const SizedBox(height: 12),
            Row(
              children: [
                _typeOption(AccountType.cash, 'Cash', LucideIcons.wallet),
                const SizedBox(width: 12),
                _typeOption(AccountType.bank, 'Bank', LucideIcons.building),
                const SizedBox(width: 12),
                _typeOption(AccountType.creditCard, 'Credit Card', LucideIcons.creditCard),
              ],
            ),
            const SizedBox(height: 24),

            // Details
            AppCard(
              isDark: true,
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Column(
                children: [
                  _inputField('Account Name', _nameController, hint: 'e.g. Commercial Bank'),
                  if (_selectedType == AccountType.creditCard) ...[
                    const SizedBox(height: 20),
                    _inputField('Credit Limit ($currency)', _creditLimitController, hint: 'e.g. 100000', isNumber: true),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Theme Color', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text(context))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((colorVal) {
                final isSelected = _selectedColor == colorVal;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorVal;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: Color(colorVal).withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                          : null,
                    ),
                    child: isSelected ? const Icon(LucideIcons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList()
                ..add(
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.muted(context).withOpacity(0.3), width: 2),
                      ),
                      child: Icon(LucideIcons.palette, color: AppColors.text(context), size: 20),
                    ),
                  ),
                ),
            ),
            
            const SizedBox(height: 36),
            
            // Save Button
            ElevatedButton(
              onPressed: _saveAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isEditing ? 'Update Account' : 'Save Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
            ),

            if (isEditing) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                label: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeOption(AccountType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent(context).withOpacity(0.15) : AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.accent(context) : AppColors.borderColor(context)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.accent(context) : AppColors.muted(context), size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? AppColors.accent(context) : AppColors.text(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, {String? hint, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.muted(context))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: TextStyle(color: AppColors.text(context), fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.muted(context).withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
