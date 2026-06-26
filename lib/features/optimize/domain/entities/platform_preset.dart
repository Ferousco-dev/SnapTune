import 'package:flutter/material.dart';

enum PlatformId {
  whatsappStatus,
  instagramStory,
  instagramPost,
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
    PlatformPreset(
      id: PlatformId.whatsappStatus,
      name: 'WhatsApp Status',
      subtitle: 'Best for status updates',
      specs: '1920x1080  JPEG 88',
      icon: Icons.chat_rounded,
      color: Color(0xFF25D366),
      maxWidth: 1920,
      maxHeight: 1080,
      jpegQuality: 88,
    ),
    PlatformPreset(
      id: PlatformId.instagramStory,
      name: 'Instagram Story',
      subtitle: 'Full-screen vertical format',
      specs: '1080x1920  JPEG 85',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE1306C),
      maxWidth: 1080,
      maxHeight: 1920,
      jpegQuality: 85,
    ),
    PlatformPreset(
      id: PlatformId.instagramPost,
      name: 'Instagram Post',
      subtitle: 'Square or portrait feed',
      specs: '1080x1080  JPEG 85',
      icon: Icons.grid_on_rounded,
      color: Color(0xFFF77737),
      maxWidth: 1080,
      maxHeight: 1080,
      jpegQuality: 85,
    ),
    PlatformPreset(
      id: PlatformId.telegram,
      name: 'Telegram',
      subtitle: 'Original quality lossless',
      specs: 'Original  Lossless',
      icon: Icons.send_rounded,
      color: Color(0xFF2AABEE),
      maxWidth: 0,
      maxHeight: 0,
      jpegQuality: 100,
    ),
    PlatformPreset(
      id: PlatformId.custom,
      name: 'Custom',
      subtitle: 'Set your own parameters',
      specs: '1280x1280  JPEG 80',
      icon: Icons.tune_rounded,
      color: Color(0xFF7B61FF),
      maxWidth: 1280,
      maxHeight: 1280,
      jpegQuality: 80,
    ),
  ];
}
