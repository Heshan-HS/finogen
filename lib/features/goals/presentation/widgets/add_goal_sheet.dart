import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/repositories/goal_repository.dart';
import '../../../../core/models/goal_model.dart';
import '../helpers/goal_category_helper.dart';

class AddGoalSheet extends ConsumerStatefulWidget {
  final GoalModel? goalToEdit;
  const AddGoalSheet({super.key, this.goalToEdit});

  static Future<void> show(BuildContext context, {GoalModel? goal}) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
            child: AddGoalSheet(goalToEdit: goal),
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
            heightFactor: 0.90,
            child: AddGoalSheet(goalToEdit: goal),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _initialDepositController = TextEditingController();

  DateTime? _deadline;
  late String _selectedCategory;
  late String _selectedIcon;
  late int _selectedColor;
  String _selectedPriority = 'medium';
  bool _isSaving = false;

  final List<int> _colorPalette = [
    0xFF005A36, // Deep Luxury Emerald
    0xFF3B82F6, // Electric Blue
    0xFFF59E0B, // Amber Gold
    0xFF8B5CF6, // Royal Violet
    0xFFEC4899, // Cyber Pink
    0xFF10B981, // Mint Forest
    0xFF06B6D4, // Cyan
    0xFFEF4444, // Crimson Red
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      final g = widget.goalToEdit!;
      _nameController.text = g.name;
      _targetController.text = g.targetAmount > 0 ? (g.targetAmount % 1 == 0 ? g.targetAmount.toInt().toString() : g.targetAmount.toStringAsFixed(2)) : '';
      _initialDepositController.text = g.currentAmount > 0 ? (g.currentAmount % 1 == 0 ? g.currentAmount.toInt().toString() : g.currentAmount.toStringAsFixed(2)) : '0';
      _deadline = g.deadline;
      _selectedCategory = g.category;
      _selectedIcon = g.iconName;
      _selectedColor = g.colorValue;
      _selectedPriority = g.priority;
    } else {
      _selectedCategory = 'emergency';
      final def = GoalCategoryHelper.getCategory('emergency');
      _selectedIcon = 'shield';
      _selectedColor = def.defaultColor;
      _selectedPriority = 'high';
      _deadline = DateTime.now().add(const Duration(days: 90));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _initialDepositController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final targetVal = double.tryParse(_targetController.text.replaceAll(',', '')) ?? 0.0;
    if (targetVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target amount greater than zero')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(goalRepositoryProvider);
      final initialDeposit = double.tryParse(_initialDepositController.text.replaceAll(',', '')) ?? 0.0;

      if (widget.goalToEdit != null) {
        final currentVal = double.tryParse(_initialDepositController.text.replaceAll(',', '')) ?? widget.goalToEdit!.currentAmount;
        final updated = widget.goalToEdit!.copyWith(
          name: _nameController.text.trim(),
          targetAmount: targetVal,
          currentAmount: currentVal,
          deadline: _deadline,
          colorValue: _selectedColor,
          category: _selectedCategory,
          iconName: _selectedIcon,
          priority: _selectedPriority,
        );
        await repo.updateGoal(updated);
      } else {
        final newGoal = GoalModel(
          id: '',
          userId: '',
          name: _nameController.text.trim(),
          targetAmount: targetVal,
          currentAmount: initialDeposit,
          deadline: _deadline,
          colorValue: _selectedColor,
          category: _selectedCategory,
          iconName: _selectedIcon,
          priority: _selectedPriority,
        );
        await repo.addGoal(newGoal);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving goal: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final isDark = AppColors.isDark(context);
    final isEdit = widget.goalToEdit != null;

    final activeColor = Color(_selectedColor);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: activeColor.withValues(alpha: 0.35)),
                      ),
                      child: Icon(
                        GoalCategoryHelper.getIcon(_selectedIcon, _selectedCategory),
                        color: activeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Goal Vault' : 'New Goal Vault',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Wealth milestones & smart projection',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    LucideIcons.x,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
            height: 1,
          ),

          // Scrollable Form Body
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                children: [
                  // 1. Goal Name
                  Text(
                    'GOAL NAME',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. M3 MacBook Pro, Emergency Shield, NovaGen VPS Pool',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                        fontSize: 13.5,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: activeColor, width: 1.5),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a goal name' : null,
                  ),
                  const SizedBox(height: 20),

                  // 2. Target Amount & Initial Deposit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TARGET AMOUNT ($currency)',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : const Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _targetController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                prefixText: '$currency ',
                                prefixStyle: TextStyle(
                                  color: activeColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                                hintText: '100,000',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: activeColor, width: 1.5),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'SAVED BALANCE ($currency)' : 'STARTING SEED ($currency)',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : const Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _initialDepositController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                prefixText: '$currency ',
                                prefixStyle: TextStyle(
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: activeColor, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 3. Category Vault Selector
                  Text(
                    'GOAL CATEGORY & VAULT TYPE',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: GoalCategoryHelper.categories.map((cat) {
                      final isSelected = _selectedCategory == cat.key;
                      final catColor = Color(cat.defaultColor);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat.key;
                            _selectedIcon = cat.key;
                            _selectedColor = cat.defaultColor;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
      ? const LinearGradient(
          colors: [Color(0xFF007A4D), Color(0xFF005A36)],
        )
      : null,
  color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? catColor.withValues(alpha: 0.6)
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 14,
                                color: isSelected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // 4. Target Deadline
                  Text(
                    'TARGET DEADLINE (FOR SMART PACING)',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _deadline ?? now.add(const Duration(days: 90)),
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365 * 10)),
                        builder: (ctx, child) {
                          return Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: activeColor,
                                surface: const Color(0xFF1E293B),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _deadline = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.calendar, size: 16, color: activeColor),
                              const SizedBox(width: 10),
                              Text(
                                _deadline != null
                                    ? DateFormat('MMMM dd, yyyy').format(_deadline!)
                                    : 'No deadline set (Flexible Vault)',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_deadline != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: activeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_deadline!.difference(DateTime.now()).inDays}d left',
                                style: TextStyle(
                                  color: activeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 5. Priority Tier
                  Text(
                    'PRIORITY LEVEL',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPriorityChip('high', '🔥 High Priority', Colors.redAccent),
                      const SizedBox(width: 10),
                      _buildPriorityChip('medium', '⚡ Medium', Colors.amber),
                      const SizedBox(width: 10),
                      _buildPriorityChip('low', '🌱 Low / Casual', Colors.cyan),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 6. Color Accent
                  Text(
                    'ACCENT JEWEL COLOR',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colorPalette.map((colorVal) {
                      final isSelected = _selectedColor == colorVal;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = colorVal),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Color(colorVal),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Color(colorVal).withValues(alpha: 0.6),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check, size: 16, color: Colors.black87),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A36),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: activeColor.withValues(alpha: 0.5),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isEdit ? LucideIcons.check : LucideIcons.plusCircle, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isEdit ? 'Save Changes' : 'Create Goal Vault',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String key, String label, Color color) {
    final isSelected = _selectedPriority == key;
    final isDark = AppColors.isDark(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.6)
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? (isDark ? Colors.white : color) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
