import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/trivia_category.dart';

class CategoryVisualData {
  final String imagePath;
  final Color backgroundColor;

  const CategoryVisualData({
    required this.imagePath,
    required this.backgroundColor,
  });
}

class CategoryAssetHelper {
  /// OpenTDB category IDs for the 16 curated categories
  static const Set<int> supportedCategoryIds = {
    9, // General Knowledge
    10, // Entertainment: Books
    11, // Entertainment: Film
    17, // Science & Nature
    18, // Science: Computers
    19, // Science: Mathematics
    20, // Mythology
    21, // Sports
    22, // Geography
    23, // History
    24, // Politics
    25, // Art
    27, // Animals
    28, // Vehicles
    30, // Science: Gadgets
    32, // Entertainment: Cartoon & Animations
  };

  /// Normalizes a category name to a canonical key for the 16 supported categories.
  /// Handles prefixes (e.g. "Entertainment: ", "Science: ") and naming variations
  /// (e.g. "Animals" vs "Animal", "Cartoon & Animations" vs "Cartoons").
  static String? normalizeCategoryKey(String categoryName) {
    var cleaned = categoryName.trim().toLowerCase();
    if (cleaned.contains(':')) {
      cleaned = cleaned.split(':').last.trim();
    }

    if (cleaned == 'general knowledge' || cleaned.contains('general knowledge')) {
      return 'general_knowledge';
    }
    if (cleaned == 'books' || cleaned == 'book' || cleaned.contains('book')) {
      return 'books';
    }
    if (cleaned == 'film' || cleaned == 'films' || cleaned.contains('film')) {
      return 'film';
    }
    if (cleaned == 'science & nature' ||
        cleaned == 'science and nature' ||
        cleaned.contains('science & nature') ||
        cleaned.contains('science and nature')) {
      return 'science_nature';
    }
    if (cleaned == 'computers' || cleaned == 'computer' || cleaned.contains('computer')) {
      return 'computers';
    }
    if (cleaned == 'mathematics' ||
        cleaned == 'math' ||
        cleaned == 'maths' ||
        cleaned.contains('mathematics') ||
        cleaned.contains('math')) {
      return 'mathematics';
    }
    if (cleaned == 'mythology' || cleaned == 'myth' || cleaned.contains('myth')) {
      return 'mythology';
    }
    if (cleaned == 'sports' || cleaned == 'sport' || cleaned.contains('sport')) {
      return 'sports';
    }
    if (cleaned == 'geography' || cleaned.contains('geography')) {
      return 'geography';
    }
    if (cleaned == 'history' || cleaned.contains('history')) {
      return 'history';
    }
    if (cleaned == 'politics' || cleaned == 'politic' || cleaned.contains('politic')) {
      return 'politics';
    }
    if (cleaned == 'cartoons' ||
        cleaned == 'cartoon' ||
        cleaned == 'cartoon & animations' ||
        cleaned == 'cartoons & animations' ||
        cleaned == 'cartoon and animations' ||
        cleaned.contains('cartoon') ||
        cleaned.contains('animation')) {
      return 'cartoons';
    }
    if (cleaned == 'art' || cleaned == 'arts') {
      return 'art';
    }
    if (cleaned == 'animals' || cleaned == 'animal' || cleaned.contains('animal')) {
      return 'animals';
    }
    if (cleaned == 'vehicles' || cleaned == 'vehicle' || cleaned.contains('vehicle')) {
      return 'vehicles';
    }
    if (cleaned == 'gadgets' || cleaned == 'gadget' || cleaned.contains('gadget')) {
      return 'gadgets';
    }

    return null;
  }

  /// Checks if a trivia category is one of the 16 supported categories.
  static bool isSupportedCategory(TriviaCategory category) {
    if (supportedCategoryIds.contains(category.id)) {
      return true;
    }
    return isSupported(category.name) || isSupported(category.displayName);
  }

  /// Checks if a category name belongs to the 16 supported categories.
  static bool isSupported(String categoryName) {
    return normalizeCategoryKey(categoryName) != null;
  }

  /// Returns the corresponding visual data (image path & background color)
  /// for a category name, respecting exact existing file extensions (.jpg / .png).
  static CategoryVisualData getVisualData(String categoryName) {
    final key = normalizeCategoryKey(categoryName);

    switch (key) {
      case 'general_knowledge':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_general_knowledge.png',
          backgroundColor: AppColors.catGeneralKnowledge,
        );
      case 'books':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_books.png',
          backgroundColor: AppColors.catBooks,
        );
      case 'film':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_film.jpg',
          backgroundColor: AppColors.catEntertainment,
        );
      case 'science_nature':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_science.png',
          backgroundColor: AppColors.catScience,
        );
      case 'computers':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_computers.jpg',
          backgroundColor: AppColors.catScience,
        );
      case 'mathematics':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_mathematics.jpg',
          backgroundColor: AppColors.catScience,
        );
      case 'mythology':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_mythology.jpg',
          backgroundColor: AppColors.catGeneralKnowledge,
        );
      case 'sports':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_sports.jpg',
          backgroundColor: AppColors.catGeography,
        );
      case 'geography':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_geography.jpg',
          backgroundColor: AppColors.catGeography,
        );
      case 'history':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_history.png',
          backgroundColor: AppColors.catHistory,
        );
      case 'politics':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_politics.jpg',
          backgroundColor: AppColors.catGeography,
        );
      case 'art':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_art.png',
          backgroundColor: AppColors.catArt,
        );
      case 'animals':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_animals.jpg',
          backgroundColor: AppColors.catGeography,
        );
      case 'vehicles':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_vehicles.png',
          backgroundColor: AppColors.catVehicles,
        );
      case 'gadgets':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_gadgets.jpg',
          backgroundColor: AppColors.catScience,
        );
      case 'cartoons':
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_cartoons.jpg',
          backgroundColor: AppColors.catEntertainment,
        );
      default:
        return const CategoryVisualData(
          imagePath: 'assets/images/cat_general_knowledge.png',
          backgroundColor: AppColors.catGeneralKnowledge,
        );
    }
  }
}