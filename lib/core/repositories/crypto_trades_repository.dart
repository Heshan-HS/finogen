import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_finance/core/models/crypto_trade_model.dart';

class CryptoTradesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTrade(CryptoTradeModel trade) async {
    try {
      await _firestore.collection('crypto_trades').add(trade.toMap());
    } catch (e) {
      throw Exception('Failed to add crypto trade: ');
    }
  }

  Stream<List<CryptoTradeModel>> getUserTrades(String userId) {
    return _firestore
        .collection('crypto_trades')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CryptoTradeModel.fromFirestore(doc)).toList();
    });
  }


  Future<void> updateTrade(CryptoTradeModel trade) async {
    try {
      await _firestore.collection('crypto_trades').doc(trade.id).update(trade.toMap());
    } catch (e) {
      throw Exception('Failed to update crypto trade: ');
    }
  }

  Future<void> deleteTrade(String tradeId) async {
    try {
      await _firestore.collection('crypto_trades').doc(tradeId).delete();
    } catch (e) {
      throw Exception('Failed to delete crypto trade: ');
    }
  }
}
