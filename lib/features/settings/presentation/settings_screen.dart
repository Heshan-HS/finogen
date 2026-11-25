import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/presentation/welcome_screen.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/selection_sheet.dart';
import 'widgets/passcode_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/sms_sync_service.dart';
import '../../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final securityState = ref.watch(securityProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          _header(),
          const SizedBox(height: 24),
          _profileCard(context, user),
          const SizedBox(height: 24),
          _bankSmsSyncCard(context),
          const SizedBox(height: 24),
          _settingsSection('Appearance', [
            _SettingItem(
              icon: LucideIcons.sun,
              title: 'Theme Mode',
              value: ref.watch(themeModeProvider) == ThemeMode.dark ? 'Dark' : 'Light',
              onTap: () {
                ref.read(themeModeProvider.notifier).toggle();
              },
            ),
          ]),
          const SizedBox(height: 24),
          _settingsSection('Preferences', [
            _SettingItem(
              icon: LucideIcons.bell,
              title: 'Notifications',
              value: settingsAsync.value?.notificationsEnabled == true ? 'Enabled' : 'Disabled',
              onTap: () {
                if (settingsAsync.value != null) {
                  final newSettings = settingsAsync.value!.copyWith(
                    notificationsEnabled: !settingsAsync.value!.notificationsEnabled,
                  );
                  ref.read(settingsRepositoryProvider).updateSettings(newSettings);
                }
              },
            ),
            _SettingItem(
              icon: LucideIcons.globe,
              title: 'Language',
              value: settingsAsync.value?.language ?? 'English',
              onTap: () => _showLanguagePicker(context, ref, settingsAsync.value?.language ?? 'English'),
            ),
          ]),
          const SizedBox(height: 24),
          _settingsSection('Currency Configuration', [
            _SettingItem(
              icon: LucideIcons.wallet,
              title: 'Base Currency (Transactions)',
              value: settingsAsync.value?.baseCurrency ?? 'LKR (Rs)',
              onTap: () => _showBaseCurrencyPicker(context, ref, settingsAsync.value?.baseCurrency ?? 'LKR (Rs)'),
            ),
            _SettingItem(
              icon: LucideIcons.coins,
              title: 'Display Currency',
              value: settingsAsync.value?.currency ?? 'USD (\$)',
              onTap: () => _showCurrencyPicker(context, ref, settingsAsync.value?.currency ?? 'USD (\$)'),
            ),
            _SettingItem(
              icon: LucideIcons.activity,
              title: 'Live Exchange Rates',
              value: settingsAsync.value?.useLiveExchangeRate == true ? 'On' : 'Off',
              onTap: () {
                if (settingsAsync.value != null) {
                  final newSettings = settingsAsync.value!.copyWith(
                    useLiveExchangeRate: !settingsAsync.value!.useLiveExchangeRate,
                  );
                  ref.read(settingsRepositoryProvider).updateSettings(newSettings);
                }
              },
            ),
            if (settingsAsync.value?.useLiveExchangeRate != true)
              _SettingItem(
                icon: LucideIcons.edit3,
                title: 'Manual Exchange Rate',
                value: '1 \u0024 = ${settingsAsync.value?.manualExchangeRate ?? 300.0} Rs',
                onTap: () => _showManualRateInput(context, ref, settingsAsync.value?.manualExchangeRate ?? 300.0),
              ),
          ]),
          const SizedBox(height: 24),
          _settingsSection('Security', [
            _SettingItem(
              icon: LucideIcons.fingerprint,
              title: 'Biometric Login',
              value: securityState.biometricEnabled ? 'On' : 'Off',
              onTap: () async {
                final auth = LocalAuthentication();
                final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                if (canCheck) {
                  if (!securityState.biometricEnabled) {
                    final authenticated = await auth.authenticate(
                      localizedReason: 'Please authenticate to enable biometric login',
                    );
                    if (authenticated) {
                      ref.read(securityProvider.notifier).setBiometric(true);
                    }
                  } else {
                    ref.read(securityProvider.notifier).setBiometric(false);
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics not supported on this device')));
                  }
                }
              },
            ),
            _SettingItem(
              icon: LucideIcons.lock,
              title: 'Change Passcode',
              value: securityState.passcode != null ? 'Set' : 'Not Set',
              onTap: () => PasscodeSheet.show(context),
            ),
          ]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
              isDark: AppColors.isDark(context),
              padding: const EdgeInsets.all(16),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isGuest', false);
                await prefs.setBool('isLoggedIn', false);
                if (!(!kIsWeb && Platform.isWindows)) await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.logOut, color: Color(0xFFFF5252), size: 20),
                  SizedBox(width: 8),
                  Text('Log Out',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF5252))),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _header() { return Padding(
      padding: EdgeInsets.fromLTRB(20, 52, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account', style: TextStyle(fontSize: 13, color: AppColors.muted(context))),
          Text('Settings',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                  height: 1.1,
                  letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _profileCard(BuildContext context, User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
              isDark: AppColors.isDark(context),
        centerGlow: true,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent(context), width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.accentGlow(context), blurRadius: 20, spreadRadius: -5),
                ],
                image: DecorationImage(
                  image: NetworkImage(user?.photoURL ?? 'https://i.pravatar.cc/150?img=11'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? 'User Name',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(user?.email ?? 'user@example.com',
                      style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final result = await EditProfileSheet.show(context);
                if (result == true) {
                  setState(() {});
                }
              },
              child: AppCard(
              isDark: AppColors.isDark(context),
                padding: EdgeInsets.all(10),
                borderRadius: 12,
                child: Icon(LucideIcons.edit2, size: 16, color: AppColors.text(context)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _settingsSection(String title, List<_SettingItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context))),
          const SizedBox(height: 12),
          AppCard(
            isDark: AppColors.isDark(context),
            padding: EdgeInsets.zero,
            child: Column(
              children: items.map((item) {
                final isLast = items.last == item;
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.elevated(context).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderColor(context)),
                        ),
                        child: Icon(item.icon, size: 18, color: AppColors.accent(context)),
                      ),
                      title: Text(item.title, style: TextStyle(fontSize: 14, color: AppColors.text(context))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.value.isNotEmpty)
                            Text(item.value, style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                          const SizedBox(width: 8),
                          Icon(LucideIcons.chevronRight, size: 16, color: AppColors.muted(context)),
                        ],
                      ),
                      onTap: item.onTap,
                    ),
                    if (!isLast) Divider(color: AppColors.borderColor(context), height: 1),
                  ],
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  void _showBaseCurrencyPicker(BuildContext context, WidgetRef ref, String currentVal) async {
    final selected = await SelectionSheet.show(
      context,
      title: 'Select Base Currency',
      options: const ['USD (\$)', 'LKR (Rs)', 'EUR (€)', 'GBP (£)', 'INR (₹)', 'JPY (¥)', 'AUD (\$)'],
      currentValue: currentVal,
    );
    if (selected != null) {
      final state = ref.read(settingsProvider).value;
      if (state != null) {
        ref.read(settingsRepositoryProvider).updateSettings(state.copyWith(baseCurrency: selected));
      }
    }
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String currentVal) async {
    final selected = await SelectionSheet.show(
      context,
      title: 'Select Display Currency',
      options: const ['USD (\$)', 'LKR (Rs)', 'EUR (€)', 'GBP (£)', 'INR (₹)', 'JPY (¥)', 'AUD (\$)'],
      currentValue: currentVal,
    );
    if (selected != null) {
      final state = ref.read(settingsProvider).value;
      if (state != null) {
        ref.read(settingsRepositoryProvider).updateSettings(state.copyWith(currency: selected));
      }
    }
  }

  void _showManualRateInput(BuildContext context, WidgetRef ref, double currentVal) {
    final TextEditingController controller = TextEditingController(text: currentVal.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg(context),
          title: Text('Manual Exchange Rate', style: TextStyle(color: AppColors.text(context), fontSize: 16)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.text(context)),
            decoration: InputDecoration(
              hintText: 'e.g. 300.0',
              hintStyle: TextStyle(color: AppColors.muted(context).withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderColor(context))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent(context))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
            ),
            TextButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null && val > 0) {
                  final state = ref.read(settingsProvider).value;
                  if (state != null) {
                    ref.read(settingsRepositoryProvider).updateSettings(state.copyWith(manualExchangeRate: val));
                  }
                  Navigator.pop(context);
                }
              },
              child: Text('Save', style: TextStyle(color: AppColors.accent(context))),
            ),
          ],
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentVal) async {
    final selected = await SelectionSheet.show(
      context,
      title: 'Select Language',
      options: ['English', 'Sinhala', 'Tamil', 'Spanish'],
      currentValue: currentVal,
    );
    if (selected != null) {
      final state = ref.read(settingsProvider).value;
      if (state != null) {
        ref.read(settingsRepositoryProvider).updateSettings(state.copyWith(language: selected));
      }
    }
  }

  Widget _bankSmsSyncCard(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) return const SizedBox.shrink();

    final smsState = ref.watch(smsSyncServiceProvider);
    final smsNotifier = ref.read(smsSyncServiceProvider.notifier);
    final isDark = AppColors.isDark(context);
    final accentGreen = AppColors.accent(context);
    final accentBg = AppColors.accentTint(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank & Wallet Integration',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            isDark: isDark,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentGreen.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.landmark,
                        color: accentGreen,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Automated SMS Sync',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: smsState.hasPermission
                                      ? accentGreen.withOpacity(0.15)
                                      : Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  smsState.hasPermission ? 'ACTIVE' : 'ACTION REQ',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: smsState.hasPermission ? accentGreen : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            smsState.hasPermission
                                ? (smsState.lastSyncTime != null
                                    ? 'Last sync: ${smsState.lastSyncTime!.hour.toString().padLeft(2, '0')}:${smsState.lastSyncTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Auto-ingests NTB & eZ Cash SMS')
                                : 'Tap to grant SMS permissions',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: smsState.isSyncing
                          ? null
                          : () async {
                              if (!smsState.hasPermission) {
                                final granted = await smsNotifier.requestPermission();
                                if (!granted && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('SMS permission is required to automatically parse bank alerts.'),
                                    ),
                                  );
                                }
                              } else {
                                final count = await smsNotifier.syncPastSms(days: 60);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF1E232A),
                                      content: Text(
                                        count > 0
                                            ? '🎉 Successfully imported $count transaction(s)!'
                                            : 'All bank transactions are already up to date.',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.elevated(context) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.refreshCw,
                              size: 12,
                              color: accentGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              smsState.isSyncing ? 'Scanning' : 'Sync',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.elevated(context) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0x17F0FDF5) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        smsState.deviceWallet == 'dialog' ? LucideIcons.smartphone : LucideIcons.phone,
                        size: 15,
                        color: accentGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Device Wallet: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted(context),
                                  ),
                                ),
                                Text(
                                  smsState.deviceWallet == 'dialog' ? 'Ez Cash (Dialog)' : 'Ez Cash (Airtel)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              smsState.deviceWalletSetting == 'auto'
                                  ? 'Auto-detected (${smsState.deviceModel.isNotEmpty ? smsState.deviceModel : "This Device"})'
                                  : 'Manual selection active',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showDeviceWalletDialog(context, smsState, smsNotifier),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accentGreen.withOpacity(0.25)),
                          ),
                          child: Text(
                            'Switch',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeviceWalletDialog(BuildContext context, SmsSyncState state, SmsSyncNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'eZ Cash Device Wallet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which eZ Cash account receives incoming SMS on ${state.deviceModel.isNotEmpty ? state.deviceModel : "this phone"}.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                ),
                const SizedBox(height: 16),
                _walletOptionTile(
                  ctx: ctx,
                  title: '⚡ Auto-Detect (Recommended)',
                  subtitle: 'Routes Huawei ➔ Dialog and Infinix ➔ Airtel',
                  isSelected: state.deviceWalletSetting == 'auto',
                  onTap: () {
                    notifier.setDeviceWalletSetting('auto');
                    Navigator.pop(ctx);
                  },
                ),
                _walletOptionTile(
                  ctx: ctx,
                  title: 'Ez Cash (Dialog)',
                  subtitle: 'Direct Dialog SIM (0779040196) on this device',
                  isSelected: state.deviceWalletSetting == 'dialog',
                  onTap: () {
                    notifier.setDeviceWalletSetting('dialog');
                    Navigator.pop(ctx);
                  },
                ),
                _walletOptionTile(
                  ctx: ctx,
                  title: 'Ez Cash (Airtel)',
                  subtitle: 'Secondary SIM (0769169810) on this device',
                  isSelected: state.deviceWalletSetting == 'airtel',
                  onTap: () {
                    notifier.setDeviceWalletSetting('airtel');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _walletOptionTile({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final accentGreen = AppColors.accent(ctx);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? accentGreen : AppColors.text(ctx),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: AppColors.muted(ctx)),
      ),
      trailing: isSelected
          ? Icon(LucideIcons.check, color: accentGreen, size: 18)
          : null,
      onTap: onTap,
    );
  }

}

class _SettingItem {
  const _SettingItem({required this.icon, required this.title, required this.value, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
}