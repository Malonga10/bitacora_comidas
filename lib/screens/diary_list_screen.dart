import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/database_helper.dart';
import '../models/meal_entry.dart';
import '../widgets/app_drawer.dart';
import '../widgets/meal_thumb.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  late Future<List<MealEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.getAll();
  }

  void _reload() {
    setState(() {
      _future = DatabaseHelper.instance.getAll();
    });
  }

  Future<void> _openDetail(MealEntry entry) async {
    await Navigator.pushNamed(context, AppRoutes.detail, arguments: entry);
    if (!mounted) return;
    _reload();
  }

  Future<void> _openForm() async {
    final saved = await Navigator.pushNamed(context, AppRoutes.form);
    if (!mounted) return;
    if (saved == true) _reload();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final filter = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(title: Text(filter ?? 'Bitácora de Comidas')),
      drawer: AppDrawer(currentFilter: filter),
      body: FutureBuilder<List<MealEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final all = snapshot.data ?? [];
          final entries =
          filter == null ? all : all.where((e) => e.mealType == filter).toList();

          if (entries.isEmpty) {
            return Center(
              child: Text(
                filter == null
                    ? 'Aún no hay comidas.\nToca "Nueva" para agregar la primera.'
                    : 'No hay entradas de $filter.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88, top: 8),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: MealThumb(entry: e, size: 56),
                  title: Text(e.title),
                  subtitle: Text('${e.mealType} · ${_formatDate(e.createdAt)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openDetail(e),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}