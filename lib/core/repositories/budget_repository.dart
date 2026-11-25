import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';
import '../providers/auth_state_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final authType = ref.watch(authTypeProvider);
  if ((!kIsWeb && Platform.isWindows) || authType == AuthType.guest) {
    return LocalBudgetRepository();
  }
  return CloudBudgetRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

abstract class BudgetRepository {
  Stream<BudgetModel?> getBudgetForMonth(int month, int year);
  Future<void> saveBudget(BudgetModel budget);
}

class CloudBudgetRepository implements BudgetRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CloudBudgetRepository({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  CollectionReference get _budgets => _firestore.collection('budgets');

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<BudgetModel?> getBudgetForMonth(int month, int year) {
    final userId = currentUserId;
    if (userId == null) return Stream.value(null);

    return _budgets
        .where('userId', isEqualTo: userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return BudgetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    final userId = currentUserId;
    if (userId == null) return;

    final data = budget.copyWith(userId: userId).toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (budget.id.isEmpty) {
      await _budgets.add(data);
    } else {
      await _budgets.doc(budget.id).update(data);
    }
  }
}

class LocalBudgetRepository implements BudgetRepository {
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen('budgets')) {
      return await Hive.openBox('budgets');
    }
    return Hive.box('budgets');
  }

  @override
  Stream<BudgetModel?> getBudgetForMonth(int month, int year) async* {
    final box = await _getBox();
    
    BudgetModel? _findBudget(Box b) {
      for (var key in b.keys) {
        final data = Map<String, dynamic>.from(b.get(key));
        if (data['month'] == month && data['year'] == year) {
          return BudgetModel.fromMap(data, key.toString());
        }
      }
      return null;
    }

    yield _findBudget(box);
    yield* box.watch().map((event) => _findBudget(box));
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    final box = await _getBox();
    final data = budget.copyWith(userId: 'guest').toMap();
    
    final id = budget.id.isEmpty ? const Uuid().v4() : budget.id;
    await box.put(id, data);
  }
}
