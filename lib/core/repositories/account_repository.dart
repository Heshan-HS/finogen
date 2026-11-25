import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/account_model.dart';
import '../providers/auth_state_provider.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final authType = ref.watch(authTypeProvider);
  if ((!kIsWeb && Platform.isWindows) || authType == AuthType.guest) {
    return LocalAccountRepository();
  }
  return CloudAccountRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

abstract class AccountRepository {
  Stream<List<AccountModel>> getUserAccounts();
  Future<void> addAccount(AccountModel account);
  Future<void> updateAccount(AccountModel account);
  Future<void> deleteAccount(String id);
}

class CloudAccountRepository implements AccountRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CloudAccountRepository({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  CollectionReference get _accounts => _firestore.collection('accounts');

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<List<AccountModel>> getUserAccounts() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _accounts
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AccountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  @override
  Future<void> addAccount(AccountModel account) async {
    final userId = currentUserId;
    if (userId == null) return;

    final data = account.copyWith(userId: userId).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _accounts.add(data);
  }

  @override
  Future<void> updateAccount(AccountModel account) async {
    await _accounts.doc(account.id).update(account.toMap());
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _accounts.doc(id).delete();
  }
}

class LocalAccountRepository implements AccountRepository {
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen('accounts')) {
      return await Hive.openBox('accounts');
    }
    return Hive.box('accounts');
  }

  @override
  Stream<List<AccountModel>> getUserAccounts() async* {
    final box = await _getBox();
    
    List<AccountModel> _mapBoxToList(Box b) {
      final list = b.keys.map((key) {
        final data = Map<String, dynamic>.from(b.get(key));
        return AccountModel.fromMap(data, key.toString());
      }).toList();
      return list;
    }

    yield _mapBoxToList(box);
    yield* box.watch().map((event) => _mapBoxToList(box));
  }

  @override
  Future<void> addAccount(AccountModel account) async {
    final box = await _getBox();
    final data = account.copyWith(userId: 'guest').toMap();
    data['createdAt'] = DateTime.now().toIso8601String();
    
    final id = account.id.isEmpty ? const Uuid().v4() : account.id;
    await box.put(id, data);
  }

  @override
  Future<void> updateAccount(AccountModel account) async {
    final box = await _getBox();
    await box.put(account.id, account.toMap());
  }

  @override
  Future<void> deleteAccount(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
