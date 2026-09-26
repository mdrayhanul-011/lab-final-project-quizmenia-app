import 'user_answer.dart';

/// Aggregated result of a completed quiz session.
class QuizResult {
  final List<UserAnswer> userAnswers;
  final Duration totalDuration; // Total elapsed time used
  final Duration selectedDuration; // Configured quiz timer duration
  final DateTime completedAt;
  final String? categoryTitle;
  final String? difficulty;

  QuizResult({
    required this.userAnswers,
    required this.totalDuration,
    this.selectedDuration = const Duration(minutes: 10),
    DateTime? completedAt,
    this.categoryTitle,
    this.difficulty,
  }) : completedAt = completedAt ?? DateTime.now();

  int get totalQuestions => userAnswers.length;

  /// Number of correctly answered questions.
  int get score => userAnswers.where((a) => a.isCorrect).length;

  /// Number of answered questions.
  int get answeredCount => userAnswers.where((a) => a.isAnswered).length;

  /// Number of incorrectly answered questions.
  int get incorrectCount => userAnswers.where((a) => a.isIncorrect).length;

  /// Number of unanswered/skipped questions.
  int get unansweredCount => userAnswers.where((a) => a.isUnanswered).length;

  /// Score / accuracy percentage (0.0 to 100.0).
  double get scorePercentage =>
      totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;

  double get accuracy => scorePercentage;

  /// Filtered list of correctly answered questions for review.
  List<UserAnswer> get correctAnswers =>
      userAnswers.where((a) => a.isCorrect).toList();

  /// Filtered list of incorrectly answered questions for review.
  List<UserAnswer> get incorrectAnswers =>
      userAnswers.where((a) => a.isIncorrect).toList();

  /// Filtered list of unanswered questions for review.
  List<UserAnswer> get unansweredQuestions =>
      userAnswers.where((a) => a.isUnanswered).toList();

  /// Formatted elapsed duration string (e.g. "01:45" or "45s")
  String get formattedDuration {
    final minutes = totalDuration.inMinutes;
    final seconds = totalDuration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  /// Formatted selected duration string (e.g. "10:00")
  String get formattedSelectedDuration {
    final minutes = selectedDuration.inMinutes;
    final seconds = selectedDuration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'QuizResult(score: $score/$totalQuestions (${scorePercentage.toStringAsFixed(1)}%), duration: $formattedDuration)';
}
