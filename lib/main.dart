import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'models/meal_entry.dart';
import 'screens/diary_detail_screen.dart';
import 'screens/diary_form_screen.dart';
import 'screens/diary_list_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitácora de Comidas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.list,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.detail:
            final entry = settings.arguments as MealEntry;
            return MaterialPageRoute(
              builder: (_) => DiaryDetailScreen(entry: entry),
              settings: settings,
            );
          case AppRoutes.form:
            return MaterialPageRoute(
              builder: (_) => const DiaryFormScreen(),
              settings: settings,
            );
          case AppRoutes.list:
          default:
            return MaterialPageRoute(
              builder: (_) => const DiaryListScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}