import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../providers/auth_state_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final authType = ref.watch(authTypeProvider);
  
  if ((!kIsWeb && Platform.isWindows) || authType == AuthType.guest) {
    return LocalTransactionRepository();
  } else {
    return CloudTransactionRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
  }
});

abstract class TransactionRepository {
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Stream<List<TransactionModel>> getUserTransactions();
}

class CloudTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CloudTransactionRepository(this._firestore, this._auth);

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference get _transactions => _firestore.collection('transactions');

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final uid = currentUserId;
    if (uid == null) throw Exception("User not logged in");
    
    final data = transaction.toMap();
    data['userId'] = uid;
    
    await _transactions.add(data);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final uid = currentUserId;
    if (uid == null) throw Exception("User not logged in");
    
    final data = transaction.toMap();
    data['userId'] = uid;
    
    await _transactions.doc(transaction.id).update(data);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final uid = currentUserId;
    if (uid == null) throw Exception("User not logged in");
    
    await _transactions.doc(id).delete();
  }

  @override
  Stream<List<TransactionModel>> getUserTransactions() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _transactions
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    });
  }
}

class LocalTransactionRepository implements TransactionRepository {
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen('transactions')) {
      return await Hive.openBox('transactions');
    }
    return Hive.box('transactions');
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final box = await _getBox();
    final data = transaction.toMap();
    // Convert Timestamp to ISO8601 for local storage
    data['date'] = transaction.date.toIso8601String();
    
    final id = transaction.id.isEmpty ? const Uuid().v4() : transaction.id;
    await box.put(id, data);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final box = await _getBox();
    final data = transaction.toMap();
    data['date'] = transaction.date.toIso8601String();
    
    await box.put(transaction.id, data);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Stream<List<TransactionModel>> getUserTransactions() async* {
    final box = await _getBox();
    
    List<TransactionModel> _mapBoxToList(Box b) {
      final list = b.keys.map((key) {
        final data = Map<String, dynamic>.from(b.get(key));
        return TransactionModel(
          id: key.toString(),
          userId: 'guest',
          accountId: data['accountId'] ?? '',
          amount: (data['amount'] ?? 0.0).toDouble(),
          categoryId: data['categoryId'] ?? '',
          note: data['note'] ?? '',
          date: DateTime.parse(data['date'] as String),
          isIncome: data['isIncome'] ?? false,
          externalRefId: data['externalRefId'],
        );
      }).toList();
      
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }

    yield _mapBoxToList(box);
    yield* box.watch().map((event) => _mapBoxToList(box));
  }
}
