import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String userId;
  final int month;
  final int year;
  final double overallLimit;
  final Map<String, double> categoryLimits;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.overallLimit,
    required this.categoryLimits,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BudgetModel(
      id: documentId,
      userId: map['userId'] ?? '',
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
      overallLimit: (map['overallLimit'] ?? 0.0).toDouble(),
      categoryLimits: (map['categoryLimits'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'month': month,
      'year': year,
      'overallLimit': overallLimit,
      'categoryLimits': categoryLimits,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    int? month,
    int? year,
    double? overallLimit,
    Map<String, double>? categoryLimits,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      year: year ?? this.year,
      overallLimit: overallLimit ?? this.overallLimit,
      categoryLimits: categoryLimits ?? this.categoryLimits,
    );
  }
}
