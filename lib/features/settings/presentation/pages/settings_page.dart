import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/grid_columns_notifier.dart';
import '../../../../core/services/theme_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../optimize/domain/entities/platform_preset.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _defaultPlatformId = 'whatsappStatus';
  String _qualityMode = 'Balanced';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _defaultPlatformId =
          prefs.getString('default_platform') ?? 'whatsappStatus';
      _qualityMode = prefs.getString('quality_mode') ?? 'Balanced';
    });
  }

  Future<void> _setDefaultPlatform(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_platform', id);
    if (mounted) setState(() => _defaultPlatformId = id);
  }

  Future<void> _setQualityMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quality_mode', mode);
    if (mounted) setState(() => _qualityMode = mode);
  }

  String get _defaultPlatformName => PlatformPreset.all
      .firstWhere(
        (p) => p.id.name == _defaultPlatformId,
        orElse: () => PlatformPreset.all.first,
      )
      .name;

  void _showPlatformSheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlatformSheet(
        isDark: isDark,
        currentId: _defaultPlatformId,
        onPick: (id) {
          _setDefaultPlatform(id);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showQualitySheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QualitySheet(
        isDark: isDark,
        current: _qualityMode,
        onPick: (mode) {
          _setQualityMode(mode);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAppearanceSheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AppearanceSheet(isDark: isDark),
    );
  }

  void _showGridSheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GridSheet(isDark: isDark),
    );
  }

  void _showPrivacySheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PrivacySheet(isDark: isDark),
    );
  }

  Future<void> _clearCache() async {
    HapticFeedback.lightImpact();
    try {
      await PhotoManager.clearFileCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to clear'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendFeedback() async {
    await Share.share(
      'Hi SnapTune team,\n\nI wanted to share some feedback:\n\n[Your message here]',
      subject: 'SnapTune Feedback',
    );
  }

  Future<void> _rateApp() async {
    await Share.share(
      'Check out SnapTune — a beautiful, on-device gallery and media optimizer!\nhttps://github.com/Ferousco-dev/SnapTune',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final currentMode = sl<ThemeNotifier>().mode;

    final appearanceSubtitle = switch (currentMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      _ => 'Follow system',
    };

    return ValueListenableBuilder<int>(
      valueListenable: sl<GridColumnsNotifier>(),
      builder: (context, cols, _) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          title: Text(
            'Settings',
            style: AppTypography.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            MediaQuery.of(context).padding.bottom + AppSpacing.lg,
          ),
          children: [
            _AppCard(isDark: isDark),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Preferences'),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.palette_outlined,
                  iconColor: AppColors.violet,
                  title: 'Appearance',
                  subtitle: appearanceSubtitle,
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.muted),
                  onTap: () => _showAppearanceSheet(context, isDark),
                ),
                _TileDivider(isDark: isDark),
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.grid_view_rounded,
                  iconColor: AppColors.primary,
                  title: 'Grid columns',
                  subtitle: '$cols columns',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.muted),
                  onTap: () => _showGridSheet(context, isDark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Optimization'),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.tune_rounded,
                  iconColor: AppColors.success,
                  title: 'Default platform',
                  subtitle: _defaultPlatformName,
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.muted),
                  onTap: () => _showPlatformSheet(context, isDark),
                ),
                _TileDivider(isDark: isDark),
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.high_quality_rounded,
                  iconColor: AppColors.coral,
                  title: 'Quality mode',
                  subtitle: _qualityMode,
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.muted),
                  onTap: () => _showQualitySheet(context, isDark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('Storage'),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.cleaning_services_outlined,
                  iconColor: AppColors.primary,
                  title: 'Clear cache',
                  subtitle: 'Remove temporary files',
                  onTap: _clearCache,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionLabel('About'),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.star_outline_rounded,
                  iconColor: AppColors.coral,
                  title: 'Rate SnapTune',
                  subtitle: 'Share the love',
                  onTap: _rateApp,
                ),
                _TileDivider(isDark: isDark),
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: AppColors.violet,
                  title: 'Send feedback',
                  subtitle: 'Tell us what you think',
                  onTap: _sendFeedback,
                ),
                _TileDivider(isDark: isDark),
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.primary,
                  title: 'Privacy policy',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.muted),
                  onTap: () => _showPrivacySheet(context, isDark),
                ),
                _TileDivider(isDark: isDark),
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.info_outline_rounded,
                  iconColor: isDark ? AppColors.darkMuted : AppColors.muted,
                  title: 'Version',
                  subtitle: '1.0.0',
                  onTap: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Platform picker sheet ─────────────────────────────────────────────────────

class _PlatformSheet extends StatelessWidget {
  final bool isDark;
  final String currentId;
  final void Function(String id) onPick;

