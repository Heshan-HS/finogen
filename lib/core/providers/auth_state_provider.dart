import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_provider.dart';

enum AuthType { guest, google, unauthenticated }

final authTypeProvider = Provider<AuthType>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final isGuest = prefs.getBool('isGuest') ?? false;
  
  if (isGuest) {
    return AuthType.guest;
  }

  try {
    if (Firebase.apps.isNotEmpty) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        return AuthType.google;
      }
    }
  } catch (e) {
    // Ignore if Firebase is not initialized
  }
  
  return AuthType.unauthenticated;
});
