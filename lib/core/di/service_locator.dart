import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  _registerGalleryDependencies();
  _registerOptimizationDependencies();
}

void _registerGalleryDependencies() {
  // Registered when gallery feature is built
}

void _registerOptimizationDependencies() {
  // Registered when optimization feature is built
}
