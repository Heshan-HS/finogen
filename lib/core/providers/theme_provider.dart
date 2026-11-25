import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'security_provider.dart';

/// Persisted theme mode provider using SharedPreferences
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'app_theme_mode';
  static const _platform = MethodChannel('com.example.nova_finance/theme');

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_key);
    final mode = (stored == 'light') ? ThemeMode.light : ThemeMode.dark;
    
    // Sync to Android OS on build
    _syncToNative(mode);
    return mode;
  }

  Future<void> _syncToNative(ThemeMode mode) async {
    try {
      await _platform.invokeMethod('setTheme', mode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final value = mode == ThemeMode.light ? 'light' : 'dark';
    await prefs.setString(_key, value);
    state = mode;
    await _syncToNative(mode);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  () => ThemeModeNotifier(),
);

/// Convenience: true when light mode is active
final isLightModeProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider) == ThemeMode.light;
});
