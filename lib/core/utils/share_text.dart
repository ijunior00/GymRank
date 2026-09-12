import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Abre a folha de compartilhar do sistema. Onde ela não existe (Chrome
/// de computador, alguns navegadores), copia o texto e avisa — assim o
/// botão nunca "não faz nada".
Future<void> shareText(BuildContext context, String text) async {
  ShareResult result;
  try {
    result = await SharePlus.instance.share(ShareParams(text: text));
  } catch (_) {
    result = ShareResult.unavailable;
  }
  if (result.status != ShareResultStatus.unavailable) return;

  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Texto copiado. Pégalo en WhatsApp o donde quieras.'),
    ),
  );
}
