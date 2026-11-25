import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/account_providers.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../core/models/account_model.dart';
import '../../../core/repositories/account_repository.dart';
import 'add_account_screen.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String get currency => ref.watch(currencySymbolProvider);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAccountScreen()));
        },
        backgroundColor: AppColors.accent(context),
        child: Icon(LucideIcons.plus, color: AppColors.accentFg(context)),
      ),
      body: Stack(
        children: [
          // Ambient glow
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [
                      AppColors.accent(context).withOpacity(AppColors.isDark(context) ? 0.25 : 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final accountsAsync = ref.watch(accountsStreamProvider);
                      return accountsAsync.when(
                        data: (accounts) {
                          if (accounts.isEmpty) {
                            return Center(child: Text('No accounts yet', style: TextStyle(color: AppColors.muted(context))));
                          }
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            child: SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 24,
                                children: accounts.map((account) {
                                  return ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 420),
                                    child: AccountCardItem(account: account),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Center(child: Text('Error loading accounts')),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AppCard(
              padding: const EdgeInsets.all(10),
              isDark: true,
              borderRadius: 12,
              child: Icon(LucideIcons.arrowLeft, color: AppColors.text(context), size: 20),
            ),
          ),
          Text('Linked Accounts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text(context))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class AccountCardItem extends ConsumerWidget {
  final AccountModel account;
  const AccountCardItem({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    final derivedBalance = ref.watch(accountDerivedBalanceProvider(account.id)) * rate;
    final isDark = AppColors.isDark(context);
    final accent = AppColors.accent(context);
    
    final typeName = account.type == AccountType.creditCard
        ? 'Credit Card'
        : (account.type == AccountType.bank ? 'Bank Account' : 'Cash Wallet');

    final pseudoNumber = '**** **** **** ${account.id.length >= 4 ? account.id.substring(0, 4).toUpperCase() : account.id.toUpperCase()}';

    final user = FirebaseAuth.instance.currentUser;
    final cardHolderName = (user?.displayName?.isNotEmpty == true 
        ? user!.displayName! 
        : (user?.email?.split('@')[0] ?? 'CARDHOLDER')).toUpperCase();

    // Deep luxury theme styling: Crisp white with deep emerald & slate in Light Mode, obsidian with neon emerald in Dark Mode
    final cardBg = isDark ? const Color(0xFF0F1715) : Colors.white;
    final cardBorder = isDark ? AppColors.border : AppColors.borderLight;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white.withOpacity(0.55) : const Color(0xFF64748B);
    final numberColor = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B);
    final balanceColor = isDark ? Colors.white : accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddAccountScreen(accountToEdit: account)));
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: account.isEnabled ? 1.0 : 0.5,
          child: AspectRatio(
            aspectRatio: 1.586, // Standard credit card aspect ratio
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder, width: 1.2),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x0A0F172A),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Color(0x040F172A),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Ambient glow - Top Right (Ultra-fast GPU radial glow)
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withOpacity(isDark ? 0.18 : 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Ambient glow - Bottom Left (Ultra-fast GPU radial glow)
                    Positioned(
                      bottom: -50,
                      left: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withOpacity(isDark ? 0.12 : 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // FinoGen Watermark
                    Positioned(
                      bottom: 16,
                      right: 12,
                      child: Text(
                        'FinoGen',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white.withOpacity(0.03) : accent.withOpacity(0.04),
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    // Content - Balanced with zero overflow!
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top row: Name + Wifi & Switch
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      typeName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.wifi,
                                    color: isDark ? Colors.white.withOpacity(0.7) : accent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: account.isEnabled,
                                      onChanged: (val) {
                                        ref.read(accountRepositoryProvider).updateAccount(account.copyWith(isEnabled: val));
                                      },
                                      activeColor: accent,
                                      activeTrackColor: accent.withOpacity(0.3),
                                      inactiveThumbColor: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF94A3B8),
                                      inactiveTrackColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        
                          // Middle row (Number only)
                          Text(
                            pseudoNumber,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: numberColor,
                              letterSpacing: 3.5,
                              fontFamily: 'Courier',
                            ),
                          ),

                          // Bottom row: Balance & Cardholder Name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BALANCE',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: textSecondary,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${derivedBalance < 0 ? '-' : ''}$currency ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white.withOpacity(0.7) : textSecondary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: derivedBalance.abs().toStringAsFixed(2),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: balanceColor,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                cardHolderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
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
}
