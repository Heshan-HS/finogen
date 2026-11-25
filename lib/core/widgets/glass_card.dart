import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// surface-card equivalent - now theme-aware for both dark and light modes.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.withGlow = false,
    this.centerGlow = false,
    this.isDark = false,
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool withGlow;
  final bool centerGlow;
  final bool isDark;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius);
    final isLightMode = !AppColors.isDark(context);

    Widget innerChild = Padding(
      padding: padding,
      child: child,
    );

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: br,
        color: isLightMode
            ? AppColors.cardLight // In Light Mode: Always crisp pure white
            : (isDark ? AppColors.background : null),
        gradient: isLightMode
            ? null  // Light mode: clean flat pure white
            : (isDark
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.cardGradStart, AppColors.cardGradEnd],
                    stops: [0.0, 0.7],
                  )),
        border: Border.all(
          color: isLightMode ? AppColors.borderLight : AppColors.border,
          width: isLightMode ? 1.2 : 1,
        ),
        boxShadow: isLightMode
            ? const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x040F172A),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ]
            : (isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0xB3000000),
                      blurRadius: 40,
                      offset: Offset(0, 18),
                    ),
                  ]),
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            if (withGlow && !isLightMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.7, -1.0),
                        radius: 1.4,
                        colors: [AppColors.glowStart, Colors.transparent],
                        stops: [0.0, 0.65],
                      ),
                    ),
                  ),
                ),
              ),
            if (withGlow && isLightMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.7, -1.0),
                        radius: 1.4,
                        colors: [AppColors.primaryLight.withOpacity(0.04), Colors.transparent],
                        stops: const [0.0, 0.65],
                      ),
                    ),
                  ),
                ),
              ),
            if (centerGlow && !isLightMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 90,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            innerChild,
            // Top accent line (only in dark mode for neon effect)
            if (!isLightMode)
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, AppColors.primary.withOpacity(0.5), Colors.transparent],
                    ),
                  ),
                ),
              ),
            if (!isLightMode)
              Positioned(
                bottom: 0,
                left: 40,
                right: 40,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, AppColors.primary.withOpacity(0.4), Colors.transparent],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
    }
    return card;
  }
}

/// Horizontal rule divider
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.isDark(context) ? AppColors.border : AppColors.borderLight,
    );
  }
}
