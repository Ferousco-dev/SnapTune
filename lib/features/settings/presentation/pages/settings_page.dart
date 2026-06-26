import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
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
                subtitle: 'Follow system',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
                onTap: () => _showAppearanceSheet(context, isDark),
              ),
              _TileDivider(isDark: isDark),
              _SettingsTile(
                isDark: isDark,
                icon: Icons.grid_view_rounded,
                iconColor: AppColors.primary,
                title: 'Grid columns',
                subtitle: '3 columns',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
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
                subtitle: 'WhatsApp Status',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
                onTap: () => _showComingSoon(context),
              ),
              _TileDivider(isDark: isDark),
              _SettingsTile(
                isDark: isDark,
                icon: Icons.high_quality_rounded,
                iconColor: AppColors.coral,
                title: 'Quality mode',
                subtitle: 'Balanced',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
                onTap: () => _showComingSoon(context),
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
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
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
                iconColor: const Color(0xFFFFB800),
                title: 'Rate SnapTune',
                subtitle: 'Enjoying the app? Share the love',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
                onTap: () => _showComingSoon(context),
              ),
              _TileDivider(isDark: isDark),
              _SettingsTile(
                isDark: isDark,
                icon: Icons.feedback_outlined,
                iconColor: AppColors.violet,
                title: 'Send feedback',
                subtitle: 'Help us improve SnapTune',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
                onTap: () => _showComingSoon(context),
              ),
              _TileDivider(isDark: isDark),
              _SettingsTile(
                isDark: isDark,
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.primary,
                title: 'Privacy policy',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
                onTap: () => _showComingSoon(context),
              ),
              _TileDivider(isDark: isDark),
              _SettingsTile(
                isDark: isDark,
                icon: Icons.info_outline_rounded,
                iconColor: isDark ? AppColors.darkMuted : AppColors.muted,
                title: 'Version',
                subtitle: '1.0.0 (build 1)',
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_fix_high_rounded,
              color: Colors.white,
              size: 28,
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
                  color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
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
            ..._themeOptions(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _themeOptions(BuildContext context) {
    final options = [
      (Icons.brightness_auto_rounded, 'Follow system', true),
      (Icons.light_mode_rounded, 'Light', false),
      (Icons.dark_mode_rounded, 'Dark', false),
    ];
    return options.map((opt) {
      final (icon, label, selected) = opt;
      return _SheetOption(
        isDark: isDark,
        icon: icon,
        label: label,
        selected: selected,
        onTap: () => Navigator.pop(context),
      );
    }).toList();
  }
}

class _GridSheet extends StatelessWidget {
  final bool isDark;
  const _GridSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
                  color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
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
              selected: false,
              onTap: () => Navigator.pop(context),
            ),
            _SheetOption(
              isDark: isDark,
              icon: Icons.apps_rounded,
              label: '3 columns',
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            _SheetOption(
              isDark: isDark,
              icon: Icons.view_comfy_rounded,
              label: '4 columns',
              selected: false,
              onTap: () => Navigator.pop(context),
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
