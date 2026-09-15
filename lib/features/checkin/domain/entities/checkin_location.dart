/// Academia onde a treinadora atende, com seu QR impresso
/// (`coaches/{coachId}/locations/{id}`). A aluna nunca lê estes documentos:
/// o servidor devolve o nome no check-in.
class CheckInLocation {
  const CheckInLocation({
    required this.id,
    required this.coachId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.radiusM,
    required this.qrVersion,
    required this.active,
    required this.createdAt,
  });

  /// Raio padrão: um ginásio médio mais o estacionamento.
  static const double defaultRadiusM = 150;
  static const double minRadiusM = 50;
  static const double maxRadiusM = 1000;

  final String id;
  final String coachId;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final double radiusM;

  /// Sobe quando a coach "gera um QR novo": o papel antigo deixa de valer.
  final int qrVersion;
  final bool active;
  final DateTime createdAt;

  CheckInLocation copyWith({
    String? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    double? radiusM,
    int? qrVersion,
    bool? active,
  }) {
    return CheckInLocation(
      id: id ?? this.id,
      coachId: coachId,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusM: radiusM ?? this.radiusM,
      qrVersion: qrVersion ?? this.qrVersion,
      active: active ?? this.active,
      createdAt: createdAt,
    );
  }
}

/// Posição do celular no momento do scan, como o aparelho informa.
class CheckInPosition {
  const CheckInPosition({
    required this.lat,
    required this.lng,
    required this.accuracyM,
  });

  final double lat;
  final double lng;

  /// Raio de incerteza em metros. O servidor dá essa folga (até um teto).
  final double accuracyM;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'accuracy': accuracyM};
}
