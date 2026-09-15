/// Os dois formatos de QR de check-in, do ponto de vista do app.
///
/// - **Rotativo** (tela da coach): `coachId.issuedAt.assinatura`, vale 30 s.
/// - **De academia** (impresso): um link do site com `c`, `l`, `v` e `s`
///   na query; exige a localização do celular.
abstract final class CheckInQr {
  /// `true` se o payload é o QR impresso de uma academia. Aceita a URL
  /// completa, o caminho `/checkin?...` ou só a query.
  static bool isLocationPayload(String payload) {
    final params = queryParams(payload);
    return params.containsKey('c') && params.containsKey('l') && params.containsKey('s');
  }

  /// Só a query (`c=…&l=…&v=…&s=…`), que é o que o servidor precisa.
  static String queryOf(String payload) {
    final trimmed = payload.trim();
    final q = trimmed.indexOf('?');
    return q >= 0 ? trimmed.substring(q + 1) : trimmed;
  }

  static Map<String, String> queryParams(String payload) {
    try {
      return Uri.splitQueryString(queryOf(payload));
    } on ArgumentError {
      return const {};
    }
  }
}
