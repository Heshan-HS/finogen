import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_model.dart';

import '../repositories/account_repository.dart';

// Stream of accounts for the current user
final accountsStreamProvider = StreamProvider<List<AccountModel>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getUserAccounts();
});

// A provider to quickly fetch a specific account by ID
final accountByIdProvider = Provider.family<AccountModel?, String>((ref, id) {
  final accounts = ref.watch(accountsStreamProvider).value;
  if (accounts == null) return null;
  try {
    return accounts.firstWhere((acc) => acc.id == id);
  } catch (e) {
    return null;
  }
});

// A default primary account (e.g. main Cash wallet)
final primaryAccountProvider = Provider<AccountModel?>((ref) {
  final accounts = ref.watch(accountsStreamProvider).value;
  if (accounts == null || accounts.isEmpty) return null;
  return accounts.first;
});
