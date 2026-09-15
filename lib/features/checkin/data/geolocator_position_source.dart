import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_location.dart';
import 'package:gymrank/features/checkin/domain/repositories/checkin_repository.dart';

/// Posição via GPS do aparelho (ou do navegador, no web). Cada motivo de
/// falha vira uma frase que a aluna consegue resolver sozinha.
class GeolocatorPositionSource implements PositionSource {
  const GeolocatorPositionSource();

  static const _timeout = Duration(seconds: 20);

  @override
  Future<Result<CheckInPosition>> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const Result.failure(Failure.validation(
          'Activa la ubicación (GPS) del celular e intenta de nuevo.',
        ));
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const Result.failure(Failure.validation(
          'Necesitamos tu ubicación para confirmar que estás en la academia.',
        ));
      }
      if (permission == LocationPermission.deniedForever) {
        return const Result.failure(Failure.validation(
          'El permiso de ubicación está bloqueado. Actívalo en los ajustes del '
          'navegador o del celular y vuelve a intentar.',
        ));
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        ),
      );
      return Result.success(
        CheckInPosition(lat: p.latitude, lng: p.longitude, accuracyM: p.accuracy),
      );
    } on TimeoutException {
      return const Result.failure(Failure.validation(
        'No conseguimos tu ubicación a tiempo. Sal a un lugar más abierto e '
        'intenta de nuevo.',
      ));
    } on LocationServiceDisabledException {
      return const Result.failure(Failure.validation(
        'Activa la ubicación (GPS) del celular e intenta de nuevo.',
      ));
    } catch (e) {
      return Result.failure(Failure.unexpected('$e'));
    }
  }
}
