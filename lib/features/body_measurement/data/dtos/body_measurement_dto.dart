import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/features/body_measurement/domain/entities/body_measurement_entity.dart';

class BodyMeasurementDto {
  static BodyMeasurementEntity fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return BodyMeasurementEntity(
      id: doc.id,
      userId: data['userId'] as String,
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      pesoKg: (data['pesoKg'] as num?)?.toDouble(),
      percentualGordura: (data['percentualGordura'] as num?)?.toDouble(),
      massaMuscularKg: (data['massaMuscularKg'] as num?)?.toDouble(),
      imc: (data['imc'] as num?)?.toDouble(),
      bracoCm: (data['bracoCm'] as num?)?.toDouble(),
      peitoralCm: (data['peitoralCm'] as num?)?.toDouble(),
      cinturaCm: (data['cinturaCm'] as num?)?.toDouble(),
      abdomenCm: (data['abdomenCm'] as num?)?.toDouble(),
      quadrilCm: (data['quadrilCm'] as num?)?.toDouble(),
      coxaCm: (data['coxaCm'] as num?)?.toDouble(),
      panturrilhaCm: (data['panturrilhaCm'] as num?)?.toDouble(),
    );
  }

  static Map<String, dynamic> toMap(BodyMeasurementEntity entity) {
    return {
      'userId': entity.userId,
      'recordedAt': Timestamp.fromDate(entity.recordedAt),
      'pesoKg': entity.pesoKg,
      'percentualGordura': entity.percentualGordura,
      'massaMuscularKg': entity.massaMuscularKg,
      'imc': entity.imc,
      'bracoCm': entity.bracoCm,
      'peitoralCm': entity.peitoralCm,
      'cinturaCm': entity.cinturaCm,
      'abdomenCm': entity.abdomenCm,
      'quadrilCm': entity.quadrilCm,
      'coxaCm': entity.coxaCm,
      'panturrilhaCm': entity.panturrilhaCm,
    };
  }
}
