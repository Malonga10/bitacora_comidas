import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'meal_thumb.dart';

class AppDrawer extends StatelessWidget {
  final String? currentFilter;

  const AppDrawer({super.key, this.currentFilter});

  static const List<String> mealTypes = ['Desayuno', 'Comida', 'Cena', 'Snack'];

  void _showList(BuildContext context, String? filter) {
    final navigator = Navigator.of(context);
    navigator.pop(); // cierra el drawer
    navigator.pushReplacementNamed(AppRoutes.list, arguments: filter);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: scheme.primaryContainer),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Bitácora de Comidas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Todas las comidas'),
            selected: currentFilter == null,
            onTap: () => _showList(context, null),
          ),
          for (final type in mealTypes)
            ListTile(
              leading: Icon(iconForMealType(type)),
              title: Text(type),
              selected: currentFilter == type,
              onTap: () => _showList(context, type),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Nueva entrada'),
            onTap: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.pushNamed(AppRoutes.form);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () {
              Navigator.of(context).pop();
              showAboutDialog(
                context: context,
                applicationName: 'Bitácora de Comidas',
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    );
  }
}