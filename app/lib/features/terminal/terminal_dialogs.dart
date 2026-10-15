import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'terminal_service.dart';

/// Fluxo unificado: dispara, aguarda o veredito do Termux (até 10s) e mostra
/// sucesso ou o diálogo de falha com o erro exato + copiar. Sem veredito
/// (timeout), assume sessão interativa aberta = sucesso.
Future<void> handleTerminalRequest(BuildContext context, String dir) async {
  final terminal = TerminalService();
  final outcome = await terminal.openTerminal(dir);
  if (!context.mounted) return;
  if (!outcome.opened) {
    await showTerminalFailure(context, outcome: outcome, dir: dir);
    return;
  }
  final verdict = await terminal.waitForVerdict();
  if (!context.mounted) return;
  if (verdict == null || verdict.opened) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terminal aberto em $dir')),
    );
  } else {
    await showTerminalFailure(context, outcome: verdict, dir: dir);
  }
}

/// Diálogo de falha do terminal com o detalhe técnico exato + botões:
/// COPIAR (manda o erro ao dev) e ABRIR O TERMUX (plano B sem permissão).
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
  final terminal = TerminalService();
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
            const Text(
              'Tente: 1) ABRIR O TERMUX abaixo. 2) Se o disparo direto seguir negado, desinstale o PORTE e instale o APK de novo (a permissão do Termux pode ter ficado obsoleta no upgrade).',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final ok = await terminal.launchTermuxApp();
            if (d.mounted && !ok) {
              ScaffoldMessenger.of(d).showSnackBar(
                const SnackBar(content: Text('Termux não encontrado para abrir.')),
              );
            }
          },
          child: const Text('ABRIR O TERMUX'),
        ),
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
