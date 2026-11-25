import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/goal_model.dart';
import '../providers/auth_state_provider.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final authType = ref.watch(authTypeProvider);
  if ((!kIsWeb && Platform.isWindows) || authType == AuthType.guest) {
    return LocalGoalRepository();
  }
  return CloudGoalRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

abstract class GoalRepository {
  Stream<List<GoalModel>> getUserGoals();
  Future<void> addGoal(GoalModel goal);
  Future<void> updateGoal(GoalModel goal);
  Future<void> deleteGoal(String id);
}

class CloudGoalRepository implements GoalRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CloudGoalRepository({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  CollectionReference get _goals => _firestore.collection('goals');

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<List<GoalModel>> getUserGoals() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _goals
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final goals = snapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      goals.sort((a, b) => b.id.compareTo(a.id)); 
      return goals;
    });
  }

  @override
  Future<void> addGoal(GoalModel goal) async {
    final userId = currentUserId;
    if (userId == null) return;

    final data = goal.copyWith(userId: userId).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _goals.add(data);
  }

  @override
  Future<void> updateGoal(GoalModel goal) async {
    await _goals.doc(goal.id).update(goal.toMap());
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _goals.doc(id).delete();
  }
}

class LocalGoalRepository implements GoalRepository {
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen('goals')) {
      return await Hive.openBox('goals');
    }
    return Hive.box('goals');
  }

  @override
  Stream<List<GoalModel>> getUserGoals() async* {
    final box = await _getBox();
    
    List<GoalModel> _mapBoxToList(Box b) {
      final list = b.keys.map((key) {
        final data = Map<String, dynamic>.from(b.get(key));
        return GoalModel.fromMap(data, key.toString());
      }).toList();
      list.sort((a, b) => b.id.compareTo(a.id));
      return list;
    }

    yield _mapBoxToList(box);
    yield* box.watch().map((event) => _mapBoxToList(box));
  }

  @override
  Future<void> addGoal(GoalModel goal) async {
    final box = await _getBox();
    final data = goal.copyWith(userId: 'guest').toMap();
    data['createdAt'] = DateTime.now().toIso8601String();
    
    final id = goal.id.isEmpty ? const Uuid().v4() : goal.id;
    await box.put(id, data);
  }

  @override
  Future<void> updateGoal(GoalModel goal) async {
    final box = await _getBox();
    await box.put(goal.id, goal.toMap());
  }

  @override
  Future<void> deleteGoal(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
