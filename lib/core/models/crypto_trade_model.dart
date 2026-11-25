import 'package:cloud_firestore/cloud_firestore.dart';

class CryptoTradeModel {
  final String id;
  final String userId;
  final String pair;
  final double pnl;
  final bool isLong;
  final DateTime date;

  CryptoTradeModel({
    required this.id,
    required this.userId,
    required this.pair,
    required this.pnl,
    required this.isLong,
    required this.date,
  });

  factory CryptoTradeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CryptoTradeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      pair: data['pair'] ?? '',
      pnl: (data['pnl'] ?? 0.0).toDouble(),
      isLong: data['isLong'] ?? true,
      date: data['date'] is Timestamp 
          ? (data['date'] as Timestamp).toDate() 
          : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pair': pair,
      'pnl': pnl,
      'isLong': isLong,
      'date': Timestamp.fromDate(date),
    };
  }
}
