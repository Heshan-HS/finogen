import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings_model.dart';
import '../providers/auth_state_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final authType = ref.watch(authTypeProvider);
  if (authType == AuthType.guest) {
    return LocalSettingsRepository();
  }
  return CloudSettingsRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

abstract class SettingsRepository {
  Future<void> updateSettings(SettingsModel settings);
  Stream<SettingsModel> getSettings();
}

class CloudSettingsRepository implements SettingsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CloudSettingsRepository(this._firestore, this._auth);

  String? get currentUserId => _auth.currentUser?.uid;

  DocumentReference get _settingsDoc {
    final uid = currentUserId;
    if (uid == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(uid).collection('settings').doc('preferences');
  }

  @override
  Future<void> updateSettings(SettingsModel settings) async {
    try {
      await _settingsDoc.set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      // ignore
    }
  }

  @override
  Stream<SettingsModel> getSettings() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(SettingsModel.initial());

    return _settingsDoc.snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return SettingsModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return SettingsModel.initial();
    });
  }
}

class LocalSettingsRepository implements SettingsRepository {
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen('settings')) {
      return await Hive.openBox('settings');
    }
    return Hive.box('settings');
  }

  @override
  Stream<SettingsModel> getSettings() async* {
    final box = await _getBox();
    
    SettingsModel _readSettings(Box b) {
      final data = b.get('preferences');
      if (data != null) {
        return SettingsModel.fromMap(Map<String, dynamic>.from(data));
      }
      return SettingsModel.initial();
    }

    yield _readSettings(box);
    yield* box.watch(key: 'preferences').map((event) => _readSettings(box));
  }

  @override
  Future<void> updateSettings(SettingsModel settings) async {
    final box = await _getBox();
    await box.put('preferences', settings.toMap());
  }
}
