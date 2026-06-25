import 'package:flutter/material.dart';
import '../pages/onboarding_page.dart';
import 'onboarding_illustrations.dart';

class OnboardingStep extends StatelessWidget {
  final OnboardingStepData data;

  const OnboardingStep({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Illustration takes the upper portion
          Expanded(
            flex: 5,
            child: Center(child: _illustration(data.assetPath)),
          ),

          // Text block pinned to bottom of expanded area
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _illustration(String assetPath) {
    if (assetPath.contains('gallery')) return const IllustrationGallery();
    if (assetPath.contains('optimize')) return const IllustrationOptimize();
    return const IllustrationShare();
  }
}
