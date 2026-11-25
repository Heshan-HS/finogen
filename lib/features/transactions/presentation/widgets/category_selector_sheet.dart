import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/transaction_category.dart';
import '../../../../core/theme/app_colors.dart';
import 'create_category_sheet.dart';

class CategorySelectorSheet extends StatelessWidget {
  final bool isIncome;

  const CategorySelectorSheet({super.key, required this.isIncome});

  static Future<TransactionCategory?> show(BuildContext context, {required bool isIncome}) {
    return showModalBottomSheet<TransactionCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySelectorSheet(isIncome: isIncome),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = isIncome ? CategoryProvider.getIncomeCategories() : CategoryProvider.getExpenseCategories();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
            'Select Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.8,
              ),
              itemCount: categories.length + 1, // +1 for "Add New"
              itemBuilder: (context, index) {
                if (index == categories.length) {
                  return _buildAddNewCategory(context);
                }
                return _buildCategoryItem(context, categories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, TransactionCategory category) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, category),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.elevated(context),
              shape: BoxShape.circle,
              border: Border.all(color: category.color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: category.color.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(category.icon, color: category.color, size: 28),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewCategory(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final newCategory = await CreateCategorySheet.show(context, isIncome: isIncome);
        if (newCategory != null) {
          // Pass the newly created category back to the main screen
          Navigator.pop(context, newCategory);
        }
      },
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.elevated(context).withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.muted(context).withOpacity(0.3), width: 1, style: BorderStyle.solid), // Actually dashed border would be nice, but solid is fine for now
            ),
            child: Center(
              child: Icon(LucideIcons.plus, color: AppColors.muted(context), size: 28),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add New',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}
