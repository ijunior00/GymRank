import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymrank/core/constants/app_constants.dart';

part 'progress_photo_entity.freezed.dart';

/// Documento canônico de `progress_photos/{photoId}`.
@freezed
class ProgressPhotoEntity with _$ProgressPhotoEntity {
  const factory ProgressPhotoEntity({
    required String id,
    required String userId,
    required String storageUrl,
    required String thumbnailUrl,
    required ProgressPhotoCategory category,
    required DateTime takenAt,
    double? weightAtTimeKg,
  }) = _ProgressPhotoEntity;
}
