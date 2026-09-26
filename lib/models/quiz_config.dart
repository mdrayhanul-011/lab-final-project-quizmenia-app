import 'trivia_category.dart';

/// Configuration options selected before starting a quiz.
class QuizConfig {
  final int amount;
  final TriviaCategory? category;
  final String? difficulty; // 'easy', 'medium', 'hard', or null for Any
  final String? type; // 'multiple', 'boolean', or null for Any
  final int timePerQuestionSeconds; // e.g., 15s, 30s, or 0 for unlimited

  const QuizConfig({
    this.amount = 10,
    this.category,
    this.difficulty,
    this.type,
    this.timePerQuestionSeconds = 0,
  });

  bool get isTimed => timePerQuestionSeconds > 0;

  QuizConfig copyWith({
    int? amount,
    TriviaCategory? category,
    bool clearCategory = false,
    String? difficulty,
    bool clearDifficulty = false,
    String? type,
    bool clearType = false,
    int? timePerQuestionSeconds,
  }) {
    return QuizConfig(
      amount: amount ?? this.amount,
      category: clearCategory ? null : (category ?? this.category),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      type: clearType ? null : (type ?? this.type),
      timePerQuestionSeconds:
          timePerQuestionSeconds ?? this.timePerQuestionSeconds,
    );
  }

  @override
  String toString() =>
      'QuizConfig(amount: $amount, category: ${category?.name}, difficulty: $difficulty, type: $type)';
}
