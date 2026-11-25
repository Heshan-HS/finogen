import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.value,
      'isIncome': isIncome,
    };
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
      id: map['id'],
      name: map['name'],
      icon: IconData(
        map['iconCode'], 
        fontFamily: map['iconFontFamily'], 
        fontPackage: map['iconFontPackage']
      ),
      color: Color(map['colorValue']),
      isIncome: map['isIncome'],
    );
  }
}


class CategoryProvider {
  static final List<TransactionCategory> _defaultIncomeCategories = [
    const TransactionCategory(
      id: 'inc_salary',
      name: 'Salary',
      icon: LucideIcons.banknote,
      color: Color(0xFF00D9A8), // Primary green
      isIncome: true,
    ),
    const TransactionCategory(
      id: 'inc_freelance',
      name: 'Freelance',
      icon: LucideIcons.laptop,
      color: Color(0xFF4A90E2), // Blue
      isIncome: true,
    ),
    const TransactionCategory(
      id: 'inc_rental',
      name: 'Rental',
      icon: LucideIcons.home,
      color: Color(0xFFE2A04A), // Orange
      isIncome: true,
    ),
    const TransactionCategory(
      id: 'inc_bonus',
      name: 'Bonus',
      icon: LucideIcons.gift,
      color: Color(0xFFC8F73A), // Neon yellow-green
      isIncome: true,
    ),
    const TransactionCategory(
      id: 'inc_refund',
      name: 'Refund',
      icon: LucideIcons.undo,
      color: Color(0xFF9013FE), // Purple
      isIncome: true,
    ),
    const TransactionCategory(
      id: 'inc_transfer',
      name: 'Transfer In',
      icon: LucideIcons.arrowDownLeft,
      color: Color(0xFF4A90E2), // Blue
      isIncome: true,
    ),
    const TransactionCategory(
      id: 'inc_novagen',
      name: 'NovaGen SpeedNet',
      icon: LucideIcons.globe,
      color: Color(0xFF00E5FF), // Cyan
      isIncome: true,
    ),
  ];

  static final List<TransactionCategory> _defaultExpenseCategories = [
    const TransactionCategory(
      id: 'exp_food',
      name: 'Food',
      icon: LucideIcons.utensils,
      color: Color(0xFFFF5252), // Red
      isIncome: false,
    ),
    const TransactionCategory(
      id: 'exp_transport',
      name: 'Transport',
      icon: LucideIcons.car,
      color: Color(0xFF4A90E2), // Blue
      isIncome: false,
    ),
    const TransactionCategory(
      id: 'exp_shopping',
      name: 'Shopping',
      icon: LucideIcons.shoppingBag,
      color: Color(0xFFFF4081), // Pink
      isIncome: false,
    ),
    const TransactionCategory(
      id: 'exp_bills',
      name: 'Bills',
      icon: LucideIcons.receipt,
      color: Color(0xFFE2A04A), // Orange
      isIncome: false,
    ),
    const TransactionCategory(
      id: 'exp_entertainment',
      name: 'Entertainment',
      icon: LucideIcons.film,
      color: Color(0xFF9013FE), // Purple
      isIncome: false,
    ),
    const TransactionCategory(
      id: 'exp_health',
      name: 'Health',
      icon: LucideIcons.heartPulse,
      color: Color(0xFF00D9A8), // Green
      isIncome: false,
    ),
    const TransactionCategory(
      id: 'exp_transfer',
      name: 'Transfer Out',
      icon: LucideIcons.arrowUpRight,
      color: Color(0xFF4A90E2), // Blue
      isIncome: false,
    ),
    const TransactionCategory(
      id: 'exp_novagen_server',
      name: 'Netcup Server',
      icon: LucideIcons.server,
      color: Color(0xFF7C4DFF), // Purple
      isIncome: false,
    ),
    const TransactionCategory(
      id: 'exp_novagen_draw',
      name: 'NovaGen Drawing',
      icon: LucideIcons.wallet,
      color: Color(0xFFFF9100), // Amber
      isIncome: false,
    ),
  ];

  // In-memory list to store custom categories created by user
  static final List<TransactionCategory> _customCategories = [];

  static List<TransactionCategory> getIncomeCategories() {
    return [
      ..._defaultIncomeCategories,
      ..._customCategories.where((c) => c.isIncome),
    ];
  }

  static List<TransactionCategory> getExpenseCategories() {
    return [
      ..._defaultExpenseCategories,
      ..._customCategories.where((c) => !c.isIncome),
    ];
  }


  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('custom_categories');
    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        _customCategories.clear();
        for(var item in list) {
          _customCategories.add(TransactionCategory.fromMap(item as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error loading categories: $e');
      }
    }
  }

  static Future<void> addCustomCategory(TransactionCategory category) async {
    _customCategories.add(category);
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_customCategories.map((c) => c.toMap()).toList());
    await prefs.setString('custom_categories', jsonStr);
  }
}
