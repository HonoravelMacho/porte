import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../terminal/terminal_service.dart';
import '../../services/file_service.dart';
import '../../domain/file_entry.dart';

/// Menu de contexto da pasta/arquivo — inclui "Abrir Terminal"
/// (requisito §4), além de abrir/compartilhar/renomear/copiar/excluir.
Future<void> showPorteContextMenu({
  required BuildContext context,
  required FileEntry entry,
  required FileService files,
  required String currentDir,
  required VoidCallback onChanged,
}) {
  final terminal = TerminalService();
  final isDir = entry.isDir;
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.terminal_rounded),
            title: const Text('Abrir Terminal aqui'),
            subtitle: Text(entry.path, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () async {
              Navigator.pop(ctx);
              final target = isDir ? entry.path : currentDir;
              final res = await terminal.openTerminal(target);
              if (ctx.mounted && res != TerminalResult.opened) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      res == TerminalResult.notInstalled
                          ? 'Termux não encontrado — abrimos a página dele no F-Droid. Depois rode termux-setup-storage dentro dele.'
                          : 'Terminal indisponível — no Linux instale xterm ou gnome-terminal.',
                    ),
                  ),
                );
              }
            },
          ),
          if (!isDir) ...[
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Abrir com app padrão'),
              onTap: () async {
                Navigator.pop(ctx);
                await OpenFilex.open(entry.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Compartilhar'),
              onTap: () async {
                Navigator.pop(ctx);
                await SharePlus.instance.share(ShareParams(files: [XFile(entry.path)]));
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.folder_open_rounded),
              title: const Text('Abrir pasta'),
              onTap: () {
                Navigator.pop(ctx);
                onChanged(); // o chamador navega via onChanged customizado
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline_rounded),
            title: const Text('Renomear'),
            onTap: () async {
              Navigator.pop(ctx);
              final ctrl = TextEditingController(text: entry.name);
              final out = await showDialog<String>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('RENOMEAR'),
                  content: TextField(controller: ctrl, autofocus: true),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d), child: const Text('CANCELAR')),
                    TextButton(onPressed: () => Navigator.pop(d, ctrl.text.trim()), child: const Text('OK')),
                  ],
                ),
              );
              if (out != null && out.isNotEmpty && out != entry.name) {
                try {
                  await files.rename(entry.path, out);
                  onChanged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Excluir'),
            onTap: () async {
              Navigator.pop(ctx);
              final ok = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('EXCLUIR?'),
                  content: Text(entry.path),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('NÃO')),
                    TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('SIM')),
                  ],
                ),
              );
              if (ok == true) {
                try {
                  await files.delete(entry.path);
                  onChanged();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              }
            },
          ),
          if (!isDir && Platform.isAndroid)
            ListTile(
              leading: const Icon(Icons.install_mobile_rounded),
              title: const Text('Detalhes'),
              subtitle: Text('${entry.size} bytes • ${entry.modified}'),
              onTap: () => Navigator.pop(ctx),
            ),
        ],
      ),
    ),
  );
}
