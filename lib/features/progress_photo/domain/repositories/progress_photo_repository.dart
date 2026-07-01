import 'dart:io';

import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/progress_photo/domain/entities/progress_photo_entity.dart';

abstract interface class ProgressPhotoRepository {
  Stream<List<ProgressPhotoEntity>> watchAll(String userId);

  Future<Result<ProgressPhotoEntity>> upload({
    required String userId,
    required File file,
    required ProgressPhotoCategory category,
    double? weightAtTimeKg,
  });
}
