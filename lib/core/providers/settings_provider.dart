import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../repositories/settings_repository.dart';
export '../repositories/settings_repository.dart';
import '../utils/currency_utils.dart';
import '../services/currency_service.dart';



final settingsProvider = StreamProvider<SettingsModel>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getSettings();
});

final currencySymbolProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  final currencyString = settingsAsync.value?.currency ?? 'USD (\$)';
  return CurrencyUtils.extractSymbol(currencyString);
});

class CurrencyRateNotifier extends Notifier<double> {
  @override
  double build() {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value;
    print("CurrencyRateNotifier build called. Settings available: ${settings != null}");
    if (settings == null) {
      print("Settings is null, returning 1.0");
      return 1.0;
    }
    print("Base: ${settings.baseCurrency}, Display: ${settings.currency}");
    if (settings.baseCurrency == settings.currency) {
      print("Returning 1.0 because baseCurrency == currency");
      return 1.0;
    }
    
    if (settings.useLiveExchangeRate) {
      print("Fetching live exchange rate for ${settings.baseCurrency} to ${settings.currency}");
      _fetchLiveRate(settings);
      return settings.manualExchangeRate;
    } else {
      print("Returning manual exchange rate: ${settings.manualExchangeRate}");
      return settings.manualExchangeRate;
    }
  }

  Future<void> _fetchLiveRate(SettingsModel settings) async {
    final rate = await currencyService.getExchangeRate(settings.baseCurrency, settings.currency);
    print("Live exchange rate fetched: $rate");
    if (rate != null) {
      state = rate;
      print("State updated to: $state");
    } else {
      print("Live rate was null, state not updated. Current state is: $state");
    }
  }
}

final currencyRateProvider = NotifierProvider<CurrencyRateNotifier, double>(() {
  return CurrencyRateNotifier();
});
