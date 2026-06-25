import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Settings', style: AppTypography.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
