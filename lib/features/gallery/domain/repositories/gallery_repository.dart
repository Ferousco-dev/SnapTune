import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/media_item.dart';

abstract interface class GalleryRepository {
  Future<Either<Failure, bool>> requestPermission();

  Future<Either<Failure, List<MediaItem>>> getRecentMedia({
    int page = 0,
    int pageSize = 80,
    MediaType? filterType,
  });

  Future<Either<Failure, Uint8List?>> getThumbnail(
    String id, {
    int width = 200,
    int height = 200,
  });
}
