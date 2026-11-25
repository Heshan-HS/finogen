import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

class DesktopSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final accent = AppColors.accent(context);
    final mutedColor = AppColors.muted(context);

    // Ultra-luxurious, visible dark emerald gradient
    final sidebarGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF041A13), // Deep Pine
              Color(0xFF020F0A), // Obsidian Spruce
              Color(0xFF010805), // Pure Midnight
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF064E3B), // Vibrant Glowing Imperial Emerald (Top Left specular light)
              Color(0xFF033325), // Rich Jade Forest
              Color(0xFF022118), // Deep Pine
              Color(0xFF01140E), // Obsidian Base (Bottom Right)
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          );

    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: sidebarGradient,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFF00D9A8).withValues(alpha: 0.28),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient Glowing Glass Orbs (Aurora Effect)
          Positioned(
            top: -30,
            left: -20,
            child: IgnorePointer(
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00D9A8).withValues(alpha: isDark ? 0.08 : 0.22),
                      const Color(0xFF059669).withValues(alpha: isDark ? 0.03 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: isDark ? 0.06 : 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Sidebar Content
          Column(
            children: [
              _buildLogo(isDark),
              const SizedBox(height: 6),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildSectionLabel('MAIN'),
                    _buildMenuItem(context, 0, LucideIcons.layoutDashboard, 'Overview', accent),
                    _buildMenuItem(context, 1, LucideIcons.fileText, 'Transactions', accent),
                    _buildMenuItem(context, 2, LucideIcons.arrowLeftRight, 'Transfer', accent),
                    _buildMenuItem(context, 3, LucideIcons.receipt, 'Bills', accent),
                    _buildMenuItem(context, 4, LucideIcons.wallet, 'Accounts', accent),
                    const SizedBox(height: 8),
                    _buildSectionLabel('ANALYTICS'),
                    _buildMenuItem(context, 5, LucideIcons.pieChart, 'Reports', accent),
                    _buildMenuItem(context, 6, LucideIcons.target, 'Budget', accent),
                    _buildMenuItem(context, 7, LucideIcons.flag, 'Goals', accent),
                    const SizedBox(height: 8),
                    _buildSectionLabel('TOOLS'),
                    _buildMenuItem(context, 8, LucideIcons.calendarClock, 'Workspace', accent),
                    _buildMenuItem(context, 9, LucideIcons.candlestickChart, 'Crypto Trades', accent),
                  ],
                ),
              ),
              _buildBottomMenu(context, ref, isDark, mutedColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF00D9A8).withValues(alpha: 0.65),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00D9A8),
                    Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D9A8).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/mainlogo.png',
                  width: 36,
                  height: 36,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(LucideIcons.barChart2, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finogen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Track · Manage · Grow',
                  style: TextStyle(
                    color: const Color(0xFF00D9A8).withValues(alpha: 0.85),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, int index, IconData icon, String title, Color accent) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF00D9A8).withValues(alpha: 0.30),
                      const Color(0xFF059669).withValues(alpha: 0.16),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFF00D9A8).withValues(alpha: 0.50),
                    width: 1.2,
                  )
                : Border.all(color: Colors.transparent, width: 1.2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D9A8).withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF00D9A8) : Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                  letterSpacing: isSelected ? -0.1 : 0,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D9A8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00D9A8),
                        blurRadius: 6,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomMenu(BuildContext context, WidgetRef ref, bool isDark, Color mutedColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 8),
        // Glass Theme Toggle Container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isDark ? LucideIcons.moon : LucideIcons.sun,
                color: const Color(0xFF00D9A8),
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                isDark ? 'Dark Mode' : 'Light Mode',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF021D15),
                    border: Border.all(
                      color: const Color(0xFF00D9A8).withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D9A8).withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        left: isDark ? 2 : 20,
                        top: 2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF34D399), Color(0xFF00D9A8)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D9A8).withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              _buildMenuItem(context, -1, LucideIcons.settings, 'Settings', Colors.white),
              _buildMenuItem(context, -2, LucideIcons.helpCircle, 'Help & Support', Colors.white),
              const SizedBox(height: 10),
              // Frosted Glass Premium upgrade card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF064E3B).withValues(alpha: 0.55),
                      const Color(0xFF02160F).withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D9A8).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D9A8).withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFfbbf24).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFfbbf24).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(LucideIcons.star, color: Color(0xFFfbbf24), size: 14),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Unlock More Features',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 14),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
