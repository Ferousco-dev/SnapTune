import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/media_item_model.dart';

abstract interface class GalleryLocalDatasource {
  Future<bool> requestPermission();
  Future<List<MediaItemModel>> getRecentMedia({
    int page = 0,
    int pageSize = 80,
    RequestType? filterType,
  });
  Future<Uint8List?> getThumbnail(String id, {int width = 200, int height = 200});
}

class GalleryLocalDatasourceImpl implements GalleryLocalDatasource {
  @override
  Future<bool> requestPermission() async {
    // Request audio permission on Android 13+ (needed for FFmpegKit to read audio tracks)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.audio.request();
    }
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result == PermissionState.limited;
  }

  @override
  Future<List<MediaItemModel>> getRecentMedia({
    int page = 0,
    int pageSize = 80,
    RequestType? filterType,
  }) async {
    final albums = await PhotoManager.getAssetPathList(
      type: filterType ?? RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (albums.isEmpty) return [];

    final recent = albums.firstWhere(
      (a) => a.isAll,
      orElse: () => albums.first,
    );

    final assets = await recent.getAssetListPaged(page: page, size: pageSize);
    return assets.map(MediaItemModel.fromAsset).toList();
  }

  @override
  Future<Uint8List?> getThumbnail(
    String id, {
    int width = 200,
    int height = 200,
  }) async {
    final asset = await AssetEntity.fromId(id);
    if (asset == null) return null;
    return asset.thumbnailDataWithSize(ThumbnailSize(width, height));
  }
}
