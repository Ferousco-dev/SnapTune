import 'package:equatable/equatable.dart';
import '../../domain/entities/media_item.dart';

abstract class GalleryEvent extends Equatable {
  const GalleryEvent();
  @override
  List<Object?> get props => [];
}

class GalleryStarted extends GalleryEvent {
  const GalleryStarted();
}

class GalleryFilterChanged extends GalleryEvent {
  final MediaType? filterType;
  const GalleryFilterChanged(this.filterType);
  @override
  List<Object?> get props => [filterType];
}

class GalleryLoadMore extends GalleryEvent {
  const GalleryLoadMore();
}

class GalleryRefreshed extends GalleryEvent {
  const GalleryRefreshed();
}
