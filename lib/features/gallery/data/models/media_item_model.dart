import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/media_item.dart';

class MediaItemModel extends MediaItem {
  const MediaItemModel({
    required super.id,
    required super.title,
    required super.type,
    required super.createDate,
    required super.width,
    required super.height,
    required super.size,
    super.duration,
    super.mimeType,
  });

  factory MediaItemModel.fromAsset(AssetEntity asset) {
    return MediaItemModel(
      id: asset.id,
      title: asset.title ?? '',
      type: asset.type == AssetType.video ? MediaType.video : MediaType.image,
      createDate: asset.createDateTime,
      width: asset.width,
      height: asset.height,
      size: asset.size,
      duration: asset.duration,
      mimeType: asset.mimeType,
    );
  }
}
