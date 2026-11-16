import 'dart:io';

import 'package:flutter/material.dart';

import '../models/meal_entry.dart';

IconData iconForMealType(String type) {
  switch (type) {
    case 'Desayuno':
      return Icons.free_breakfast;
    case 'Comida':
      return Icons.lunch_dining;
    case 'Cena':
      return Icons.dinner_dining;
    default:
      return Icons.cookie;
  }
}

class MealThumb extends StatelessWidget {
  final MealEntry entry;
  final double size;

  const MealThumb({super.key, required this.entry, required this.size});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = entry.imagePath;
    final hasImage = path != null && File(path).existsSync();

    return Hero(
      tag: 'meal-${entry.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: hasImage
              ? Image.file(File(path!), fit: BoxFit.cover)
              : ColoredBox(
            color: scheme.primaryContainer,
            child: Icon(
              iconForMealType(entry.mealType),
              size: size * 0.5,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}