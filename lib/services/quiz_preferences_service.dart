import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_config.dart';
import '../models/trivia_category.dart';

/// Service responsible for preserving the user's last quiz configuration
/// using SharedPreferences.
class QuizPreferencesService {
  static const String _keyAmount = 'last_quiz_amount';
  static const String _keyCategoryId = 'last_quiz_category_id';
  static const String _keyCategoryName = 'last_quiz_category_name';
  static const String _keyDifficulty = 'last_quiz_difficulty';
  static const String _keyType = 'last_quiz_type';
  static const String _keyDurationMinutes = 'last_quiz_duration_minutes';

  final SharedPreferences? _prefs;

  QuizPreferencesService([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Saves the last quiz configuration (amount, category, difficulty, type, duration).
  Future<void> saveLastConfig(QuizConfig config) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setInt(_keyAmount, config.amount);
      await prefs.setInt(_keyDurationMinutes, config.durationMinutes);

      if (config.category != null) {
        await prefs.setInt(_keyCategoryId, config.category!.id);
        await prefs.setString(_keyCategoryName, config.category!.name);
      } else {
        await prefs.remove(_keyCategoryId);
        await prefs.remove(_keyCategoryName);
      }

      if (config.difficulty != null && config.difficulty!.isNotEmpty) {
        await prefs.setString(_keyDifficulty, config.difficulty!);
      } else {
        await prefs.remove(_keyDifficulty);
      }

      if (config.type != null && config.type!.isNotEmpty) {
        await prefs.setString(_keyType, config.type!);
      } else {
        await prefs.remove(_keyType);
      }
    } catch (_) {
      // Graceful fallback if storage fails
    }
  }

  /// Loads the preserved last quiz configuration, or returns defaults if none saved.
  Future<QuizConfig> loadLastConfig({List<TriviaCategory>? availableCategories}) async {
    try {
      final prefs = await _getPrefs();
      final amount = prefs.getInt(_keyAmount) ?? 10;
      final duration = prefs.getInt(_keyDurationMinutes) ?? 10;
      final categoryId = prefs.getInt(_keyCategoryId);
      final categoryName = prefs.getString(_keyCategoryName);
      final difficulty = prefs.getString(_keyDifficulty);
      final type = prefs.getString(_keyType);

      TriviaCategory? category;
      if (categoryId != null && categoryName != null) {
        if (availableCategories != null && availableCategories.isNotEmpty) {
          category = availableCategories.firstWhere(
            (c) => c.id == categoryId,
            orElse: () => TriviaCategory(id: categoryId, name: categoryName),
          );
        } else {
          category = TriviaCategory(id: categoryId, name: categoryName);
        }
      }

      return QuizConfig(
        amount: amount,
        category: category,
        difficulty: difficulty,
        type: type,
        durationMinutes: duration,
      );
    } catch (_) {
      return const QuizConfig();
    }
  }
}
