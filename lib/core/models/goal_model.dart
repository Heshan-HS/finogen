import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final int colorValue;
  final String category; // 'emergency', 'tech', 'novagen', 'vehicle', 'travel', 'crypto', 'home', 'general'
  final String iconName; // 'shield', 'laptop', 'globe', 'car', 'plane', 'trendingUp', 'home', 'target'
  final String priority; // 'high', 'medium', 'low'
  final String? linkedAccountId;

  GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.colorValue,
    this.category = 'general',
    this.iconName = 'target',
    this.priority = 'medium',
    this.linkedAccountId,
  });

  // Smart calculations and forecasting getters
  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentAmount >= targetAmount && targetAmount > 0;
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  int get daysRemaining {
    if (deadline == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return target.difference(today).inDays;
  }

  double get dailyRequired {
    if (daysRemaining <= 0 || remainingAmount <= 0) return 0.0;
    return remainingAmount / daysRemaining;
  }

  double get monthlyRequired => dailyRequired * 30.0;

  int get milestoneStage {
    if (progress >= 1.0) return 4;
    if (progress >= 0.75) return 3;
    if (progress >= 0.50) return 2;
    if (progress >= 0.25) return 1;
    return 0;
  }

  String get milestoneTitle {
    switch (milestoneStage) {
      case 4:
        return 'Conquered';
      case 3:
        return 'Momentum';
      case 2:
        return 'Halfway';
      case 1:
        return 'Growth';
      default:
        return 'Started';
    }
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GoalModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0.0).toDouble(),
      deadline: map['deadline'] != null
          ? (map['deadline'] is Timestamp
              ? (map['deadline'] as Timestamp).toDate()
              : DateTime.tryParse(map['deadline'].toString()))
          : null,
      colorValue: map['colorValue'] ?? 0xFF00D9A8,
      category: map['category'] ?? 'general',
      iconName: map['iconName'] ?? 'target',
      priority: map['priority'] ?? 'medium',
      linkedAccountId: map['linkedAccountId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'colorValue': colorValue,
      'category': category,
      'iconName': iconName,
      'priority': priority,
      'linkedAccountId': linkedAccountId,
    };
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    int? colorValue,
    String? category,
    String? iconName,
    String? priority,
    String? linkedAccountId,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      colorValue: colorValue ?? this.colorValue,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      priority: priority ?? this.priority,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
    );
  }
}

