import '../../../core/providers/analytics_providers.dart';
import '../../../core/models/account_model.dart';
import 'widgets/gf_holding_modal.dart';
import 'widgets/novagen_business_modal.dart';
import '../../novagen/presentation/novagen_admin_dashboard_screen.dart';
import '../../../core/providers/novagen_business_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/presentation/welcome_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/providers/navigation_providers.dart';
import '../../../core/widgets/gradient_progress_bar.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../transfer/presentation/transfer_screen.dart';
import '../../bills/presentation/bills_screen.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../goals/presentation/goals_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/edit_budget_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/presentation/widgets/add_transaction_modal.dart';
import '../../../core/models/transaction_category.dart';
import 'package:intl/intl.dart';
import '../../../core/services/sms_sync_service.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../core/providers/budget_providers.dart';
import '../../../core/providers/account_providers.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/navigation_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  String get currency => ref.watch(currencySymbolProvider);

  late AnimationController _balanceController;
  late Animation<double> _balanceAnimation;
  double _lastBalance = 0;
  int _cashFlowPeriodIndex = 0; // 0 = Today, 1 = This Week, 2 = This Month, 3 = Total

  @override
  void initState() {
    super.initState();
    _balanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _balanceAnimation = Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(
      parent: _balanceController,
      curve: Curves.easeOutCubic,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smsSyncServiceProvider.notifier).init();
      ref.read(smsSyncServiceProvider.notifier).reconcileAccounts();
    });
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    final rate = ref.watch(currencyRateProvider);

    ref.listen(mainNavIndexProvider, (prev, next) {
      if (next == 0) {
        _balanceController.forward(from: 0);
      }
    });

    final targetBalance = balanceState.totalBalance * rate;
    if (_lastBalance != targetBalance) {
      _lastBalance = targetBalance;
      _balanceAnimation = Tween<double>(begin: 0, end: _lastBalance).animate(CurvedAnimation(
        parent: _balanceController,
        curve: Curves.easeOutCubic,
      ));
      _balanceController.forward(from: 0);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110), // space for floating nav
        children: [
          // App Header (AppHeader.tsx)
          _header(),
          const SizedBox(height: 12),
          // Cash In / Cash Out premium cards
          _cashFlowCards(balanceState, rate),
          const SizedBox(height: 14),
          // Total Balance Gradient Card (under Cash In / Cash Out)
          _balanceCard(balanceState, rate),
          const SizedBox(height: 16),
          // Quick Access Grid
          _quickAccessCard(context),
          const SizedBox(height: 14),
          // Action Buttons: Income & Expense (under Quick Access)
          _actionButtons(),
          const SizedBox(height: 12),
          _novagenBusinessMobileCard(context),
          const SizedBox(height: 12),
          _gfHoldingMobileCard(context),
          const SizedBox(height: 20),
          _budgetStatusCard(rate),
          const SizedBox(height: 16),
          _recentTransactions(rate),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ HEADER (AppHeader.tsx)
  Widget _bankSmsSyncCard(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) return const SizedBox.shrink();

    final smsState = ref.watch(smsSyncServiceProvider);
    final smsNotifier = ref.read(smsSyncServiceProvider.notifier);
    final isDark = AppColors.isDark(context);
    final accentGreen = AppColors.accent(context);
    final accentBg = AppColors.accentTint(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        isDark: false,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentGreen.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                LucideIcons.landmark,
                color: accentGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Nations & eZ Cash',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AUTO SYNC',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accentGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    smsState.isSyncing
                        ? 'Scanning SMS inbox...'
                        : (smsState.lastStatusMessage ?? 'Auto-detecting income & expense SMS'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: smsState.isSyncing ? accentGreen : AppColors.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: smsState.isSyncing
                  ? null
                  : () async {
                      final count = await smsNotifier.syncPastSms(days: 60);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.cardBg(context),
                            content: Text(
                              count > 0
                                  ? '🎉 Successfully imported $count transaction(s)!'
                                  : 'All Nations & eZ Cash transactions are up to date.',
                              style: TextStyle(color: AppColors.text(context)),
                            ),
                          ),
                        );
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevated(context) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderColor(context)),
                ),
                child: smsState.isSyncing
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(accentGreen),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.refreshCw, size: 13, color: accentGreen),
                          const SizedBox(width: 5),
                          Text(
                            'Sync',
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
      ),
    );
  }

  Widget _header() {
    final userName = (!kIsWeb && Platform.isWindows)
        ? 'Guest'
        : (FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'Guest');
    return Padding(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top > 0 ? (MediaQuery.of(context).padding.top + 8) : 18, 20, 0),
      child: Row(
        children: [
          // Logo: 2Ã—2 grid of squares (exact from AppHeader.tsx)
          _logo(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hi, $userName',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                      height: 1.1,
                      letterSpacing: -0.5)),
              Text('Welcome to FinoGen',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted(context),
                      fontWeight: FontWeight.w400)),
            ],
          ),
          const Spacer(),
          _buildSpeedNetBusinessSwitchBtn(context),
          const SizedBox(width: 8),
          _buildNotificationBellBtn(context),
        ],
      ),
    );
  }

  Widget _buildSpeedNetBusinessSwitchBtn(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accentGreen = AppColors.accent(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const NovaGenAdminDashboardScreen(),
          ),
        );
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1A17) : const Color(0xFFE8F7F0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentGreen.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentGreen.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accentGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentGreen.withOpacity(0.8),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Icon(LucideIcons.zap, size: 14, color: accentGreen),
            const SizedBox(width: 4),
            Text(
              'SpeedNet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: const DecorationImage(
          image: AssetImage('assets/images/mainlogo.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSettingsMenuBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSettingsBottomSheet(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.elevated(context).withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderColor(context)),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(LucideIcons.slidersHorizontal, color: AppColors.text(context).withOpacity(0.8), size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBellBtn(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    
    return GestureDetector(
      onTap: () => _showNotificationDropdown(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.elevated(context).withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderColor(context)),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(LucideIcons.bell, color: AppColors.text(context).withOpacity(0.8), size: 20),
                if (unreadCount > 0)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.accent(context),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.accent(context).withOpacity(0.5), blurRadius: 4, spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bg(context).withOpacity(0.95), // Match app theme
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.accent(context), width: 1.5)),
          boxShadow: [BoxShadow(color: AppColors.accentGlow(context), blurRadius: 30, spreadRadius: -10)],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.text(context).withOpacity(0.24), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.accent(context).withOpacity(0.2), shape: BoxShape.circle),
                          child: Icon(LucideIcons.user, color: AppColors.accent(context)),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((!kIsWeb && Platform.isWindows) ? 'FinoGen User' : (FirebaseAuth.instance.currentUser?.displayName ?? 'FinoGen User'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                            Text(((!kIsWeb && Platform.isWindows) ? '' : FirebaseAuth.instance.currentUser?.email ?? ''), style: TextStyle(fontSize: 13, color: AppColors.elevated(context).withOpacity(0.5))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(mainNavIndexProvider.notifier).setIndex(3);
                      },
                      child: _buildMenuOption(LucideIcons.shield, 'Security & Privacy', 'FaceID, PIN, App Lock'),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(mainNavIndexProvider.notifier).setIndex(3);
                      },
                      child: _buildMenuOption(LucideIcons.palette, 'Appearance', 'Dark Mode, Pure Black'),
                    ),
                    GestureDetector(
                      onTap: () async {
                        // Quick way to test Notifications: generate dummy ones.
                        final repository = ref.read(notificationRepositoryProvider);
                        await repository.addNotification(NotificationModel(
                          id: '',
                          title: 'System Alert',
                          message: 'This is a real-time notification test!',
                          type: 'system',
                          isRead: false,
                          createdAt: DateTime.now(),
                        ));
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: _buildMenuOption(LucideIcons.cloud, 'Data & Backup', 'Tap to Generate Test Notification'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isGuest', false);
                          await prefs.setBool('isLoggedIn', false);
                          if (!(!kIsWeb && Platform.isWindows)) await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
                          }
                        },
                        child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.borderColor(context), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.text(context), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text(context))),
                Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.elevated(context).withOpacity(0.5))),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: AppColors.elevated(context).withOpacity(0.5), size: 20),
        ],
      ),
    );
  }

  void _showNotificationDropdown(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 80, right: 20),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.elevated(context).withOpacity(0.5)),
                    boxShadow: [BoxShadow(color: AppColors.accent(context).withOpacity(0.1), blurRadius: 30, spreadRadius: 5)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Consumer(
                          builder: (context, ref, _) {
                            final notificationsAsync = ref.watch(notificationsProvider);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                                    GestureDetector(
                                      onTap: () {
                                        ref.read(notificationRepositoryProvider).markAllAsRead();
                                      },
                                      child: Text('Mark all read', style: TextStyle(fontSize: 12, color: AppColors.accent(context), fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                notificationsAsync.when(
                                  data: (notifications) {
                                    if (notifications.isEmpty) {
                                      return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('No new notifications', style: TextStyle(color: AppColors.muted(context)))),
                                      );
                                    }
                                    return Column(
                                      children: notifications.take(5).map((n) {
                                        IconData icon;
                                        switch (n.type) {
                                          case 'alert': icon = LucideIcons.alertTriangle; break;
                                          case 'reminder': icon = LucideIcons.receipt; break;
                                          default: icon = LucideIcons.sparkles;
                                        }
                                        return _buildNotificationItem(n.title, n.message, icon, isNew: !n.isRead);
                                      }).toList(),
                                    );
                                  },
                                  loading: () => Center(child: CircularProgressIndicator(color: AppColors.accent(context))),
                                  error: (_, __) => const Text('Error loading notifications', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, IconData icon, {bool isNew = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isNew ? AppColors.primary.withOpacity(0.2) : AppColors.borderColor(context), shape: BoxShape.circle),
            child: Icon(icon, color: isNew ? AppColors.primary : Colors.white70, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: isNew ? FontWeight.bold : FontWeight.w600, color: AppColors.text(context))),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.elevated(context).withOpacity(0.5))),
              ],
            ),
          ),
          if (isNew) Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: AppColors.accent(context), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ BALANCE (BalanceCard.tsx) - NO card
  // ────────────────────────────────────────── BALANCE CARD (Forest Gradient)
  Widget _balanceCard(BalanceState state, double rate) {
    final formatter = NumberFormat('#,##0.00');
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final dateRange = '$monthName 01 - $lastDay, ${now.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00643F), // Rich deep forest emerald (darkened left)
              Color(0xFF004F32), // Deep forest green
              Color(0xFF003823), // Very deep forest green
              Color(0xFF001E13), // Dark forest obsidian green
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF004F32).withOpacity(0.38),
              blurRadius: 26,
              offset: const Offset(0, 12),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: const Color(0xFF00291B).withOpacity(0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Subtle soft circle at top-right corner
              Positioned(
                top: -35,
                right: -35,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // Subtle soft circle at bottom-left corner
              Positioned(
                bottom: -45,
                left: -25,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Card content
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Label + Date chip pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total Balance',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.92),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        // Date chip: semi-transparent white pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.24),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.calendarDays,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateRange,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Balance Amount
                    AnimatedBuilder(
                      animation: _balanceAnimation,
                      builder: (context, child) {
                        final formattedAmount =
                            formatter.format(_balanceAnimation.value);
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$currency $formattedAmount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -0.8,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────── ACTION BUTTONS (Income / Expense)
  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _modeBtn('Income', LucideIcons.plusCircle, true, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(isExpense: false),
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _modeBtn('Expense', LucideIcons.minusCircle, false, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(isExpense: true),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, IconData icon, bool isIncome, VoidCallback onTap) {
    final isDark = AppColors.isDark(context);
    final accentColor = isIncome ? AppColors.accent(context) : const Color(0xFFEF4444);
    final accentBg = isIncome
        ? AppColors.accentTint(context)
        : (isDark ? const Color(0xFFEF4444).withOpacity(0.12) : const Color(0xFFFEF2F2));
    final borderColor = isDark
        ? (isIncome ? AppColors.primary.withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.25))
        : (isIncome ? AppColors.primaryLight.withOpacity(0.25) : const Color(0xFFEF4444).withOpacity(0.25));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: isIncome ? AppColors.primary.withOpacity(0.08) : Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: isIncome ? AppColors.primaryLight.withOpacity(0.08) : const Color(0x0AEF4444),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                  const BoxShadow(
                    color: Color(0x040F172A),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: accentBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────── CASH IN / CASH OUT CARDS
  Widget _cashFlowCards(BalanceState state, double rate) {
    final formatter = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);
    final inColor = isDark ? AppColors.primary : AppColors.primaryLight;
    final inBg = isDark ? AppColors.primary.withOpacity(0.12) : AppColors.primaryLightTint;
    const outColor = Color(0xFFEF4444);
    final outBg = isDark ? outColor.withOpacity(0.12) : const Color(0xFFFEF2F2);
    final velocity = ref.watch(financialVelocityProvider);

    double displayedIncome = 0;
    double displayedExpense = 0;
    String inTitle = "Today's In";
    String outTitle = "Today's Out";
    String? netSubtitle;
    String? outSubtitle;

    switch (_cashFlowPeriodIndex) {
      case 0: // Today
        displayedIncome = velocity.today.income;
        displayedExpense = velocity.today.expense;
        inTitle = "Today's In";
        outTitle = "Today's Out";
        final net = velocity.today.income - velocity.today.expense;
        final netSign = net >= 0 ? '+' : '';
        netSubtitle = 'Net: $netSign$currency ${formatter.format(net * rate)}';
        outSubtitle = displayedExpense > 0 ? 'Daily Outflow' : 'Zero Outflow';
        break;
      case 1: // This Week
        displayedIncome = velocity.thisWeek.income;
        displayedExpense = velocity.thisWeek.expense;
        inTitle = "Week's In";
        outTitle = "Week's Out";
        final net = velocity.thisWeek.income - velocity.thisWeek.expense;
        final netSign = net >= 0 ? '+' : '';
        netSubtitle = 'Net: $netSign$currency ${formatter.format(net * rate)}';
        outSubtitle = displayedExpense > 0 ? 'Weekly Outflow' : 'Zero Outflow';
        break;
      case 2: // This Month
        displayedIncome = velocity.thisMonth.income;
        displayedExpense = velocity.thisMonth.expense;
        inTitle = "Month's In";
        outTitle = "Month's Out";
        final net = velocity.thisMonth.income - velocity.thisMonth.expense;
        final netSign = net >= 0 ? '+' : '';
        netSubtitle = 'Net: $netSign$currency ${formatter.format(net * rate)}';
        outSubtitle = displayedExpense > 0 ? 'Monthly Outflow' : 'Zero Outflow';
        break;
      case 3: // All Time
      default:
        displayedIncome = state.totalIncome;
        displayedExpense = state.totalExpense;
        inTitle = 'Total In';
        outTitle = 'Total Out';
        final net = state.totalIncome - state.totalExpense;
        final netSign = net >= 0 ? '+' : '';
        netSubtitle = 'Net: $netSign$currency ${formatter.format(net * rate)}';
        outSubtitle = 'All-time Outflow';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Elegant period selector row
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _periodTab('Today', 0, isDark),
                _periodTab('This Week', 1, isDark),
                _periodTab('This Month', 2, isDark),
                _periodTab('Total', 3, isDark),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _cashFlowCard(
                    inTitle,
                    '$currency ${formatter.format(displayedIncome * rate)}',
                    LucideIcons.arrowDownLeft,
                    inColor,
                    inBg,
                    subtitle: netSubtitle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _cashFlowCard(
                    outTitle,
                    '$currency ${formatter.format(displayedExpense * rate)}',
                    LucideIcons.arrowUpRight,
                    outColor,
                    outBg,
                    subtitle: outSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodTab(String label, int index, bool isDark) {
    final isSelected = _cashFlowPeriodIndex == index;
    final emeraldPrimary = isDark ? const Color(0xFF00D9A8) : const Color(0xFF005A36);
    final activeBg = isDark ? emeraldPrimary.withOpacity(0.22) : Colors.white;
    final activeFg = isDark ? emeraldPrimary : const Color(0xFF005A36);
    final inactiveFg = isDark ? const Color(0xFFA5B4AD) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _cashFlowPeriodIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected && !isDark
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeFg : inactiveFg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cashFlowCard(String title, String amount, IconData icon, Color color, Color bg, {String? subtitle}) {
    return AppCard(
      isDark: false,
      centerGlow: false,
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.muted(context))),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text(context),
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAccessCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        isDark: false,
        centerGlow: false,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.98,
              children: [
                _qaItem('Income', LucideIcons.banknote, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen(isExpense: false)))),
                _qaItem('Expense', LucideIcons.plusCircle, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen(isExpense: true)))),
                _qaItem('Transfer', LucideIcons.arrowLeftRight, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen()))),
                _qaItem('Bills', LucideIcons.receipt, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsScreen()))),
                _qaItem('Accounts', LucideIcons.wallet, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen()))),
                _qaItem('Reports', LucideIcons.pieChart, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
                _qaItem('Budget', LucideIcons.piggyBank, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen()))),
                _qaItem('Goal', LucideIcons.target, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qaItem(String label, IconData icon, VoidCallback onTap) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated(context).withOpacity(0.7) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLight,
            width: 1.1,
          ),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x040F172A),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5.5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary.withOpacity(0.08) : AppColors.primaryLightTint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.primary : AppColors.primaryLight,
                size: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.text(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ BUDGET STATUS (BudgetStatusCard.tsx)
  Widget _budgetStatusCard(double rate) {
    final spent = ref.watch(currentMonthExpenseProvider) * rate;
    final budget = ref.watch(currentMonthBudgetProvider).value;
    final total = (budget?.overallLimit ?? ref.watch(settingsProvider).value?.monthlyBudget ?? 50000.0) * rate;
    final pct = (total > 0) ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final remaining = (total - spent).clamp(0.0, total);
    
    final formatter = NumberFormat('#,##0');
    final formattedSpent = formatter.format(spent);
    final formattedTotal = formatter.format(total);
    final formattedRemaining = formatter.format(remaining);
    
    // Calculate daily left
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;
    final dailyLeft = remaining / daysRemaining;
    final formattedDaily = NumberFormat('#,##0.00').format(dailyLeft);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        isDark: false,
        centerGlow: true,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header with divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Budget Status', style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(context))),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => EditBudgetSheet.show(context),
                        child: Icon(LucideIcons.edit3, size: 14, color: AppColors.accent(context)),
                      ),
                    ],
                  ),
                  Row(children: [
                    Text('This Month',
                        style: TextStyle(fontSize: 12, color: AppColors.muted(context).withOpacity(0.85))),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronDown, size: 14, color: AppColors.muted(context)),
                  ]),
                ],
              ),
            ),
            const AppDivider(),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Overall Budget', style: TextStyle(fontSize: 11, color: AppColors.muted(context))),
                        const SizedBox(height: 4),
                        RichText(text: TextSpan(
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(text: '$currency $formattedSpent ', style: TextStyle(color: AppColors.text(context))),
                            TextSpan(text: '/ $currency $formattedTotal', style: TextStyle(color: AppColors.muted(context))),
                          ],
                        )),
                      ]),
                      Text('${(pct * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(context),
                              letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppProgressBar(value: pct),
                  const SizedBox(height: 16),
                  const AppDivider(),
                  const SizedBox(height: 14),
                  // Remaining / Daily Left
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat('Remaining', '$currency $formattedRemaining', CrossAxisAlignment.start),
                      _stat('Daily Left', '$currency $formattedDaily', CrossAxisAlignment.end),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, CrossAxisAlignment align) {
    return Column(crossAxisAlignment: align, children: [
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.muted(context))),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context))),
    ]);
  }

  Widget _recentTransactions(double rate) {
    final recentTx = ref.watch(recentTransactionsProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text(context))),
              Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.accent(context).withOpacity(0.9))),
            ],
          ),
          const SizedBox(height: 12),
          if (recentTx.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No recent transactions', style: TextStyle(color: AppColors.muted(context))),
              ),
            )
          else
            ...recentTx.map((tx) => _buildTxItem(tx, rate)),
        ],
      ),
    );
  }

  Widget _buildTxItem(TransactionModel tx, double rate) {
    final isExpense = !tx.isIncome;
    final isDark = AppColors.isDark(context);
    final accentGreen = AppColors.accent(context);
    final expenseColor = isDark ? const Color(0xFFFF5252) : const Color(0xFFDC2626);
    final color = isExpense ? expenseColor : accentGreen;
    final iconBg = isExpense
        ? (isDark ? expenseColor.withOpacity(0.12) : const Color(0xFFFEE2E2))
        : (isDark ? accentGreen.withOpacity(0.12) : AppColors.primaryLightTint);
    final icon = isExpense ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft;
    
    final allCategories = [...CategoryProvider.getIncomeCategories(), ...CategoryProvider.getExpenseCategories()];
    final categoryName = allCategories.firstWhere((c) => c.id == tx.categoryId, orElse: () => allCategories.first).name;

    final account = ref.watch(accountByIdProvider(tx.accountId));
    final defaultDesc = account?.name ?? categoryName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => AddTransactionModal.show(context, isExpense: isExpense, transaction: tx),
        child: AppCard(
          isDark: false,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.note.isNotEmpty ? tx.note : defaultDesc,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${categoryName.isNotEmpty ? '$categoryName \u2022 ' : ''}${DateFormat('MMM dd, yyyy \u2022 hh:mm a').format(tx.date)}',
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isExpense ? '-' : '+'}$currency ${(tx.amount * rate).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _novagenBusinessMobileCard(BuildContext context) {
    final bizState = ref.watch(novagenBusinessProvider);
    final currency = ref.watch(currencySymbolProvider);
    final decimalFormat = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);

    // Deep prestigious forest emerald & slate/black palette (100% executive look)
    final emeraldPrimary = isDark ? AppColors.primary : AppColors.primaryLight;
    final emeraldTint = isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primaryLightTint;
    final textDark = AppColors.text(context);
    final textMuted = AppColors.muted(context);

    // Exact matching light-green ("lapata green") button style as GF BOC Holding card
    final accentBtnBg = isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primaryLightTint;
    final accentBtnFg = isDark ? AppColors.primary : AppColors.primaryLight;
    final secondaryBtnBg = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9);
    final secondaryBtnFg = isDark ? Colors.white70 : AppColors.text(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        isDark: false,
        centerGlow: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: emeraldTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: emeraldPrimary.withOpacity(0.25), width: 1),
                  ),
                  child: Icon(LucideIcons.globe, size: 18, color: emeraldPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NovaGen SpeedNet',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'VPN Business • Netcup VPS',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency ' + decimalFormat.format(bizState.netProfit),
                      style: TextStyle(
                        color: emeraldPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Net Profit',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10,
                      ),
                    ),
                    if (bizState.todayRevenue > 0)
                      Text(
                        'Today: +Rs ' + decimalFormat.format(bizState.todayRevenue),
                        style: TextStyle(
                          color: emeraldPrimary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Executive metrics bar in cohesive neutral tones
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: emeraldPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Spent: Rs ' + decimalFormat.format(bizState.totalExpenses),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          bizState.isServerPaidThisCycle ? LucideIcons.checkCircle2 : LucideIcons.server,
                          size: 11,
                          color: emeraldPrimary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            bizState.isServerPaidThisCycle
                                ? 'Paid • ${DateFormat('MMM dd').format(bizState.nextRenewalDate)} (${bizState.daysUntilRenewal}d)'
                                : 'Due: ${DateFormat('MMM dd').format(bizState.nextRenewalDate)} • ${bizState.daysUntilRenewal}d left',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => NovaGenBusinessModal.show(context, initialTab: 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: accentBtnBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentBtnFg.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.plusCircle, size: 14, color: accentBtnFg),
                          const SizedBox(width: 6),
                          Text(
                            'Quick Add',
                            style: TextStyle(
                              color: accentBtnFg,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      NovaGenBusinessModal.show(context, initialTab: 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: secondaryBtnBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderColor(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.server, size: 14, color: secondaryBtnFg),
                          const SizedBox(width: 6),
                          Text(
                            'VPS Console',
                            style: TextStyle(
                              color: secondaryBtnFg,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gfHoldingMobileCard(BuildContext context) {
    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final currency = ref.watch(currencySymbolProvider);
    final decimalFormat = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);

    AccountModel? gfAccount = accounts.cast<AccountModel?>().firstWhere(
      (a) => a != null && (a.name.toLowerCase().contains('boc') || (a.name.toLowerCase().contains('gf') && a.name.toLowerCase().contains('holding'))),
      orElse: () => null,
    );
    if (gfAccount == null) {
      gfAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && a.excludeFromTotal && a.name.toLowerCase().contains('holding'),
        orElse: () => null,
      );
    }
    if (gfAccount == null) {
      gfAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && a.excludeFromTotal,
        orElse: () => null,
      );
    }

    final double holdingBalance = gfAccount != null ? ref.watch(accountDerivedBalanceProvider(gfAccount.id)) : 0.0;

    // Unified luxury deep green & light green tint palette (replacing orange/amber)
    final greenIconBg = isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primaryLightTint;
    final greenIconColor = isDark ? AppColors.primary : AppColors.primaryLight;
    final accentBtnBg = isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primaryLightTint;
    final accentBtnFg = isDark ? AppColors.primary : AppColors.primaryLight;
    final secondaryBtnBg = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9);
    final secondaryBtnFg = isDark ? Colors.white70 : AppColors.text(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        isDark: false,
        centerGlow: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: greenIconBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: greenIconColor.withOpacity(0.25), width: 1),
                  ),
                  child: Icon(LucideIcons.landmark, size: 18, color: greenIconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GF BOC Holding',
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Custodial • Excluded from Main Total',
                        style: TextStyle(
                          color: AppColors.muted(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency ' + decimalFormat.format(holdingBalance),
                      style: TextStyle(
                        color: greenIconColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Held with GF',
                      style: TextStyle(
                        color: AppColors.muted(context),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => GfHoldingModal.show(context, initialTab: 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: accentBtnBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentBtnFg.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.plusCircle, size: 14, color: accentBtnFg),
                          const SizedBox(width: 6),
                          Text(
                            'Quick Add',
                            style: TextStyle(
                              color: accentBtnFg,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => GfHoldingModal.show(context, initialTab: 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: secondaryBtnBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderColor(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.barChart2, size: 14, color: secondaryBtnFg),
                          const SizedBox(width: 6),
                          Text(
                            'History & Stats',
                            style: TextStyle(
                              color: secondaryBtnFg,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
