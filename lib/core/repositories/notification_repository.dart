import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../providers/auth_state_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final authType = ref.watch(authTypeProvider);
  if ((!kIsWeb && Platform.isWindows) || authType == AuthType.guest) {
    return LocalNotificationRepository();
  }
  return CloudNotificationRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

abstract class NotificationRepository {
  Stream<List<NotificationModel>> getNotifications();
  Future<void> markAllAsRead();
  Future<void> addNotification(NotificationModel notification);
}

class CloudNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CloudNotificationRepository(this._firestore, this._auth);

  CollectionReference get _notificationsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  @override
  Stream<List<NotificationModel>> getNotifications() {
    try {
      return _notificationsRef
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return NotificationModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final snapshot = await _notificationsRef.where('isRead', isEqualTo: false).get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final data = notification.toMap();
      await _notificationsRef.add(data);
    } catch (e) {
      print('Error adding notification: $e');
    }
  }
}

class LocalNotificationRepository implements NotificationRepository {
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen('notifications')) {
      return await Hive.openBox('notifications');
    }
    return Hive.box('notifications');
  }

  @override
  Stream<List<NotificationModel>> getNotifications() async* {
    final box = await _getBox();
    
    List<NotificationModel> _readNotifications(Box b) {
      final list = b.keys.map((key) {
        final data = Map<String, dynamic>.from(b.get(key));
        return NotificationModel.fromMap(data, key.toString());
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    yield _readNotifications(box);
    yield* box.watch().map((event) => _readNotifications(box));
  }

  @override
  Future<void> markAllAsRead() async {
    final box = await _getBox();
    for (var key in box.keys) {
      final data = Map<String, dynamic>.from(box.get(key));
      if (data['isRead'] == false) {
        data['isRead'] = true;
        await box.put(key, data);
      }
    }
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    final box = await _getBox();
    final data = notification.toMap();
    final id = notification.id.isEmpty ? const Uuid().v4() : notification.id;
    await box.put(id, data);
  }
}
