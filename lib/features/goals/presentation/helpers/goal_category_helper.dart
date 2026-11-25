import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GoalCategoryDef {
  final String key;
  final String label;
  final IconData icon;
  final int defaultColor;
  final String subtitle;

  const GoalCategoryDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.defaultColor,
    required this.subtitle,
  });
}

class GoalCategoryHelper {
  static const List<GoalCategoryDef> categories = [
    GoalCategoryDef(
      key: 'emergency',
      label: 'Emergency Shield',
      icon: LucideIcons.shield,
      defaultColor: 0xFF005A36,
      subtitle: 'Safety reserve for unplanned life events',
    ),
    GoalCategoryDef(
      key: 'tech',
      label: 'Tech & Gear',
      icon: LucideIcons.laptop,
      defaultColor: 0xFF3B82F6,
      subtitle: 'MacBook, devices & workstation upgrades',
    ),
    GoalCategoryDef(
      key: 'novagen',
      label: 'NovaGen Business',
      icon: LucideIcons.globe,
      defaultColor: 0xFF007A4D,
      subtitle: 'Server VPS, IP pools & infrastructure fund',
    ),
    GoalCategoryDef(
      key: 'vehicle',
      label: 'Vehicle & Transport',
      icon: LucideIcons.car,
      defaultColor: 0xFFF59E0B,
      subtitle: 'Vehicle maintenance, upgrades & fuel buffer',
    ),
    GoalCategoryDef(
      key: 'travel',
      label: 'Vacation & Trips',
      icon: LucideIcons.plane,
      defaultColor: 0xFF8B5CF6,
      subtitle: 'Holiday trips, getaways & leisure adventures',
    ),
    GoalCategoryDef(
      key: 'crypto',
      label: 'Crypto & Assets',
      icon: LucideIcons.trendingUp,
      defaultColor: 0xFFEC4899,
      subtitle: 'Long-term spot accumulation & capital pool',
    ),
    GoalCategoryDef(
      key: 'home',
      label: 'Home & Living',
      icon: LucideIcons.home,
      defaultColor: 0xFF14B8A6,
      subtitle: 'Apartment down-payment, decor & furniture',
    ),
    GoalCategoryDef(
      key: 'general',
      label: 'Personal Vault',
      icon: LucideIcons.target,
      defaultColor: 0xFF6366F1,
      subtitle: 'Milestone target with custom deadlines',
    ),
  ];

  static GoalCategoryDef getCategory(String? key) {
    if (key == null) return categories.last;
    return categories.firstWhere(
      (c) => c.key.toLowerCase() == key.toLowerCase(),
      orElse: () => categories.last,
    );
  }

  static IconData getIcon(String? iconName, [String? categoryKey]) {
    if (iconName != null && iconName.isNotEmpty) {
      switch (iconName.toLowerCase()) {
        case 'shield':
          return LucideIcons.shield;
        case 'laptop':
          return LucideIcons.laptop;
        case 'globe':
          return LucideIcons.globe;
        case 'car':
          return LucideIcons.car;
        case 'plane':
          return LucideIcons.plane;
        case 'trendingup':
        case 'trending_up':
          return LucideIcons.trendingUp;
        case 'home':
          return LucideIcons.home;
        case 'gift':
          return LucideIcons.gift;
        case 'heart':
          return LucideIcons.heart;
        case 'target':
          return LucideIcons.target;
      }
    }
    return getCategory(categoryKey).icon;
  }
}
