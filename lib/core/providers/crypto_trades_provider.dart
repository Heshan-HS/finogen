import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_finance/core/models/crypto_trade_model.dart';
import 'package:nova_finance/core/repositories/crypto_trades_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final cryptoTradesRepositoryProvider = Provider<CryptoTradesRepository>((ref) {
  return CryptoTradesRepository();
});

final cryptoTradesProvider = StreamProvider<List<CryptoTradeModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  
  final repository = ref.watch(cryptoTradesRepositoryProvider);
  return repository.getUserTrades(user.uid);
});
