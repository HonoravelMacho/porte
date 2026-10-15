import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/widgets/hud_panel.dart';
import '../domain/file_entry.dart';
import '../services/file_service.dart';
import 'widgets/file_grid_tile.dart';
import 'widgets/file_tile.dart';
import 'widgets/porte_context_menu.dart';

/// Página de categoria — resultado da grade de categorias:
/// varredura real por extensão (imagens/áudio/vídeo/docs/pacotes),
/// com alternância lista/grade e abertura via menu de contexto.
class CategoryPage extends StatefulWidget {
  final String category;
  final String title;
  final String root;
  const CategoryPage({super.key, required this.category, required this.title, required this.root});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _files = FileService();
  List<FileEntry> _entries = [];
  bool _loading = true;
  bool _grid = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _files.byCategory(widget.root, widget.category);
    if (mounted) {
      setState(() {
        _entries = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PorteAppBar(
        title: '${widget.title} (${_entries.length})',
        actions: [
          IconButton(
            icon: Icon(_grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: const Color(0xFF22E6FF)),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF22E6FF)),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22E6FF)))
          : _entries.isEmpty
              ? const Center(
                  child: Text('Nada aqui — varredura limitada a 500 arquivos.',
                      style: TextStyle(fontFamily: 'monospace')),
                )
              : _grid
                  ? GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _entries.length,
                      itemBuilder: (context, i) => FileGridTile(
                        entry: _entries[i],
                        onTap: () => _open(_entries[i]),
                        onLongPress: () => _menu(_entries[i]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, i) => FileTile(
                        entry: _entries[i],
                        onTap: () => _open(_entries[i]),
                        onLongPress: () => _menu(_entries[i]),
                      ),
                    ),
    );
  }

  Future<void> _open(FileEntry e) async {
    if (e.isDir) {
      Navigator.pop(context);
      return;
    }
    await OpenFilex.open(e.path);
  }

  Future<void> _menu(FileEntry e) => showPorteContextMenu(
        context: context,
        entry: e,
        files: _files,
        currentDir: File(e.path).parent.path,
        onChanged: _load,
      );
}
