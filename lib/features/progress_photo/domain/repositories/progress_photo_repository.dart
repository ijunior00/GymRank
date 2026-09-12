import 'dart:typed_data';

import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/progress_photo/domain/entities/progress_photo_entity.dart';

abstract interface class ProgressPhotoRepository {
  Stream<List<ProgressPhotoEntity>> watchAll(String userId);

  /// Recebe os bytes (e não um `File`) para funcionar também no navegador,
  /// onde `dart:io` não existe. O `image_picker` devolve `XFile`, que dá
  /// `readAsBytes()` em qualquer plataforma.
  Future<Result<ProgressPhotoEntity>> upload({
    required String userId,
    required Uint8List bytes,
    required ProgressPhotoCategory category,
    double? weightAtTimeKg,
  });
}
