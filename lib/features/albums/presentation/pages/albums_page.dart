import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Albums', style: AppTypography.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
