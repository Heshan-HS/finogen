import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/transaction_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class CreateCategorySheet extends ConsumerStatefulWidget {
  final bool isIncome;

  const CreateCategorySheet({super.key, required this.isIncome});

  static Future<TransactionCategory?> show(BuildContext context, {required bool isIncome}) {
    return showModalBottomSheet<TransactionCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCategorySheet(isIncome: isIncome),
    );
  }

  @override
  ConsumerState<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<CreateCategorySheet> {
  final TextEditingController _nameController = TextEditingController();
  
  final List<IconData> _availableIcons = [
    LucideIcons.star, LucideIcons.briefcase, LucideIcons.heart, 
    LucideIcons.home, LucideIcons.car, LucideIcons.coffee,
    LucideIcons.plane, LucideIcons.music, LucideIcons.shoppingCart,
    LucideIcons.book, LucideIcons.monitor, LucideIcons.smartphone,
    LucideIcons.gamepad2, LucideIcons.smile, LucideIcons.zap,
  ];
  
  final List<Color> _availableColors = [
    const Color(0xFF00D9A8), // Primary Green
    const Color(0xFF4A90E2), // Blue
    const Color(0xFFFF5252), // Red
    const Color(0xFFE2A04A), // Orange
    const Color(0xFFFF4081), // Pink
    const Color(0xFF9013FE), // Purple
    const Color(0xFFC8F73A), // Neon yellow
    const Color(0xFF00E5FF), // Cyan
  ];

  late IconData _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedIcon = _availableIcons[0];
    _selectedColor = _availableColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_nameController.text.trim().isEmpty) return;
    
    final newCategory = TransactionCategory(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      isIncome: widget.isIncome,
    );
    
    CategoryProvider.addCustomCategory(newCategory);
    Navigator.pop(context, newCategory);
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom inset for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.muted(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text(
            'Create Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Input
                  Text('Category Name', style: TextStyle(fontSize: 14, color: AppColors.muted(context))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.elevated(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor(context)),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: AppColors.text(context), fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'E.g. Groceries',
                        hintStyle: TextStyle(color: AppColors.muted(context)),
                      ),
                      cursorColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Color Selection
                  Text('Color', style: TextStyle(fontSize: 14, color: AppColors.muted(context))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _availableColors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.text(context) : Colors.transparent, 
                              width: 3
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(color: color.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)
                            ] : [],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Icon Selection
                  Text('Icon', style: TextStyle(fontSize: 14, color: AppColors.muted(context))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _availableIcons.map((icon) {
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? _selectedColor.withOpacity(0.2) : AppColors.elevated(context),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? _selectedColor : AppColors.borderColor(context),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            icon, 
                            color: isSelected ? _selectedColor : AppColors.muted(context),
                            size: 20,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Save Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                onPressed: _saveCategory,
                text: 'Create Category',
                isFullWidth: true,
                variant: AppButtonVariant.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
