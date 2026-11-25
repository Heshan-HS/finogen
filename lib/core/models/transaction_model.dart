import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String accountId;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final bool isIncome;
  final String? externalRefId;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.date,
    required this.isIncome,
    this.externalRefId,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      accountId: data['accountId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      note: data['note'] ?? '',
      date: data['date'] is Timestamp 
          ? (data['date'] as Timestamp).toDate() 
          : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      isIncome: data['isIncome'] ?? false,
      externalRefId: data['externalRefId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountId': accountId,
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'date': Timestamp.fromDate(date),
      'isIncome': isIncome,
      if (externalRefId != null) 'externalRefId': externalRefId,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? accountId,
    double? amount,
    String? categoryId,
    String? note,
    DateTime? date,
    bool? isIncome,
    String? externalRefId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      externalRefId: externalRefId ?? this.externalRefId,
    );
  }
}
