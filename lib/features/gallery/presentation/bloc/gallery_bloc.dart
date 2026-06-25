import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/usecases/get_recent_media.dart';
import '../../domain/usecases/request_gallery_permission.dart';
import 'gallery_event.dart';
import 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final RequestGalleryPermission _requestPermission;
  final GetRecentMedia _getRecentMedia;

  static const _pageSize = 80;

  GalleryBloc({
    required RequestGalleryPermission requestPermission,
    required GetRecentMedia getRecentMedia,
  })  : _requestPermission = requestPermission,
        _getRecentMedia = getRecentMedia,
        super(const GalleryState()) {
    on<GalleryStarted>(_onStarted);
    on<GalleryFilterChanged>(_onFilterChanged);
    on<GalleryLoadMore>(_onLoadMore);
    on<GalleryRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
    GalleryStarted event,
    Emitter<GalleryState> emit,
  ) async {
    emit(state.copyWith(status: GalleryStatus.loading));

    final permResult = await _requestPermission();
    final granted = permResult.fold((_) => false, (v) => v);

    if (!granted) {
      emit(state.copyWith(status: GalleryStatus.permissionDenied));
      return;
    }

    await _loadPage(emit, page: 0, filter: state.activeFilter, replace: true);
  }

  Future<void> _onFilterChanged(
    GalleryFilterChanged event,
    Emitter<GalleryState> emit,
  ) async {
    emit(state.copyWith(
      status: GalleryStatus.loading,
      activeFilter: () => event.filterType,
      page: 0,
      items: [],
    ));
    await _loadPage(emit, page: 0, filter: event.filterType, replace: true);
  }

  Future<void> _onLoadMore(
    GalleryLoadMore event,
    Emitter<GalleryState> emit,
  ) async {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.page + 1;
    await _loadPage(emit, page: nextPage, filter: state.activeFilter, replace: false);
  }

  Future<void> _onRefreshed(
    GalleryRefreshed event,
    Emitter<GalleryState> emit,
  ) async {
    emit(state.copyWith(status: GalleryStatus.loading, page: 0, items: []));
    await _loadPage(emit, page: 0, filter: state.activeFilter, replace: true);
  }

  Future<void> _loadPage(
    Emitter<GalleryState> emit, {
    required int page,
    required MediaType? filter,
    required bool replace,
  }) async {
    final result = await _getRecentMedia(
      page: page,
      pageSize: _pageSize,
      filterType: filter,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: GalleryStatus.error,
        errorMessage: failure.message,
      )),
      (newItems) {
        final all = replace ? newItems : [...state.items, ...newItems];
        emit(state.copyWith(
          status: GalleryStatus.loaded,
          items: all,
          page: page,
          hasMore: newItems.length == _pageSize,
        ));
      },
    );
  }
}
