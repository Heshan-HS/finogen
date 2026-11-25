import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final String iconId;
  final bool isRecurring;
  final String frequency; // 'monthly', 'yearly', 'one_time'

  BillModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    required this.iconId,
    this.isRecurring = true,
    this.frequency = 'monthly',
  });

  /// Computes the active/upcoming due date.
  /// If [isRecurring] is true and [dueDate] is in the past,
  /// this calculates the next monthly cycle (e.g., Aug 22 -> Oct 22, 2026).
  DateTime get effectiveDueDate {
    if (!isRecurring) return dueDate;
    final now = DateTime.now();
    DateTime cycle = dueDate;
    while (DateTime(cycle.year, cycle.month, cycle.day, 23, 59, 59).isBefore(now)) {
      int nextMonth = cycle.month + 1;
      int nextYear = cycle.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear += 1;
      }
      final maxDays = DateTime(nextYear, nextMonth + 1, 0).day;
      final targetDay = dueDate.day > maxDays ? maxDays : dueDate.day;
      cycle = DateTime(nextYear, nextMonth, targetDay, dueDate.hour, dueDate.minute);
    }
    return cycle;
  }

  /// Calculates the next due date after [effectiveDueDate] (for advancing after payment).
  DateTime get nextCycleDueDate {
    final current = effectiveDueDate;
    int nextMonth = current.month + 1;
    int nextYear = current.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }
    final maxDays = DateTime(nextYear, nextMonth + 1, 0).day;
    final targetDay = dueDate.day > maxDays ? maxDays : dueDate.day;
    return DateTime(nextYear, nextMonth, targetDay, dueDate.hour, dueDate.minute);
  }

  factory BillModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BillModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'Utility',
      amount: (map['amount'] ?? 0.0).toDouble(),
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['dueDate']?.toString() ?? '') ?? DateTime.now(),
      isPaid: map['isPaid'] ?? false,
      iconId: map['iconId'] ?? 'zap',
      isRecurring: map['isRecurring'] ?? true,
      frequency: map['frequency'] ?? 'monthly',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
      'iconId': iconId,
      'isRecurring': isRecurring,
      'frequency': frequency,
    };
  }

  BillModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
    String? iconId,
    bool? isRecurring,
    String? frequency,
  }) {
    return BillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      iconId: iconId ?? this.iconId,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
    );
  }
}
