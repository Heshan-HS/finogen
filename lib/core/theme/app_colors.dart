import 'package:flutter/material.dart';

/// All design tokens - Dark and Light mode variants.
class AppColors {
  AppColors._();

  // ── Dark Mode Backgrounds ──────────────────────────
  static const Color background    = Color(0xFF020706);   // main scaffold
  static const Color card          = Color(0xFF061210);   // card base
  static const Color cardElevated  = Color(0xFF0A1512);   // icon boxes etc.

  // ── Dark Mode Card gradient stops ─────────────────
  static const Color cardGradStart = Color(0xFF0C1815);
  static const Color cardGradEnd   = Color(0xFF030807);

  // ── Primary / accent (mint green) ─────────────────
  static const Color primary       = Color(0xFF00D9A8);
  static const Color primaryFg     = Color(0xFF0D2018);   // text on primary button
  static const Color primaryGlow   = Color(0x6600D9A8);   // 40% for shadow-glow

  // ── Progress gradient ─────────────────────────────
  static const Color gradA = Color(0xFFC8F73A);
  static const Color gradB = Color(0xFF86F278);
  static const Color gradC = Color(0xFF4EDBA4);

  // ── Dark Mode Text ────────────────────────────────
  static const Color textPrimary = Color(0xFFF2FAF6);
  static const Color textMuted   = Color(0xFFA5B4AD);

  // ── Dark Mode Border ──────────────────────────────
  static const Color border = Color(0x17F0FDF5);

  // ── Glow radial ───────────────────────────────────
  static const Color glowStart = Color(0x2E00D9A8);

  // ──────────────────────────────────────────────────
  // ── LIGHT MODE (Deep Luxury Dark Green + Slate) ───
  // ──────────────────────────────────────────────────

  // ── Light Mode Backgrounds ────────────────────────
  static const Color backgroundLight    = Color(0xFFF8FAFC);   // crisp Slate-50 off-white
  static const Color cardLight          = Color(0xFFFFFFFF);   // pure crisp white card
  static const Color cardElevatedLight  = Color(0xFFF1F5F9);   // Slate-100 tile boxes

  // ── Light Mode Card gradient stops ────────────────
  static const Color cardGradStartLight = Color(0xFFFFFFFF);
  static const Color cardGradEndLight   = Color(0xFFFFFFFF);

  // ── Light Mode Primary (Deep Luxury Emerald Green) ─
  static const Color primaryLight       = Color(0xFF005A36); // Ultra-deep, rich dark emerald   // Deep, prestigious dark green
  static const Color primaryLightTint   = Color(0xFFE8F5ED);   // Soft emerald background badge
  static const Color primaryFgLight     = Color(0xFFFFFFFF);   // Pure white on green button
  static const Color primaryGlowLight   = Color(0x20006B49);   // Clean subtle green glow

  // ── Light Mode Text ───────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0F172A);   // Slate-900 (sharp & high-contrast)
  static const Color textMutedLight   = Color(0xFF64748B);   // Slate-500 (clean, readable secondary)

  // ── Light Mode Border ─────────────────────────────
  static const Color borderLight = Color(0x40005A36);        // Emerald green border matching +Income card (0xFF005A36 with 0.25 opacity)

  // ── Light Mode Glow ───────────────────────────────
  static const Color glowStartLight = Color(0x0C006B49);      // Extremely subtle ambient

  // ── Light Mode Card shadow ────────────────────────
  static const Color cardShadowLight = Color(0x0A0F172A);    // Multi-layered clean shadow

  // ──────────────────────────────────────────────────
  // ── CONTEXTUAL GETTERS (resolve based on brightness) ──
  // ──────────────────────────────────────────────────

  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? background : backgroundLight;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? card : cardLight;

  static Color elevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardElevated : cardElevatedLight;

  static Color gradStart(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardGradStart : cardGradStartLight;

  static Color gradEnd(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardGradEnd : cardGradEndLight;

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primary : primaryLight;

  static Color accentTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? primary.withOpacity(0.12)
          : primaryLightTint;

  static Color accentFg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryFg : primaryFgLight;

  static Color accentGlow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryGlow : primaryGlowLight;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimary : textPrimaryLight;

  static Color muted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMuted : textMutedLight;

  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? border : borderLight;

  static Color glow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? glowStart : glowStartLight;

  static Color positive(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primary : primaryLight;

  static Color negative(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFF5252) : const Color(0xFFDC2626);

  static Color positiveTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? primary.withOpacity(0.12)
          : primaryLightTint;

  static Color negativeTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFF5252).withOpacity(0.12)
          : const Color(0xFFFEE2E2);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
