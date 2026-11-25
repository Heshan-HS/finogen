import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/currency_utils.dart';

class CurrencyService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest/';
  
  static const String _cachePrefix = 'exchange_rate_';
  static const String _lastFetchPrefix = 'exchange_rate_time_';

  Future<double?> getExchangeRate(String baseCurrency, String displayCurrency) async {
    final baseIso = _extractIsoCode(baseCurrency);
    final targetIso = _extractIsoCode(displayCurrency);

    if (baseIso == null || targetIso == null || baseIso == targetIso) return 1.0;

    final cacheKey = '$_cachePrefix${baseIso}_$targetIso';
    final timeKey = '$_lastFetchPrefix${baseIso}_$targetIso';

    final prefs = await SharedPreferences.getInstance();
    
    final lastFetch = prefs.getInt(timeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cachedRate = prefs.getDouble(cacheKey);

    // Use cache if less than 24 hours old
    if (cachedRate != null && (now - lastFetch) < 86400000) {
      return cachedRate;
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl$baseIso'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null && data['rates'][targetIso] != null) {
          final rate = (data['rates'][targetIso] as num).toDouble();
          await prefs.setDouble(cacheKey, rate);
          await prefs.setInt(timeKey, now);
          return rate;
        }
      }
    } catch (e) {
      return cachedRate;
    }
    
    return cachedRate;
  }

  String? _extractIsoCode(String currencyString) {
    final parts = currencyString.split(' ');
    if (parts.isNotEmpty) {
      return parts[0].toUpperCase();
    }
    return null;
  }
}

final currencyService = CurrencyService();
