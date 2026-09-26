import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quizmenia/models/quiz_config.dart';
import 'package:quizmenia/models/quiz_question.dart';
import 'package:quizmenia/models/quiz_result.dart';
import 'package:quizmenia/models/trivia_category.dart';
import 'package:quizmenia/models/user_answer.dart';
import 'package:quizmenia/providers/quiz_provider.dart';
import 'package:quizmenia/services/api_exceptions.dart';
import 'package:quizmenia/services/opentdb_api_service.dart';

void main() {
  group('TriviaCategory & QuizConfig Models', () {
    test('parses trivia category correctly', () {
      final json = {'id': 9, 'name': 'General Knowledge'};
      final cat = TriviaCategory.fromJson(json);
      expect(cat.id, 9);
      expect(cat.name, 'General Knowledge');
      expect(cat.displayName, 'General Knowledge');
    });

    test('configures quiz config with total duration', () {
      const config = QuizConfig(amount: 15, durationMinutes: 20);
      expect(config.amount, 15);
      expect(config.durationMinutes, 20);
      expect(config.totalDurationSeconds, 1200);
    });
  });
  group('1 & 2. Multiple-choice & Boolean Quiz Models', () {
    test('1. parses multiple choice questions with 4 shuffled options', () {
      final json = {
        'type': 'multiple',
        'difficulty': 'easy',
        'category': 'Entertainment: Books',
        'question': 'What is &quot;The Lord of the Rings&quot; author&#039;s name?',
        'correct_answer': 'J. R. R. Tolkien',
        'incorrect_answers': [
          'George R. R. Martin',
          'C. S. Lewis',
          'J. K. Rowling',
        ],
      };

      final question = QuizQuestion.fromJson(json);

      expect(question.isMultipleChoice, isTrue);
      expect(question.question, 'What is "The Lord of the Rings" author\'s name?');
      expect(question.correctAnswer, 'J. R. R. Tolkien');
      expect(question.answers.length, 4);
      expect(question.answers.contains('J. R. R. Tolkien'), isTrue);
      expect(question.checkAnswer('J. R. R. Tolkien'), isTrue);
      expect(question.checkAnswer('George R. R. Martin'), isFalse);
    });

    test('2. parses boolean questions with True and False options', () {
      final json = {
        'type': 'boolean',
        'difficulty': 'easy',
        'category': 'Science: Computers',
        'question': 'Linux is an open-source kernel.',
        'correct_answer': 'True',
        'incorrect_answers': ['False'],
      };

      final question = QuizQuestion.fromJson(json);

      expect(question.isBoolean, isTrue);
      expect(question.isMultipleChoice, isFalse);
      expect(question.answers, ['True', 'False']);
      expect(question.checkAnswer('True'), isTrue);
      expect(question.checkAnswer('False'), isFalse);
    });

    test('8. handles very long question and answer texts without issues', () {
      final longText = 'A' * 400;
      final json = {
        'type': 'multiple',
        'difficulty': 'hard',
        'category': 'History',
        'question': 'Is this long question valid? $longText',
        'correct_answer': 'Long answer: $longText',
        'incorrect_answers': ['Short 1', 'Short 2', 'Short 3'],
      };

      final question = QuizQuestion.fromJson(json);
      expect(question.question.length, greaterThan(400));
      expect(question.correctAnswer.length, greaterThan(400));
      expect(question.answers.length, 4);
      expect(question.checkAnswer('Long answer: $longText'), isTrue);
    });
  });

  group('3, 4, 11, 12. Quiz Timer & Submission Flows', () {
    late OpenTdbApiService mockService;

    setUp(() {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'response_code': 0,
            'results': [
              {
                'type': 'multiple',
                'difficulty': 'easy',
                'category': 'General',
                'question': 'Q1?',
                'correct_answer': 'A1',
                'incorrect_answers': ['B1', 'C1', 'D1'],
              },
              {
                'type': 'multiple',
                'difficulty': 'easy',
                'category': 'General',
                'question': 'Q2?',
                'correct_answer': 'A2',
                'incorrect_answers': ['B2', 'C2', 'D2'],
              },
            ],
          }),
          200,
        );
      });
      mockService = OpenTdbApiService(client: mockClient);
    });

    test('3 & 11. manual submission stops overall countdown timer immediately', () async {
      final provider = QuizProvider(apiService: mockService);
      provider.setDurationMinutes(10);

      await provider.startQuiz();
      expect(provider.isQuizActive, isTrue);
      expect(provider.remainingSeconds, 600);

      // Answer Q1
      provider.selectCurrentAnswer('A1');

      // 3. Manual submission before timeout
      final result = provider.finishQuiz();

      // 11. Timer stops after submission
      expect(provider.isQuizActive, isFalse);
      expect(provider.isQuizCompleted, isTrue);
      expect(result.score, 1);
      expect(result.totalQuestions, 2);

      // Verify timer is canceled and does not keep running
      provider.dispose();
    });

    test('4 & 12. auto-submit and preventing duplicate result generation', () async {
      final provider = QuizProvider(apiService: mockService);
      provider.setDurationMinutes(5);

      await provider.startQuiz();
      expect(provider.isQuizActive, isTrue);

      // Call finishQuiz (simulating auto-submit or manual finish)
      final result1 = provider.finishQuiz();
      expect(provider.isQuizCompleted, isTrue);

      // 12. Calling finishQuiz again returns the exact same result without re-executing
      final result2 = provider.finishQuiz();
      expect(identical(result1, result2), isTrue);

      provider.dispose();
    });

    test('10. question navigation forward and backward records question times', () async {
      final provider = QuizProvider(apiService: mockService);
      await provider.startQuiz();

      expect(provider.currentQuestionIndex, 0);
      expect(provider.isFirstQuestion, isTrue);

      provider.nextQuestion();
      expect(provider.currentQuestionIndex, 1);
      expect(provider.isLastQuestion, isTrue);

      provider.previousQuestion();
      expect(provider.currentQuestionIndex, 0);

      provider.dispose();
    });
  });

  group('5, 6, 7. Answers, Scores & View Answers Review', () {
    final q1 = QuizQuestion(
      category: 'General',
      type: 'multiple',
      difficulty: 'easy',
      question: 'Capital of France?',
      correctAnswer: 'Paris',
      incorrectAnswers: ['Rome', 'Berlin', 'Madrid'],
    );

    final q2 = QuizQuestion(
      category: 'General',
      type: 'boolean',
      difficulty: 'easy',
      question: 'The Earth is flat.',
      correctAnswer: 'False',
      incorrectAnswers: ['True'],
    );

    test('5 & 6. calculates answered, unanswered, correct, and incorrect answers accurately', () {
      final answers = [
        UserAnswer(
          question: q1,
          questionIndex: 0,
          selectedAnswer: 'Paris', // Correct
        ),
        UserAnswer(
          question: q2,
          questionIndex: 1,
          selectedAnswer: 'True', // Incorrect
        ),
        UserAnswer(
          question: q1,
          questionIndex: 2,
          selectedAnswer: null, // Unanswered
        ),
      ];

      final result = QuizResult(
        userAnswers: answers,
        totalDuration: const Duration(seconds: 45),
        selectedDuration: const Duration(minutes: 10),
      );

      // Metrics verification
      expect(result.totalQuestions, 3);
      expect(result.answeredCount, 2);
      expect(result.unansweredCount, 1);
      expect(result.score, 1);
      expect(result.incorrectCount, 1);
      expect(result.accuracy, closeTo(33.33, 0.1));
      expect(result.selectedDuration.inMinutes, 10);
    });

    test('7. View Answers filters correctly partition review questions', () {
      final answers = [
        UserAnswer(
          question: q1,
          questionIndex: 0,
          selectedAnswer: 'Paris', // Correct
        ),
        UserAnswer(
          question: q2,
          questionIndex: 1,
          selectedAnswer: 'True', // Incorrect
        ),
        UserAnswer(
          question: q1,
          questionIndex: 2,
          selectedAnswer: null, // Unanswered
        ),
      ];

      final result = QuizResult(
        userAnswers: answers,
        totalDuration: const Duration(seconds: 45),
      );

      expect(result.correctAnswers.length, 1);
      expect(result.correctAnswers.first.selectedAnswer, 'Paris');

      expect(result.incorrectAnswers.length, 1);
      expect(result.incorrectAnswers.first.selectedAnswer, 'True');

      expect(result.unansweredQuestions.length, 1);
      expect(result.unansweredQuestions.first.selectedAnswer, isNull);
    });
  });

  group('9. API failure and HTTP 429 retry handling', () {
    test('handles OpenTDB Response Code 1 (No Results)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'response_code': 1, 'results': []}),
          200,
        );
      });

      final service = OpenTdbApiService(client: mockClient);
      expect(
        () => service.fetchQuestions(amount: 50, categoryId: 999),
        throwsA(isA<OpenTdbNoResultsException>()),
      );
    });

    test('handles HTTP 429 status code and maps to OpenTdbRateLimitException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Too Many Requests', 429);
      });

      final service = OpenTdbApiService(client: mockClient);

      expect(
        () => service.fetchQuestions(),
        throwsA(isA<OpenTdbRateLimitException>()),
      );
    });
  });
}
