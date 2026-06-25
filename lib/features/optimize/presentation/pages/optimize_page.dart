import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

class OptimizePage extends StatelessWidget {
  const OptimizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Optimize', style: AppTypography.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
