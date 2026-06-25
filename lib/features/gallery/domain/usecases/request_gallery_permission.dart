import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/gallery_repository.dart';

class RequestGalleryPermission {
  final GalleryRepository _repository;
  const RequestGalleryPermission(this._repository);

  Future<Either<Failure, bool>> call() => _repository.requestPermission();
}
