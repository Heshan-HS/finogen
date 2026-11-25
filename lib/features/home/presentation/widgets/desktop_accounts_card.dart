import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/account_providers.dart';
import '../../../../core/providers/transaction_providers.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/models/account_model.dart';
import 'package:intl/intl.dart';

class DesktopAccountsCard extends ConsumerWidget {
  const DesktopAccountsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final currency = ref.watch(currencySymbolProvider);
    final rate = ref.watch(currencyRateProvider);
    final formatter = NumberFormat('#,##0.00');

    return SizedBox(
      width: double.infinity,
      height: 185,
      child: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) return _buildEmptyCard();
          return _PeekStackCards(
            accounts: accounts,
            currency: currency,
            rate: rate,
            formatter: formatter,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
        error: (_, __) => const Center(
          child: Text('Error loading accounts', style: TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1715),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(
        child: Text('No accounts available', style: TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}

class _PeekStackCards extends ConsumerStatefulWidget {
  final List<AccountModel> accounts;
  final String currency;
  final double rate;
  final NumberFormat formatter;

  const _PeekStackCards({
    required this.accounts,
    required this.currency,
    required this.rate,
    required this.formatter,
  });

  @override
  ConsumerState<_PeekStackCards> createState() => _PeekStackCardsState();
}

class _PeekStackCardsState extends ConsumerState<_PeekStackCards>
    with TickerProviderStateMixin {
  int _frontIndex = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Default 1.0 value ensures front card is 100% visible on page load
    _slideController = AnimationController(
      value: 1.0,
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _bringToFront(int newFrontIndex) {
    if (newFrontIndex == _frontIndex) return;
    setState(() {
      _frontIndex = newFrontIndex;
    });
    _slideController.forward(from: 0);
  }

  int get _backIndex => (_frontIndex + 1) % widget.accounts.length;

  @override
  Widget build(BuildContext context) {
    final front = widget.accounts[_frontIndex];
    final hasBack = widget.accounts.length > 1;
    final back = hasBack ? widget.accounts[_backIndex] : null;

    final frontColor = Color(front.colorValue);
    final backColor = back != null ? Color(back.colorValue) : const Color(0xFF0F382C);

    return LayoutBuilder(builder: (ctx, constraints) {
      final cardWidth = constraints.maxWidth;
      final cardHeight = constraints.maxHeight;
      const peekAmount = 36.0;
      final frontCardWidth = hasBack ? cardWidth - peekAmount : cardWidth;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // --- BACK CARD (SLIGHTLY REVEALED PEEK ON RIGHT) ---
          if (hasBack && back != null)
            Positioned(
              top: 6,
              right: 0,
              width: cardWidth,
              height: cardHeight - 6,
              child: GestureDetector(
                onTap: () => _bringToFront(_backIndex),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _getLuxuryGradient(backColor, isBack: true),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 18,
                          offset: const Offset(8, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.2,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: peekAmount,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.creditCard,
                              color: const Color(0xFF10B981).withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(height: 8),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                back.type.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // --- FRONT LUXURY CREDIT CARD ---
          Positioned(
            top: 0,
            left: 0,
            width: frontCardWidth,
            height: cardHeight,
            child: GestureDetector(
              onTap: hasBack ? () => _bringToFront(_backIndex) : null,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildLuxuryRealCard(
                  account: front,
                  baseColor: frontColor,
                  currency: widget.currency,
                  rate: widget.rate,
                  formatter: widget.formatter,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  List<Color> _getLuxuryGradient(Color color, {bool isBack = false}) {
    // Elegant dark obsidian emerald palette matching the dark dashboard
    final darkBase = Color.lerp(color, const Color(0xFF04120E), 0.5) ?? const Color(0xFF0B241D);
    final obsidian = const Color(0xFF05120E);
    final accentEmerald = const Color(0xFF0D3B2E);

    if (isBack) {
      return [
        darkBase.withOpacity(0.95),
        accentEmerald.withOpacity(0.8),
        obsidian,
      ];
    }

    return [
      Color.lerp(color, const Color(0xFF0F4D3A), 0.4) ?? const Color(0xFF0F4D3A),
      darkBase,
      obsidian,
    ];
  }

  Widget _buildLuxuryRealCard({
    required AccountModel account,
    required Color baseColor,
    required String currency,
    required double rate,
    required NumberFormat formatter,
  }) {
    final derivedBalance = ref.watch(accountDerivedBalanceProvider(account.id));
    final balance = '$currency  ${formatter.format(derivedBalance * rate)}';
    final cardNum = '••••  ••••  ••••  ${(account.name.hashCode % 9000 + 1000).abs()}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.55, 1.0],
          colors: _getLuxuryGradient(baseColor),
        ),
        boxShadow: [
          // Primary glow shadow matching dark green theme
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.25),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 12),
          ),
          // Deep drop shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 1. Diagonal Glass Reflection Sheen
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.3, 0.6, 1.0],
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
                      Colors.transparent,
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Ambient Metallic Glow Spot Top Right
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Card Content Layout
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: EMV Chip + Contactless Icon + Card Brand Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildEmvChip(),
                          const SizedBox(width: 12),
                          _buildContactlessIcon(),
                        ],
                      ),
                      // Overlapping circles logo (Mastercard style luxury badge)
                      _buildCardLogo(account.type.name),
                    ],
                  ),

                  // Middle Row: Balance Label & Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVAILABLE BALANCE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 9.5,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFE2F1EC)],
                        ).createShader(bounds),
                        child: Text(
                          balance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Row: Card Number & Cardholder Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        cardNum,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 2),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text(
                            account.name.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
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
    );
  }

  // Realistic Gold Metallic EMV Chip
  Widget _buildEmvChip() {
    return Container(
      width: 36,
      height: 27,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFEEAA),
            Color(0xFFD4AF37),
            Color(0xFFA67C1E),
            Color(0xFFF7D070),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFF8A6414), width: 0.6),
      ),
      child: Stack(
        children: [
          // Inner Chip Circuit Lines
          Center(
            child: Container(
              width: 26,
              height: 19,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6B4E10), width: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 14,
              height: 19,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: const Color(0xFF6B4E10), width: 0.8),
                  right: BorderSide(color: const Color(0xFF6B4E10), width: 0.8),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 26,
              height: 0.8,
              color: const Color(0xFF6B4E10),
            ),
          ),
        ],
      ),
    );
  }

  // Contactless Payment Arcs Icon
  Widget _buildContactlessIcon() {
    return Icon(
      LucideIcons.wifi,
      color: Colors.white.withOpacity(0.7),
      size: 16,
    );
  }

  // Luxury Card Brand Overlapping Circles Logo
  Widget _buildCardLogo(String typeName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withOpacity(0.85),
                    ),
                  ),
                  Positioned(
                    left: 7,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF34D399).withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Text(
                typeName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
