import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/grid_columns_notifier.dart';
import '../../../../core/services/theme_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = info.version);
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
    final uri = Uri.parse('https://wa.me/2349072182889');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
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
                  icon: Icons.contrast_rounded,
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
                  icon: Icons.border_all_rounded,
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
            
            _SectionLabel('Storage'),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.delete_sweep_outlined,
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
                  icon: FontAwesomeIcons.whatsapp,
                  iconColor: const Color(0xFF25D366),
                  title: 'Send feedback',
                  subtitle: 'Chat with us on WhatsApp',
                  onTap: _sendFeedback,
                  isBrand: true,
                ),
                _TileDivider(isDark: isDark),
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.primary,
                  title: 'Privacy policy',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.muted),
                  onTap: () => _showPrivacySheet(context, isDark),
                ),
                _TileDivider(isDark: isDark),
                _SettingsTile(
                  isDark: isDark,
                  icon: Icons.tag_rounded,
                  iconColor: isDark ? AppColors.darkMuted : AppColors.muted,
                  title: 'Version',
                  subtitle: _version.isEmpty ? '...' : _version,
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
                'Media optimization',
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


class _SettingsTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isBrand;

  const _SettingsTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isBrand = false,
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
                child: isBrand
                    ? FaIcon(icon, color: iconColor, size: 16)
                    : Icon(icon, color: iconColor, size: 18),
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
