import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prefs_service.dart';
import '../services/theme_notifier.dart';
import '../services/grid_columns_notifier.dart';
import '../services/liked_ids_notifier.dart';
import '../../features/gallery/data/datasources/gallery_local_datasource.dart';
import '../../features/gallery/data/repositories/gallery_repository_impl.dart';
import '../../features/gallery/domain/repositories/gallery_repository.dart';
import '../../features/gallery/domain/usecases/get_recent_media.dart';
import '../../features/gallery/domain/usecases/request_gallery_permission.dart';
import '../../features/gallery/presentation/bloc/gallery_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<PrefsService>(PrefsService(prefs));
  sl.registerSingleton<ThemeNotifier>(ThemeNotifier(prefs));
  sl.registerSingleton<GridColumnsNotifier>(GridColumnsNotifier(prefs));
  sl.registerSingleton<LikedIdsNotifier>(LikedIdsNotifier(prefs));

  _registerGalleryDependencies();
}

void _registerGalleryDependencies() {
  sl.registerLazySingleton<GalleryLocalDatasource>(
    () => GalleryLocalDatasourceImpl(),
  );

  sl.registerLazySingleton<GalleryRepository>(
    () => GalleryRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => RequestGalleryPermission(sl()));
  sl.registerLazySingleton(() => GetRecentMedia(sl()));

  sl.registerFactory(
    () => GalleryBloc(
      requestPermission: sl(),
      getRecentMedia: sl(),
    ),
  );
}
