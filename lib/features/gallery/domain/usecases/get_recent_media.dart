import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/media_item.dart';
import '../repositories/gallery_repository.dart';

class GetRecentMedia {
  final GalleryRepository _repository;
  const GetRecentMedia(this._repository);

  Future<Either<Failure, List<MediaItem>>> call({
    int page = 0,
    int pageSize = 80,
    MediaType? filterType,
  }) =>
      _repository.getRecentMedia(
        page: page,
        pageSize: pageSize,
        filterType: filterType,
      );
}
