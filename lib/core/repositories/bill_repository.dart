import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_model.dart';
import '../providers/auth_state_provider.dart';

final billRepositoryProvider = Provider<BillRepository>((ref) {
  final authType = ref.watch(authTypeProvider);
  if ((!kIsWeb && Platform.isWindows) || authType == AuthType.guest) {
    return LocalBillRepository();
  }
  return CloudBillRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

abstract class BillRepository {
  Stream<List<BillModel>> getUserBills();
  Future<void> addBill(BillModel bill);
  Future<void> updateBill(BillModel bill);
  Future<void> deleteBill(String id);
}

class CloudBillRepository implements BillRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CloudBillRepository({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  CollectionReference get _bills => _firestore.collection('bills');

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<List<BillModel>> getUserBills() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _bills
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bills = snapshot.docs
          .map((doc) => BillModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      bills.sort((a, b) => a.dueDate.compareTo(b.dueDate)); 
      return bills;
    });
  }

  @override
  Future<void> addBill(BillModel bill) async {
    final userId = currentUserId;
    if (userId == null) return;

    final data = bill.copyWith(userId: userId).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _bills.add(data);
  }

  @override
  Future<void> updateBill(BillModel bill) async {
    await _bills.doc(bill.id).update(bill.toMap());
  }

  @override
  Future<void> deleteBill(String id) async {
    await _bills.doc(id).delete();
  }
}

class LocalBillRepository implements BillRepository {
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen('bills')) {
      return await Hive.openBox('bills');
    }
    return Hive.box('bills');
  }

  @override
  Stream<List<BillModel>> getUserBills() async* {
    final box = await _getBox();
    
    List<BillModel> _mapBoxToList(Box b) {
      final list = b.keys.map((key) {
        final data = Map<String, dynamic>.from(b.get(key));
        return BillModel.fromMap(data, key.toString());
      }).toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    }

    yield _mapBoxToList(box);
    yield* box.watch().map((event) => _mapBoxToList(box));
  }

  @override
  Future<void> addBill(BillModel bill) async {
    final box = await _getBox();
    final data = bill.copyWith(userId: 'guest').toMap();
    data['createdAt'] = DateTime.now().toIso8601String();
    
    final id = bill.id.isEmpty ? const Uuid().v4() : bill.id;
    await box.put(id, data);
  }

  @override
  Future<void> updateBill(BillModel bill) async {
    final box = await _getBox();
    await box.put(bill.id, bill.toMap());
  }

  @override
  Future<void> deleteBill(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
