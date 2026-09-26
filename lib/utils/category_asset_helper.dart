import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CategoryVisualData {
  final String imagePath;
  final Color backgroundColor;

  const CategoryVisualData({
    required this.imagePath,
    required this.backgroundColor,
  });
}

/// Helper that pairs trivia categories with their authentic illustration
/// and pastel card color from App_Screen.pdf.
class CategoryAssetHelper {
  static CategoryVisualData getVisualData(String categoryName) {
    final lower = categoryName.toLowerCase();

    if (lower.contains('general')) {
      return const CategoryVisualData(
        imagePath: 'assets/images/cat_general_knowledge.png',
        backgroundColor: AppColors.catGeneralKnowledge,
      );
    } else if (lower.contains('book')) {
      return const CategoryVisualData(
        imagePath: 'assets/images/cat_books.png',
        backgroundColor: AppColors.catBooks,
      );
    } else if (lower.contains('history')) {
      return const CategoryVisualData(
        imagePath: 'assets/images/cat_history.png',
        backgroundColor: AppColors.catHistory,
      );
    } else if (lower.contains('science') || lower.contains('nature') || lower.contains('math') || lower.contains('gadget') || lower.contains('computer')) {
      return const CategoryVisualData(
        imagePath: 'assets/images/cat_science.png',
        backgroundColor: AppColors.catScience,
      );
    } else if (lower.contains('art') || lower.contains('theatre') || lower.contains('musical')) {
      return const CategoryVisualData(
        imagePath: 'assets/images/cat_art.png',
        backgroundColor: AppColors.catArt,
      );
    } else if (lower.contains('vehicle')) {
      return const CategoryVisualData(
        imagePath: 'assets/images/cat_vehicles.png',
        backgroundColor: AppColors.catVehicles,
      );
    } else if (lower.contains('film') || lower.contains('music') || lower.contains('television') || lower.contains('video') || lower.contains('board') || lower.contains('anime') || lower.contains('cartoon') || lower.contains('comic')) {
      return const CategoryVisualData(
        imagePath: 'assets/images/cat_art.png',
        backgroundColor: AppColors.catEntertainment,
      );
    } else if (lower.contains('geography') || lower.contains('myth') || lower.contains('sport') || lower.contains('politic') || lower.contains('celebrities') || lower.contains('animal')) {
      return const CategoryVisualData(
        imagePath: 'assets/images/cat_general_knowledge.png',
        backgroundColor: AppColors.catGeography,
      );
    }

    // Default fallback
    return const CategoryVisualData(
      imagePath: 'assets/images/cat_general_knowledge.png',
      backgroundColor: AppColors.catGeneralKnowledge,
    );
  }
}
