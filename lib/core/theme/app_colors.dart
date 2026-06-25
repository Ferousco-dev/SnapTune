import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary — Indigo ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF5B5BD6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEEF2FF);
  static const Color onPrimaryContainer = Color(0xFF1A1A6E);

  // ── Violet (accent / secondary) ─────────────────────────────────────────────
  static const Color violet = Color(0xFF7B61FF);

  // ── Coral (tertiary / accent) ────────────────────────────────────────────────
  static const Color coral = Color(0xFFFF8A65);
  static const Color onCoral = Color(0xFFFFFFFF);

  // ── Success ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFECFDF5);
  static const Color onSuccessContainer = Color(0xFF16A34A);

  // ── Error ────────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);

  // ── Neutral — Light ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F8);
  static const Color surfaceSelected = Color(0xFFEEF2FF);
  static const Color onBackground = Color(0xFF121212);
  static const Color onSurface = Color(0xFF121212);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  static const Color outline = Color(0x12000000); // rgba(0,0,0,0.07)
  static const Color outlineVariant = Color(0xFFD1D5DB);
  static const Color muted = Color(0xFFB0B4C0);

  // ── Neutral — Dark ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0E0E1A);
  static const Color darkSurface = Color(0xFF17172A);
  static const Color darkSurfaceVariant = Color(0xFF1F1F35);
  static const Color darkSurfaceSelected = Color(0xFF26264A);
  static const Color darkOnBackground = Color(0xFFF1F1F8);
  static const Color darkOnSurface = Color(0xFFF1F1F8);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkOutline = Color(0xFF2A2A45);
  static const Color darkMuted = Color(0xFF6B7280);

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B5BD6), Color(0xFF7B61FF)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment(0.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [primary, violet],
  );

  static const LinearGradient viewerTopGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xA6000000), Colors.transparent],
  );

  static const LinearGradient viewerBottomGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xC7000000), Colors.transparent],
  );
}
