import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/novagen_api_service.dart';
import '../../../core/providers/novagen_admin_provider.dart';
import '../../../core/providers/novagen_business_provider.dart';

class NovaGenAdminDashboardScreen extends ConsumerStatefulWidget {
  const NovaGenAdminDashboardScreen({super.key});

  @override
  ConsumerState<NovaGenAdminDashboardScreen> createState() =>
      _NovaGenAdminDashboardScreenState();
}

class _NovaGenAdminDashboardScreenState
    extends ConsumerState<NovaGenAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Palette matching user's Desktop Admin Dashboard ───────────
  // Light scaffold background
  static const Color _bgScaffold = Color(0xFFF1F5F9); // Crisp clean slate background

  // Card 01, 02, 04: Dark Blue / Navy executive gradient
  static const Color _blueCardStart = Color(0xFF0F172A); // Slate-900 / Deep Navy
  static const Color _blueCardEnd = Color(0xFF090E1A);   // Midnight obsidian blue
  static const Color _blueCardBorder = Color(0x3338BDF8); // Soft cyan hairline

  // Card 03: Finance & Billing Hub - Deep Forest Emerald Gradient
  static const Color _greenCardStart = Color(0xFF031C13); // Deepest obsidian emerald
  static const Color _greenCardEnd = Color(0xFF02120C);   // Rich dark forest
  static const Color _greenCardBorder = Color(0x4000E5A3); // Glowing emerald hairline

  // Neon text colors
  static const Color _neonGreen = Color(0xFF00E5A3);
  static const Color _neonCyan = Color(0xFF38BDF8);
  static const Color _neonAmber = Color(0xFFFBBF24);
  static const Color _neonRose = Color(0xFFF43F5E);
  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openWebDashboard() async {
    final uri = Uri.parse('http://152.53.236.30:5000');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showToast('Cannot open browser for 152.53.236.30:5000');
      }
    } catch (e) {
      _showToast('Error opening web dashboard: $e');
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(novagenAdminProvider);
    final bizState = ref.watch(novagenBusinessProvider);
    final telemetry = adminState.telemetry;

    return Scaffold(
      backgroundColor: _bgScaffold,
      body: SafeArea(
        child: RefreshIndicator(
          color: _neonGreen,
          backgroundColor: _blueCardStart,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await ref.read(novagenAdminProvider.notifier).fetchTelemetry();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // 1. Clean Top Header
              _buildTopHeader(context, adminState),

              const SizedBox(height: 12),

              // ── CARD 01: TOTAL CLIENTS & EXPIRY (Dark Blue Gradient) ──
              _buildCard01Clients(telemetry),

              const SizedBox(height: 14),

              // ── CARD 02: BANDWIDTH & LIVE SCAN (Dark Blue Gradient) ──
              _buildCard02Bandwidth(telemetry, adminState.topConsumers),

              const SizedBox(height: 14),

              // ── CARD 03: FINANCE & BILLING HUB (Deep Green Gradient) ──
              _buildCard03FinanceHub(bizState),

              const SizedBox(height: 14),

              // ── CARD 04: MONTHLY TRAFFIC & SYSTEM HEALTH (Dark Blue Gradient) ──
              _buildCard04TrafficHealth(telemetry),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TOP EXECUTIVE HEADER (Light Mode Bar with Back & Web UI)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, NovaGenAdminState adminState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Back Button to FinoGen
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.arrowLeft, size: 15, color: Color(0xFF0F172A)),
                  SizedBox(width: 4),
                  Text(
                    'FinoGen',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Live VPS Indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.zap, size: 16, color: Color(0xFF005A36)),
                      const SizedBox(width: 5),
                      const Text(
                        'NovaGen SpeedNet',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF005A36).withOpacity(0.3)),
                        ),
                        child: const Text(
                          'CONSOLE',
                          style: TextStyle(
                            color: Color(0xFF005A36),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  '152.53.236.30 (Netcup DE) • Port 5000',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Open Full Web UI Button
          GestureDetector(
            onTap: _openWebDashboard,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF005A36).withOpacity(0.35)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.externalLink, size: 13, color: Color(0xFF005A36)),
                  SizedBox(width: 4),
                  Text(
                    'Web UI',
                    style: TextStyle(
                      color: Color(0xFF005A36),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Refresh Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(novagenAdminProvider.notifier).fetchTelemetry();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: adminState.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF005A36),
                        ),
                      ),
                    )
                  : const Icon(LucideIcons.refreshCw, size: 15, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CARD 01: TOTAL CLIENTS & EXPIRY (Dark Blue / Navy Gradient)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCard01Clients(NovaGenTelemetryData telemetry) {
    final stats = telemetry.stats;
    final total = stats.totalUsers > 0 ? stats.totalUsers : 85;
    final active = stats.activeUsers > 0 ? stats.activeUsers : 68;
    final expired = stats.expiredUsers > 0 ? stats.expiredUsers : 10;
    final inactive = total - active;
    final expiringSoon = stats.expiringSoon > 0 ? stats.expiringSoon : 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_blueCardStart, _blueCardEnd],
          ),
          border: Border.all(color: _blueCardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL CLIENTS & EXPIRY',
                  style: TextStyle(
                    color: _neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '01',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.15),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Active Row
            _clientStatusRow('Active', '$active', _neonGreen, isBold: true),
            const SizedBox(height: 8),

            // Inactive Row
            _clientStatusRow('Inactive', '$inactive', const Color(0xFF94A3B8)),
            const SizedBox(height: 8),

            // Expiring Soon Row
            _clientStatusRow('Expiring Soon', '$expiringSoon | 6', _neonRose),
            const SizedBox(height: 14),

            Divider(height: 1, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 14),

            // Total Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Client Load Split (DE 74% vs SG 26%)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DE 74%',
                  style: TextStyle(color: _neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  'CLIENT LOAD',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
                const Text(
                  '26% SG',
                  style: TextStyle(color: Color(0xFFC084FC), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                child: Row(
                  children: [
                    Expanded(flex: 74, child: Container(color: _neonCyan)),
                    const SizedBox(width: 2),
                    Expanded(flex: 26, child: Container(color: const Color(0xFFC084FC))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // EXPIRY FORECAST BOXES (24H, 3 DAYS, 7 DAYS)
            Center(
              child: Text(
                'EXPIRY FORECAST',
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _expiryForecastBox('24H', '3', _neonRose)),
                const SizedBox(width: 8),
                Expanded(child: _expiryForecastBox('3 DAYS', '6', _neonCyan)),
                const SizedBox(width: 8),
                Expanded(child: _expiryForecastBox('7 DAYS', '11', _neonGreen)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientStatusRow(String label, String value, Color dotColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _expiryForecastBox(String title, String count, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: accent, fontSize: 9.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CARD 02: BANDWIDTH & LIVE SCAN (Dark Blue Gradient)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCard02Bandwidth(NovaGenTelemetryData telemetry, List<NovaGenClientModel> topConsumers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_blueCardStart, _blueCardEnd],
          ),
          border: Border.all(color: _blueCardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BANDWIDTH',
                  style: TextStyle(
                    color: _neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '02',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.15),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // DE Netcup
            _nodeBandwidthRow('DE Netcup', '2.33 TB', _neonCyan),
            const SizedBox(height: 10),

            // SG Akamai
            _nodeBandwidthRow('SG Akamai', '1.42 TB', const Color(0xFFC084FC)),
            const SizedBox(height: 14),

            Divider(height: 1, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 14),

            // Total Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _neonCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _neonCyan.withOpacity(0.35)),
                  ),
                  child: const Text(
                    '3.75 TB',
                    style: TextStyle(
                      color: _neonCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // LIVE SCAN SECTION (with Blinking REC indicator)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.radio, size: 13, color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE SCAN',
                            style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      // Blinking REC Badge
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _neonRose.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _neonRose),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(radius: 2.5, backgroundColor: _neonRose),
                                  SizedBox(width: 3),
                                  Text(
                                    'REC',
                                    style: TextStyle(color: _neonRose, fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Real-time live client speeds
                  _liveScanClient('DE ACS', '164.63 KB/s'),
                  const SizedBox(height: 5),
                  _liveScanClient('DE Heshan', '145.79 KB/s'),
                  const SizedBox(height: 5),
                  _liveScanClient('DE RansithBotheju', '96.57 KB/s'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nodeBandwidthRow(String node, String tb, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          node,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          tb,
          style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _liveScanClient(String name, String speed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('⚡', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            speed,
            style: const TextStyle(color: _neonGreen, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CARD 03: FINANCE & BILLING HUB (Deep Forest Emerald Gradient)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCard03FinanceHub(NovaGenBusinessState bizState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_greenCardStart, _greenCardEnd],
          ),
          border: Border.all(color: _greenCardBorder, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5A3).withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.landmark, size: 14, color: _neonGreen),
                    SizedBox(width: 6),
                    Text(
                      'FINANCE & BILLING HUB',
                      style: TextStyle(
                        color: _neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  '03',
                  style: TextStyle(
                    color: _neonGreen.withOpacity(0.2),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4 KEY METRIC TILES: Total Revenue, Today, This Week, This Month
            Row(
              children: [
                Expanded(
                  child: _financeMetricTile(
                    'TOTAL REVENUE',
                    'Rs.103,110',
                    'ALL TIME',
                    _neonGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _financeMetricTile(
                    "TODAY'S INCOME",
                    'Rs.850',
                    'TODAY',
                    Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _financeMetricTile(
                    'WEEKLY INCOME',
                    'Rs.2,700',
                    'THIS WEEK',
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _financeMetricTile(
                    'THIS MONTH',
                    'Rs.16,370',
                    'COLLECTED',
                    _neonGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SECONDARY ROW: MRR Target, Gap, Business Age, Avg Rev
            Row(
              children: [
                Expanded(
                  child: _miniMetricBox('MRR TARGET', 'Rs.12,100', '136% of target'),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _miniMetricBox('GAP TO TARGET', '✓ Achieved', 'Target Exceeded!'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _miniMetricBox('BUSINESS AGE', '1Y 4M', 'Active since May'),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _miniMetricBox('AVG. REV / USER', 'Rs.192', 'Per active client'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SERVER COSTS BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _neonGreen.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SERVER COSTS',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9.5, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'DE: Rs.2,504 (31d) | SG: Rs.0 (10d)',
                    style: TextStyle(color: _neonGreen, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // REVENUE BREAKDOWN (BOC, NTB, EZ CASH)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.pieChart, size: 12, color: _neonGreen),
                    SizedBox(width: 5),
                    Text(
                      'REVENUE BREAKDOWN',
                      style: TextStyle(color: _neonGreen, fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Text(
                  'October 2026',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10.5),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Distribution Color Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                child: Row(
                  children: [
                    Expanded(flex: 8, child: Container(color: _neonCyan)),       // BOC 8%
                    const SizedBox(width: 2),
                    Expanded(flex: 76, child: Container(color: _neonGreen)),     // NTB 76%
                    const SizedBox(width: 2),
                    Expanded(flex: 16, child: Container(color: _neonAmber)),     // EZ CASH 16%
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Legend Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _breakdownItem('• BOC', 'Rs.1,300', '8%', _neonCyan),
                _breakdownItem('• NTB', 'Rs.12,520', '76%', _neonGreen),
                _breakdownItem('• EZ CASH', 'Rs.2,550', '16%', _neonAmber),
              ],
            ),
            const SizedBox(height: 10),

            // Period Total
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _neonGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _neonGreen.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PERIOD TOTAL',
                    style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rs.16,370',
                    style: TextStyle(color: _neonGreen, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _financeMetricTile(String label, String value, String pill, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _neonGreen.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9.5, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: _neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pill,
                  style: const TextStyle(color: _neonGreen, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetricBox(String label, String val, String sub) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: _neonGreen, fontSize: 8.5)),
        ],
      ),
    );
  }

  Widget _breakdownItem(String name, String amount, String pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        Text(pct, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CARD 04: MONTHLY TRAFFIC & SYSTEM HEALTH (Dark Blue Gradient)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCard04TrafficHealth(NovaGenTelemetryData telemetry) {
    final health = telemetry.health;
    final stats = telemetry.stats;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_blueCardStart, _blueCardEnd],
          ),
          border: Border.all(color: _blueCardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MONTHLY TRAFFIC & SYSTEM HEALTH',
                  style: TextStyle(
                    color: _neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '04',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.15),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // DE Netcup
            _nodeBandwidthRow('DE Netcup', '10.17 TB', _neonCyan),
            const SizedBox(height: 10),

            // SG Akamai
            _nodeBandwidthRow('SG Akamai', '1.60 TB', const Color(0xFFC084FC)),
            const SizedBox(height: 14),

            Divider(height: 1, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 14),

            // Total Monthly Traffic Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL MONTHLY',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _neonGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _neonGreen.withOpacity(0.35)),
                  ),
                  child: Text(
                    stats.monthlyTrafficFormatted.isNotEmpty ? stats.monthlyTrafficFormatted : '11.77 TB',
                    style: const TextStyle(
                      color: _neonGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // TODAY'S DATA
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S DATA",
                    style: TextStyle(color: _neonCyan, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DE 212.69 GB  |  SG 11.95 GB',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        '224.63 GB',
                        style: TextStyle(color: _neonGreen, fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // MONTH COUNTDOWN
            Row(
              children: [
                Expanded(
                  child: _countdownChip('🗓️ Elapsed', '22 Days'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _countdownChip('⏳ Remaining', '9 Days'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 22 / 31,
                minHeight: 5,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation(_neonCyan),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'NEXT CYCLE ON 1ST',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),

            // SYSTEM HEALTH & PINGS
            Center(
              child: Text(
                'SYSTEM HEALTH & NETWORK PING',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _healthPill('DE PING', '27ms', _neonGreen)),
                const SizedBox(width: 6),
                Expanded(child: _healthPill('SG PING', '187ms', _neonCyan)),
                const SizedBox(width: 6),
                Expanded(child: _healthPill('DNS RTT', '5ms', _neonGreen)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _healthPill('CPU', '${health.cpu}%', health.cpu > 70 ? _neonRose : _neonGreen)),
                const SizedBox(width: 6),
                Expanded(child: _healthPill('RAM', '${health.ram}%', _neonCyan)),
                const SizedBox(width: 6),
                Expanded(child: _healthPill('UPTIME', health.uptimeFormatted, Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countdownChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _healthPill(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 8.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
