import 'package:flutter/material.dart';

enum PlatformId {
  whatsapp,
  instagramStory,
  instagramPost,
  tiktok,
  twitter,
  facebook,
  telegram,
  custom,
}

class PlatformPreset {
  final PlatformId id;
  final String name;
  final String subtitle;
  final String specs;
  final IconData icon;
  final Color color;

  // Processing parameters used by the optimization engine
  final int maxWidth;
  final int maxHeight;
  final int jpegQuality;

  const PlatformPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.specs,
    required this.icon,
    required this.color,
    required this.maxWidth,
    required this.maxHeight,
    required this.jpegQuality,
  });

  static const List<PlatformPreset> all = [
    // WhatsApp: standard compress to ~1600px longest edge, quality 88
    PlatformPreset(
      id: PlatformId.whatsapp,
      name: 'WhatsApp',
      subtitle: 'Chat & status sharing',
      specs: '1600 × 1600  ·  JPEG 88',
      icon: Icons.chat_rounded,
      color: Color(0xFF25D366),
      maxWidth: 1600,
      maxHeight: 1600,
      jpegQuality: 88,
    ),
    // Instagram Story / Status: 9:16 vertical, 1080×1920
    PlatformPreset(
      id: PlatformId.instagramStory,
      name: 'Instagram Story',
      subtitle: 'Full-screen 9:16 vertical',
      specs: '1080 × 1920  ·  JPEG 85',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE1306C),
      maxWidth: 1080,
      maxHeight: 1920,
      jpegQuality: 85,
    ),
    // Instagram Post: 4:5 portrait (1080×1350) — 23% more engagement than 1:1
    PlatformPreset(
      id: PlatformId.instagramPost,
      name: 'Instagram Post',
      subtitle: '4:5 portrait for max reach',
      specs: '1080 × 1350  ·  JPEG 85',
      icon: Icons.grid_on_rounded,
      color: Color(0xFFF77737),
      maxWidth: 1080,
      maxHeight: 1350,
      jpegQuality: 85,
    ),
    // TikTok / Reels: 9:16 vertical, 1080×1920
    PlatformPreset(
      id: PlatformId.tiktok,
      name: 'TikTok / Reels',
      subtitle: 'Short-form vertical content',
      specs: '1080 × 1920  ·  JPEG 90',
      icon: Icons.music_note_rounded,
      color: Color(0xFFEE1D52),
      maxWidth: 1080,
      maxHeight: 1920,
      jpegQuality: 90,
    ),
    // X (Twitter): feed timeline images, quality 90 to survive Twitter's compression
    PlatformPreset(
      id: PlatformId.twitter,
      name: 'X / Twitter',
      subtitle: 'Pre-compressed for timeline',
      specs: '1200 × 675  ·  JPEG 90',
      icon: Icons.alternate_email_rounded,
      color: Color(0xFF1DA1F2),
      maxWidth: 1200,
      maxHeight: 675,
      jpegQuality: 90,
    ),
    // Facebook feed: 1200×630 landscape
    PlatformPreset(
      id: PlatformId.facebook,
      name: 'Facebook',
      subtitle: 'Feed & profile sharing',
      specs: '1200 × 630  ·  JPEG 85',
      icon: Icons.thumb_up_rounded,
      color: Color(0xFF1877F2),
      maxWidth: 1200,
      maxHeight: 630,
      jpegQuality: 85,
    ),
    // Telegram: photo mode compresses to 1280px at ~87% — pre-condition at q95
    PlatformPreset(
      id: PlatformId.telegram,
      name: 'Telegram',
      subtitle: 'Pre-conditioned for photo mode',
      specs: '1280 × 1280  ·  JPEG 95',
      icon: Icons.send_rounded,
      color: Color(0xFF2AABEE),
      maxWidth: 1280,
      maxHeight: 1280,
      jpegQuality: 95,
    ),
    // Custom: general-purpose
    PlatformPreset(
      id: PlatformId.custom,
      name: 'Custom',
      subtitle: 'General-purpose compression',
      specs: '1280 × 1280  ·  JPEG 80',
      icon: Icons.tune_rounded,
      color: Color(0xFF7B61FF),
      maxWidth: 1280,
      maxHeight: 1280,
      jpegQuality: 80,
    ),
  ];
}
