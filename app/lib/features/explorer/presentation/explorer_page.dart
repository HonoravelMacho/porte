import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/porte_colors.dart';
import '../../../core/widgets/hud_panel.dart';
import '../domain/file_entry.dart';
import '../services/file_service.dart';
import '../../terminal/terminal_dialogs.dart';
import 'widgets/category_grid.dart';
import 'widgets/file_tile.dart';
import 'widgets/path_bar.dart';
import 'widgets/porte_context_menu.dart';
import 'widgets/storage_carousel.dart';

/// Tela principal — fiel ao MVP do original:
/// carrossel de armazenamento (desktop2) + grade de categorias +
/// PathBar + lista de arquivos (fragment_file_list) + menu inferior.
class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});
  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  final _files = FileService();
  String _dir = '/storage/emulated/0';
  List<FileEntry> _entries = [];
  bool _loading = true;
  String? _error;
  final Set<String> _selected = {};
  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (Platform.isAndroid) {
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();
      }
      if (Platform.isLinux || !(await Directory(_dir).exists())) {
        String home = '/';
        try {
          home = Platform.isLinux
              ? (Platform.environment['HOME'] ?? '/')
              : (await getApplicationDocumentsDirectory()).path;
        } catch (_) {
          home = '/';
        }
        _dir = home;
      }
    } catch (_) {
      _dir = '/';
    }
    await _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _files.list(_dir);
      setState(() {
        _entries = list;
        _selected.clear();
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigate(String path) {
    setState(() => _dir = path);
    _reload();
  }

  void _openEntry(FileEntry e) {
    if (e.kind == PorteEntryKind.parent) {
      _navigate(e.path);
    } else if (e.isDir) {
      _navigate(e.path);
    } else {
      showPorteContextMenu(
        context: context,
        entry: e,
        files: _files,
        currentDir: _dir,
        onChanged: _reload,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PorteAppBar(
        title: 'PORTE // EXPLORER',
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: PorteColors.cyanNeon),
            onPressed: _onSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: PorteColors.cyanNeon),
            onPressed: _reload,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PorteColors.cyanNeon))
          : RefreshIndicator(
              color: PorteColors.cyanNeon,
              onRefresh: _reload,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: StorageCarousel(
                        label: 'INTERNO',
                        usedRatio: 0.42,
                        usedText: '—',
                        totalText: '—',
                        table: const {'imagens': '—', 'audio': '—', 'video': '—'},
                        onAnalyze: _onAnalyze,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: HudPanel(
                        title: 'CATEGORIAS',
                        child: CategoryGrid(onOpen: _onCategory),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: PathBar(currentPath: _dir, onNavigate: _navigate),
                  ),
                  if (_error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_error!, style: const TextStyle(color: PorteColors.danger, fontFamily: 'monospace')),
                      ),
                    ),
                  SliverList.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, i) {
                      final e = _entries[i];
                      return FileTile(
                        entry: e,
                        selected: _selected.contains(e.path),
                        selectionMode: _selectionMode,
                        onTap: () {
                          if (_selectionMode && e.kind != PorteEntryKind.parent) {
                            setState(() {
                              _selected.contains(e.path)
                                  ? _selected.remove(e.path)
                                  : _selected.add(e.path);
                            });
                          } else {
                            _openEntry(e);
                          }
                        },
                        onLongPress: () => showPorteContextMenu(
                          context: context,
                          entry: e,
                          files: _files,
                          currentDir: _dir,
                          onChanged: _reload,
                        ),
                        onSelected: (v) => setState(() {
                          v ? _selected.add(e.path) : _selected.remove(e.path);
                        }),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
      floatingActionButton: _selectionMode
          ? FloatingActionButton.extended(
              backgroundColor: PorteColors.danger,
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete_outline),
              label: Text('EXCLUIR (${_selected.length})'),
            )
          : FloatingActionButton(
              backgroundColor: PorteColors.cyanNeon,
              foregroundColor: PorteColors.abyss,
              onPressed: _onFabPressed,
              child: const Icon(Icons.add),
            ),
    );
  }

  /// Botão + agora oferece as duas ações: criar pasta OU abrir terminal aqui.
  /// O cabeçalho mostra a versão do PORTE (diagnóstico: confirma qual build
  /// está instalada no aparelho).
  Future<void> _onFabPressed() async {
    String version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = 'v${info.version}+${info.buildNumber}';
    } catch (_) {}
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Row(
                children: [
                  const Icon(Icons.radar, color: PorteColors.amberNeon, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'PORTE $version',
                    style: const TextStyle(
                      color: PorteColors.textDim,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined, color: PorteColors.cyanNeon),
              title: const Text('Criar nova pasta'),
              subtitle: Text(_dir, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(ctx, 'mkdir'),
            ),
            ListTile(
              leading: const Icon(Icons.terminal_rounded, color: PorteColors.amberNeon),
              title: const Text('Abrir pasta atual no terminal'),
              subtitle: Text(_dir, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(ctx, 'terminal'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'mkdir') {
      await _onCreateFolder();
    } else if (choice == 'terminal') {
      await _onOpenTerminalHere();
    }
  }

  Future<void> _onOpenTerminalHere() => handleTerminalRequest(context, _dir);

  Future<void> _onAnalyze() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analisando armazenamento... (MVP: soma limitada a 4000 entradas)')),
    );
    final size = await _files.dirSize(_dir);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total aproximado em $_dir: ${formatSize(size)}')),
      );
    }
  }

  void _onCategory(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Categoria $key — filtro por extensão chega no próximo sprint.')),
    );
  }

  Future<void> _onSearch() async {
    final q = await showDialog<String>(
      context: context,
      builder: (d) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('BUSCAR'),
          content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'nome...')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('FECHAR')),
            TextButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('IR')),
          ],
        );
      },
    );
    if (q == null || q.isEmpty) return;
    final res = await _files.search(_dir, q);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('RESULTADOS (${res.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: res.length,
            itemBuilder: (_, i) => ListTile(
              dense: true,
              title: Text(res[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(res[i].path, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(d);
                if (res[i].isDir) _navigate(res[i].path);
              },
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('FECHAR'))],
      ),
    );
  }

  Future<void> _onCreateFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (d) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('NOVA PASTA'),
          content: TextField(controller: c, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('CANCELAR')),
            TextButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('CRIAR')),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    try {
      await _files.createFolder(_dir, name);
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteSelected() async {
    for (final p in _selected.toList()) {
      try {
        await _files.delete(p);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    await _reload();
  }
}
