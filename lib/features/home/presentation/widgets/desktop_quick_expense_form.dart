import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class DesktopQuickExpenseForm extends StatelessWidget {
  const DesktopQuickExpenseForm({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      withGlow: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Add Expense', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Amount', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    const TextField(
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '\$0.00',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.dollarSign, color: AppColors.primary, size: 20),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar, color: Colors.white54, size: 14),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Select Date', style: TextStyle(color: Colors.white, fontSize: 11), maxLines: 1)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PopupMenuButton<String>(
                  color: const Color(0xFF1E293B),
                  onSelected: (value) {},
                  itemBuilder: (context) => ['Main Account', 'Savings', 'Cash']
                      .map((e) => PopupMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(LucideIcons.wallet, color: Colors.white54, size: 14),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Main', style: TextStyle(color: Colors.white, fontSize: 11), maxLines: 1)),
                        Icon(LucideIcons.chevronDown, color: Colors.white54, size: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Row(children: [Icon(LucideIcons.checkCircle, color: Colors.green), SizedBox(width: 8), Text('Success', style: TextStyle(color: Colors.white))]),
                    content: const Text('Your expense has been added successfully!', style: TextStyle(color: Colors.white70)),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: AppColors.primary)))],
                  ),
                );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Expense', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
