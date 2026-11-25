import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MexcSyncService {
  static const String _backendUrl = 'https://finance.novagen.software/api/crypto/mexc/balance';
  static const String _apiKey = 'finogen-secure-2024';

  static Future<void> syncMexcBalance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[MexcSyncService] No user logged in.');
        return;
      }
      print('[MexcSyncService] Sync starting for: ' + user.uid);

      final response = await http.get(
        Uri.parse(_backendUrl),
        headers: {'x-finogen-api-key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('[MexcSyncService] Failed. HTTP ' + response.statusCode.toString());
        return;
      }

      final data = json.decode(response.body);
      if (data['success'] != true) return;

      final double totalUsdt = (data['totalUsdt'] as num).toDouble();
      print('[MexcSyncService] USDT: ' + totalUsdt.toString());

      double usdToLkrRate = 330.0;
      try {
        final rateResp = await http.get(
          Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
        ).timeout(const Duration(seconds: 5));
        if (rateResp.statusCode == 200) {
          final rateData = json.decode(rateResp.body);
          usdToLkrRate = (rateData['rates']['LKR'] as num).toDouble();
          print('[MexcSyncService] Rate: ' + usdToLkrRate.toString());
        }
      } catch (e) {
        print('[MexcSyncService] Rate fetch failed, fallback 330.0');
      }

      final double newBalanceLkr = totalUsdt * usdToLkrRate;
      print('[MexcSyncService] LKR balance: ' + newBalanceLkr.toString());

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .where('name', isEqualTo: 'Mexc Account')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final currentBalance = (doc.data()['balance'] as num?)?.toDouble() ?? 0.0;
        if ((currentBalance - newBalanceLkr).abs() > 1.0) {
          await doc.reference.update({
            'balance': newBalanceLkr,
            'lastSyncedAt': FieldValue.serverTimestamp(),
          });
          print('[MexcSyncService] Synced OK: ' + newBalanceLkr.toString());
        } else {
          print('[MexcSyncService] No update needed.');
        }
      } else {
        print('[MexcSyncService] Mexc Account NOT FOUND in Firestore!');
      }
    } catch (e) {
      print('[MexcSyncService] Error: ' + e.toString());
    }
  }
}