import 'dart:math';
import 'package:html_unescape/html_unescape.dart';

/// Represents a single quiz question fetched from OpenTDB.
class QuizQuestion {
  final String category;
  final String type; // 'multiple' or 'boolean'
  final String difficulty; // 'easy', 'medium', 'hard'
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;

  /// Shuffled list of all available options for the user to choose from.
  /// Preserves options in a stable order once initialized for this question.
  final List<String> answers;

  QuizQuestion({
    required this.category,
    required this.type,
    required this.difficulty,
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
    List<String>? answers,
    Random? random,
  }) : answers = answers ?? _buildShuffledAnswers(correctAnswer, incorrectAnswers, type, random);

  bool get isMultipleChoice => type == 'multiple';
  bool get isBoolean => type == 'boolean';

  /// Validates whether a provided user answer matches the preserved correct answer.
  bool checkAnswer(String? answer) {
    if (answer == null) return false;
    return answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }

  /// Deserializes OpenTDB question JSON, unescapes all HTML entities,
  /// and produces shuffled answer choices.
  factory QuizQuestion.fromJson(
    Map<String, dynamic> json, {
    HtmlUnescape? unescape,
    Random? random,
  }) {
    final unescaper = unescape ?? HtmlUnescape();

    final rawQuestion = json['question'] as String? ?? '';
    final rawCorrect = json['correct_answer'] as String? ?? '';
    final rawIncorrectList = (json['incorrect_answers'] as List<dynamic>?) ?? [];

    final cleanQuestion = unescaper.convert(rawQuestion).trim();
    final cleanCorrect = unescaper.convert(rawCorrect).trim();
    final cleanIncorrect = rawIncorrectList
        .map((item) => unescaper.convert(item.toString()).trim())
        .toList();

    final type = (json['type'] as String? ?? 'multiple').toLowerCase();
    final difficulty = (json['difficulty'] as String? ?? 'easy').toLowerCase();
    final category = unescaper.convert(json['category'] as String? ?? '').trim();

    return QuizQuestion(
      category: category,
      type: type,
      difficulty: difficulty,
      question: cleanQuestion,
      correctAnswer: cleanCorrect,
      incorrectAnswers: cleanIncorrect,
      random: random,
    );
  }

  /// Generates the answer list.
  /// For boolean: options are strictly ["True", "False"] in consistent format.
  /// For multiple choice: includes 1 correct answer and 3 incorrect answers, shuffled.
  static List<String> _buildShuffledAnswers(
    String correct,
    List<String> incorrect,
    String type,
    Random? random,
  ) {
    if (type.toLowerCase() == 'boolean') {
      // For boolean true/false questions, maintain standard True/False presentation
      return const ['True', 'False'];
    }

    final combined = <String>[correct, ...incorrect];
    combined.shuffle(random ?? Random());
    return List.unmodifiable(combined);
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'type': type,
      'difficulty': difficulty,
      'question': question,
      'correct_answer': correctAnswer,
      'incorrect_answers': incorrectAnswers,
      'answers': answers,
    };
  }

  @override
  String toString() => 'QuizQuestion(type: $type, question: $question, correct: $correctAnswer)';
}
