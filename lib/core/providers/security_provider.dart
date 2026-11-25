import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class SecurityState {
  final bool biometricEnabled;
  final String? passcode;

  SecurityState({required this.biometricEnabled, this.passcode});

  SecurityState copyWith({bool? biometricEnabled, String? passcode}) {
    return SecurityState(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      passcode: passcode ?? this.passcode, // passing null keeps old passcode if we don't handle clearing, but here we will allow clearing if explicitly null. Wait, Dart doesn't have an easy "Option" type for copyWith, so let's just make it simpler.
    );
  }
}

class SecurityNotifier extends Notifier<SecurityState> {
  late SharedPreferences _prefs;

  @override
  SecurityState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return SecurityState(
      biometricEnabled: _prefs.getBool('biometricEnabled') ?? false,
      passcode: _prefs.getString('appPasscode'),
    );
  }

  Future<void> setBiometric(bool enabled) async {
    await _prefs.setBool('biometricEnabled', enabled);
    state = SecurityState(biometricEnabled: enabled, passcode: state.passcode);
  }

  Future<void> setPasscode(String? passcode) async {
    if (passcode == null || passcode.isEmpty) {
      await _prefs.remove('appPasscode');
    } else {
      await _prefs.setString('appPasscode', passcode);
    }
    state = SecurityState(biometricEnabled: state.biometricEnabled, passcode: passcode);
  }

  Future<void> clearAll() async {
    await _prefs.remove('biometricEnabled');
    await _prefs.remove('appPasscode');
    state = SecurityState(biometricEnabled: false, passcode: null);
  }
}

final securityProvider = NotifierProvider<SecurityNotifier, SecurityState>(() {
  return SecurityNotifier();
});
