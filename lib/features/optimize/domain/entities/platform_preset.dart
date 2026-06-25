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

  const PlatformPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.specs,
    required this.icon,
    required this.color,
  });

  static const List<PlatformPreset> all = [
    PlatformPreset(
      id: PlatformId.whatsappStatus,
      name: 'WhatsApp Status',
      subtitle: 'Best for status updates',
      specs: '1920x1080  H.264  CRF 24',
      icon: Icons.chat_rounded,
      color: Color(0xFF25D366),
    ),
    PlatformPreset(
      id: PlatformId.instagramStory,
      name: 'Instagram Story',
      subtitle: 'Full-screen vertical format',
      specs: '1080x1920  H.264  CRF 23',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE1306C),
    ),
    PlatformPreset(
      id: PlatformId.instagramPost,
      name: 'Instagram Post',
      subtitle: 'Square or portrait feed',
      specs: '1080x1080  JPEG 85',
      icon: Icons.grid_on_rounded,
      color: Color(0xFFF77737),
    ),
    PlatformPreset(
      id: PlatformId.telegram,
      name: 'Telegram',
      subtitle: 'Original quality lossless',
      specs: 'Original  Lossless',
      icon: Icons.send_rounded,
      color: Color(0xFF2AABEE),
    ),
    PlatformPreset(
      id: PlatformId.custom,
      name: 'Custom',
      subtitle: 'Set your own parameters',
      specs: 'Configurable',
      icon: Icons.tune_rounded,
      color: Color(0xFF7B61FF),
    ),
  ];
}
