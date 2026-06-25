import 'package:equatable/equatable.dart';
import '../../domain/entities/media_item.dart';

enum GalleryStatus { initial, loading, loaded, error, permissionDenied }

class GalleryState extends Equatable {
  final GalleryStatus status;
  final List<MediaItem> items;
  final MediaType? activeFilter;
  final bool hasMore;
  final int page;
  final String? errorMessage;

  const GalleryState({
    this.status = GalleryStatus.initial,
    this.items = const [],
    this.activeFilter,
    this.hasMore = true,
    this.page = 0,
    this.errorMessage,
  });

  bool get isLoading => status == GalleryStatus.loading;
  bool get isLoaded => status == GalleryStatus.loaded;
  bool get isEmpty => isLoaded && items.isEmpty;

  GalleryState copyWith({
    GalleryStatus? status,
    List<MediaItem>? items,
    MediaType? Function()? activeFilter,
    bool? hasMore,
    int? page,
    String? errorMessage,
  }) {
    return GalleryState(
      status: status ?? this.status,
      items: items ?? this.items,
      activeFilter: activeFilter != null ? activeFilter() : this.activeFilter,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, activeFilter, hasMore, page, errorMessage];
}
