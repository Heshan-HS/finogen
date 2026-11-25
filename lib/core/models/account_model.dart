import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountType { cash, bank, creditCard }

class AccountModel {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance; // Current balance (can be negative for credit cards)
  final double creditLimit; // Only applicable for credit cards
  final int colorValue; // To store color for UI
  final bool isEnabled;
  final bool excludeFromTotal; // Exclude from main dashboard balance & metrics (e.g. GF Holding)

  AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.creditLimit = 0.0,
    required this.colorValue,
    this.isEnabled = true,
    this.excludeFromTotal = false,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AccountModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: AccountType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'cash'),
        orElse: () => AccountType.cash,
      ),
      balance: (map['balance'] ?? 0.0).toDouble(),
      creditLimit: (map['creditLimit'] ?? 0.0).toDouble(),
      colorValue: map['colorValue'] ?? 0xFF00D9A8, // Default to primary color
      isEnabled: map['isEnabled'] ?? true,
      excludeFromTotal: map['excludeFromTotal'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'balance': balance,
      'creditLimit': creditLimit,
      'colorValue': colorValue,
      'isEnabled': isEnabled,
      'excludeFromTotal': excludeFromTotal,
    };
  }

  AccountModel copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? balance,
    double? creditLimit,
    int? colorValue,
    bool? isEnabled,
    bool? excludeFromTotal,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      colorValue: colorValue ?? this.colorValue,
      isEnabled: isEnabled ?? this.isEnabled,
      excludeFromTotal: excludeFromTotal ?? this.excludeFromTotal,
    );
  }
}
