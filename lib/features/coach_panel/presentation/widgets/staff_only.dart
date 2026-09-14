import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';

/// Porteiro das telas do painel: só entra quem é staff (treinadora,
/// nutrióloga, administração).
///
/// Por que na tela e não só no roteador: estas telas são empurradas com
/// `context.push`, e nesse caso o endereço continua sendo o de antes
/// (`/home`). Uma guarda que olhe o endereço não enxerga que a tela de
/// coach está aberta. Aqui a decisão é da própria tela, então vale
/// qualquer que tenha sido o caminho — link de notificação, endereço
/// digitado, a sessão trocando de conta com a tela aberta, ou o papel da
/// pessoa mudando no meio do caminho.
///
/// Sem isto o que aparece é o `permission-denied` cru do Firestore: a
/// regra recusa (certo), mas quem vê é a aluna, no meio de uma tela que
/// nunca foi para ela.
class StaffOnly extends ConsumerWidget {
  const StaffOnly({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    // Ainda não sabemos quem é: esperar. Expulsar agora tiraria a
    // treinadora do próprio painel no primeiro quadro.
    if (user == null) return const _Waiting();

    if (!user.isStaff) {
      // `maybeOf`: barrar a entrada é o essencial e não pode depender de
      // haver um roteador por perto — mandar de volta ao início é o
      // acabamento.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) GoRouter.maybeOf(context)?.go('/home');
      });
      return const _Waiting();
    }

    return child;
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
