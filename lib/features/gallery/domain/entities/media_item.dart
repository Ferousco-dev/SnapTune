import 'package:equatable/equatable.dart';

enum MediaType { image, video }

class MediaItem extends Equatable {
  final String id;
  final String title;
  final MediaType type;
  final DateTime createDate;
  final int width;
  final int height;
  final int size;
  final int duration; // seconds, 0 for images
  final String? mimeType;

  const MediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.createDate,
    required this.width,
    required this.height,
    required this.size,
    this.duration = 0,
    this.mimeType,
  });

  bool get isVideo => type == MediaType.video;
  bool get isImage => type == MediaType.image;

  double get aspectRatio => height == 0 ? 1.0 : width / height;

  @override
  List<Object?> get props =>
      [id, title, type, createDate, width, height, size, duration, mimeType];
}
