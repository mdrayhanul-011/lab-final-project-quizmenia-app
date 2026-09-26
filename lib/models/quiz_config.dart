import 'trivia_category.dart';

/// Configuration options selected before starting a quiz.
class QuizConfig {
  final int amount;
  final TriviaCategory? category;
  final String? difficulty; // 'easy', 'medium', 'hard', or null for Any
  final String? type; // 'multiple', 'boolean', or null for Any

  /// Overall quiz countdown timer duration in minutes (e.g. 10 minutes).
  /// This single timer runs across all questions.
  final int durationMinutes;

  const QuizConfig({
    this.amount = 10,
    this.category,
    this.difficulty,
    this.type,
    this.durationMinutes = 10,
  });

  /// Total duration as a [Duration] object.
  Duration get totalDuration => Duration(minutes: durationMinutes);

  /// Total duration in seconds.
  int get totalDurationSeconds => durationMinutes * 60;

  QuizConfig copyWith({
    int? amount,
    TriviaCategory? category,
    bool clearCategory = false,
    String? difficulty,
    bool clearDifficulty = false,
    String? type,
    bool clearType = false,
    int? durationMinutes,
  }) {
    return QuizConfig(
      amount: amount ?? this.amount,
      category: clearCategory ? null : (category ?? this.category),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      type: clearType ? null : (type ?? this.type),
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  String toString() =>
      'QuizConfig(amount: $amount, category: ${category?.name}, difficulty: $difficulty, type: $type, durationMinutes: $durationMinutes)';
}
