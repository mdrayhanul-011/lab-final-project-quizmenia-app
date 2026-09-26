import 'quiz_question.dart';

/// Records the user's interaction with a specific quiz question.
class UserAnswer {
  final QuizQuestion question;
  final int questionIndex;
  final String? selectedAnswer; // null indicates skipped or unanswered
  final Duration timeSpent;

  const UserAnswer({
    required this.question,
    required this.questionIndex,
    this.selectedAnswer,
    this.timeSpent = Duration.zero,
  });

  /// True if the user selected any answer.
  bool get isAnswered => selectedAnswer != null && selectedAnswer!.trim().isNotEmpty;

  /// True if the question was skipped or time ran out without a selection.
  bool get isUnanswered => !isAnswered;

  /// True if the selected answer matches the question's correct answer.
  bool get isCorrect => isAnswered && question.checkAnswer(selectedAnswer);

  /// True if the user selected an answer, but it was incorrect.
  bool get isIncorrect => isAnswered && !isCorrect;

  /// The official correct answer string.
  String get correctAnswer => question.correctAnswer;

  UserAnswer copyWith({
    String? selectedAnswer,
    Duration? timeSpent,
  }) {
    return UserAnswer(
      question: question,
      questionIndex: questionIndex,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }

  @override
  String toString() =>
      'UserAnswer(Q${questionIndex + 1}: selected="$selectedAnswer", correct=$isCorrect)';
}
