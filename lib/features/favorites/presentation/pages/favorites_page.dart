import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Favorites', style: AppTypography.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