  const _PlatformSheet({
    required this.isDark,
    required this.currentId,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Default platform',
            style: AppTypography.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            'Used as the preset when you open Optimize',
            style: AppTypography.dmSans(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...PlatformPreset.all.map((preset) {
            final selected = preset.id.name == currentId;
            return InkWell(
              onTap: () => onPick(preset.id.name),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: preset.color.withAlpha(isDark ? 40 : 22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(preset.icon,
                          color: preset.color, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.name,
                            style: AppTypography.dmSans(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            preset.specs,
                            style: AppTypography.dmSans(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + 4),
        ],
      ),
    );
  }
}

// ── Quality mode sheet ────────────────────────────────────────────────────────

class _QualitySheet extends StatelessWidget {
  final bool isDark;
  final String current;
  final void Function(String) onPick;

  const _QualitySheet({
    required this.isDark,
    required this.current,
    required this.onPick,
  });

  static const _options = [
    (
      label: 'Balanced',
      subtitle: 'Good quality, smaller files',
      icon: Icons.balance_rounded,
    ),
    (
      label: 'High quality',
      subtitle: 'Larger files, better detail',
      icon: Icons.hd_rounded,
    ),
    (
      label: 'Max quality',
      subtitle: 'Largest files, no compression loss',
      icon: Icons.star_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Quality mode',
            style: AppTypography.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            'Affects output file size when optimizing',
            style: AppTypography.dmSans(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ..._options.map((opt) {
            final selected = opt.label == current;
            return InkWell(
              onTap: () => onPick(opt.label),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.coral
                            .withAlpha(isDark ? 40 : 22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(opt.icon,
                          color: AppColors.coral, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.label,
                            style: AppTypography.dmSans(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            opt.subtitle,
                            style: AppTypography.dmSans(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + 4),
        ],
      ),
    );
  }
}

// ── Privacy policy sheet ──────────────────────────────────────────────────────

class _PrivacySheet extends StatelessWidget {
  final bool isDark;
  const _PrivacySheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Privacy Policy',
            style: AppTypography.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _PrivacySection(
            isDark: isDark,
            title: 'Your data stays on your device',
            body:
                'SnapTune processes all photos and videos entirely on-device. No media, metadata, or personal information is ever uploaded to external servers.',
          ),
          _PrivacySection(
            isDark: isDark,
            title: 'Face detection',
            body:
                'The People feature uses on-device ML (Google ML Kit) to detect faces. Face data is never stored persistently and never leaves your device.',
          ),
          _PrivacySection(
            isDark: isDark,
            title: 'Photo library access',
            body:
                'SnapTune requests access to your photo library solely to display, browse, and optimize your media. We do not read or transmit any file outside the app.',
          ),
          _PrivacySection(
            isDark: isDark,
            title: 'Preferences',
            body:
                'Settings such as theme, grid columns, and default platform are stored locally in SharedPreferences on your device.',
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final bool isDark;
  final String title;
  final String body;
  const _PrivacySection(
      {required this.isDark, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: AppTypography.dmSans(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ── App card ──────────────────────────────────────────────────────────────────

class _AppCard extends StatelessWidget {
  final bool isDark;
  const _AppCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/logo.png',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SnapTune',
                style: AppTypography.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Smart media optimization',
                style: AppTypography.dmSans(
                  fontSize: 13,
                  color: Colors.white.withAlpha(200),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Settings card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.outline,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(isDark ? 40 : 22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.dmSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile divider ──────────────────────────────────────────────────────────────

class _TileDivider extends StatelessWidget {
  final bool isDark;
  const _TileDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0,
      indent: 64,
      endIndent: 0,
      thickness: 0.5,
      color: isDark ? AppColors.darkOutline : AppColors.outline,
    );
  }
}

// ── Appearance sheet ──────────────────────────────────────────────────────────

class _AppearanceSheet extends StatelessWidget {
  final bool isDark;
  const _AppearanceSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currentMode = sl<ThemeNotifier>().mode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkOutline
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Appearance',
              style: AppTypography.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SheetOption(
              isDark: isDark,
              icon: Icons.brightness_auto_rounded,
              label: 'Follow system',
              selected: currentMode == ThemeMode.system,
              onTap: () {
                sl<ThemeNotifier>().setMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            _SheetOption(
              isDark: isDark,
              icon: Icons.light_mode_rounded,
              label: 'Light',
              selected: currentMode == ThemeMode.light,
              onTap: () {
                sl<ThemeNotifier>().setMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _SheetOption(
              isDark: isDark,
              icon: Icons.dark_mode_rounded,
              label: 'Dark',
              selected: currentMode == ThemeMode.dark,
              onTap: () {
                sl<ThemeNotifier>().setMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid sheet ────────────────────────────────────────────────────────────────

class _GridSheet extends StatelessWidget {
  final bool isDark;
  const _GridSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final current = sl<GridColumnsNotifier>().value;

    void pick(int count) {
      sl<GridColumnsNotifier>().setColumns(count);
      Navigator.pop(context);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkOutline
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Grid columns',
              style: AppTypography.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SheetOption(
              isDark: isDark,
              icon: Icons.grid_view_rounded,
              label: '2 columns',
              selected: current == 2,
              onTap: () => pick(2),
            ),
            _SheetOption(
              isDark: isDark,
              icon: Icons.apps_rounded,
              label: '3 columns',
              selected: current == 3,
              onTap: () => pick(3),
            ),
            _SheetOption(
              isDark: isDark,
              icon: Icons.view_comfy_rounded,
              label: '4 columns',
              selected: current == 4,
              onTap: () => pick(4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet option (shared) ─────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetOption({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.dmSans(
                    fontSize: 15,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
