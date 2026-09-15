/// O que qualquer pessoa logada pode saber de outra: o "cartão" que a
/// busca por @, a lista de amigas e o ranking mostram. Vem de
/// `public_profiles/{uid}`, espelho de `users/{uid}` mantido por Cloud
/// Function. O perfil completo (nascimento, altura, cidade…) só a própria
/// pessoa e o staff da comunidade dela leem.
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.photoUrl,
    required this.level,
  });

  final String id;
  final String name;
  final String username;
  final String? photoUrl;
  final int level;
}
