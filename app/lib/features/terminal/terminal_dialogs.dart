import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'terminal_service.dart';

/// Diálogo de falha do terminal com o detalhe técnico exato + botão copiar.
/// É assim que o usuário nos manda o erro real (classe + mensagem da exceção).
Future<void> showTerminalFailure(
  BuildContext context, {
  required TerminalOutcome outcome,
  required String dir,
}) {
  final label = switch (outcome.result) {
    TerminalResult.opened => 'enviado',
    TerminalResult.serviceMissing => 'serviço do Termux não encontrado',
    TerminalResult.denied => 'Android bloqueou o disparo',
    TerminalResult.failed => 'falha',
  };
  final report = 'PORTE terminal: $label\npasta: $dir\ndetalhe: ${outcome.detail}';
  return showDialog(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('TERMINAL FALHOU'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pasta: $dir'),
            const SizedBox(height: 8),
            SelectableText(report),
            const SizedBox(height: 8),
            const Text('Copie e envie esse texto ao desenvolvedor.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: report));
            if (d.mounted) Navigator.pop(d);
          },
          child: const Text('COPIAR'),
        ),
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('FECHAR')),
      ],
    ),
  );
}
