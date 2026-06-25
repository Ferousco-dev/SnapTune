import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../datasources/gallery_local_datasource.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  final GalleryLocalDatasource _datasource;
  const GalleryRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    try {
      final granted = await _datasource.requestPermission();
      return Right(granted);
    } catch (e) {
      return Left(PermissionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MediaItem>>> getRecentMedia({
    int page = 0,
    int pageSize = 80,
    MediaType? filterType,
  }) async {
    try {
      RequestType? requestType;
      if (filterType == MediaType.image) requestType = RequestType.image;
      if (filterType == MediaType.video) requestType = RequestType.video;

      final items = await _datasource.getRecentMedia(
        page: page,
        pageSize: pageSize,
        filterType: requestType,
      );
      return Right(items);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List?>> getThumbnail(
    String id, {
    int width = 200,
    int height = 200,
  }) async {
    try {
      final bytes = await _datasource.getThumbnail(id, width: width, height: height);
      return Right(bytes);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
