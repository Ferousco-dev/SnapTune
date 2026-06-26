import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/services/theme_notifier.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initDependencies();

  runApp(const SnapTuneApp());
}

class SnapTuneApp extends StatelessWidget {
  const SnapTuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeNotifier>(),
      builder: (context, _) => MaterialApp.router(
        title: 'SnapTune',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: sl<ThemeNotifier>().mode,
        routerConfig: appRouter,
      ),
    );
  }
}
