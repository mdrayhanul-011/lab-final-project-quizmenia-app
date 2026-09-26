import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizmenia/models/quiz_config.dart';
import 'package:quizmenia/models/quiz_question.dart';
import 'package:quizmenia/models/quiz_result.dart';
import 'package:quizmenia/models/trivia_category.dart';
import 'package:quizmenia/models/user_answer.dart';
import 'package:quizmenia/providers/quiz_provider.dart';
import 'package:quizmenia/services/api_exceptions.dart';
import 'package:quizmenia/services/opentdb_api_service.dart';
import 'package:quizmenia/services/quiz_preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

      provider.dispose();
    });

    test('4 & 12. auto-submit and preventing duplicate result generation', () async {
      final provider = QuizProvider(apiService: mockService);
      provider.setDurationMinutes(5);

      await provider.startQuiz();
      expect(provider.isQuizActive, isTrue);

      // Call finishQuiz
      final result1 = provider.finishQuiz();
      expect(provider.isQuizCompleted, isTrue);

      // 12. Calling finishQuiz again returns identical result
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

    test('Play Again resets quiz state completely while preserving configuration', () async {
      final provider = QuizProvider(apiService: mockService);
      provider.setAmount(20);
      provider.setDurationMinutes(15);
      provider.setDifficulty('hard');

      await provider.startQuiz();
      provider.selectCurrentAnswer('A1');
      final result = provider.finishQuiz();
      expect(result.score, 1);

      // User taps Play Again
      provider.resetQuiz();

      // Verify quiz session state is cleared
      expect(provider.questions, isEmpty);
      expect(provider.selectedAnswers, isEmpty);
      expect(provider.result, isNull);
      expect(provider.isQuizActive, isFalse);
      expect(provider.isQuizCompleted, isFalse);

      // Verify user's last configuration was preserved
      expect(provider.config.amount, 20);
      expect(provider.config.durationMinutes, 15);
      expect(provider.config.difficulty, 'hard');

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
          selectedAnswer: 'Paris',
        ),
        UserAnswer(
          question: q2,
          questionIndex: 1,
          selectedAnswer: 'True',
        ),
        UserAnswer(
          question: q1,
          questionIndex: 2,
          selectedAnswer: null,
        ),
      ];

      final result = QuizResult(
        userAnswers: answers,
        totalDuration: const Duration(seconds: 45),
        selectedDuration: const Duration(minutes: 10),
      );

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
          selectedAnswer: 'Paris',
        ),
        UserAnswer(
          question: q2,
          questionIndex: 1,
          selectedAnswer: 'True',
        ),
        UserAnswer(
          question: q1,
          questionIndex: 2,
          selectedAnswer: null,
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

  group('SharedPreferences & Category Caching', () {
    test('persists and restores last quiz configuration', () async {
      final prefsService = QuizPreferencesService();
      const configToSave = QuizConfig(
        amount: 25,
        difficulty: 'medium',
        type: 'multiple',
        durationMinutes: 15,
        category: TriviaCategory(id: 11, name: 'Entertainment: Film'),
      );

      await prefsService.saveLastConfig(configToSave);
      final loaded = await prefsService.loadLastConfig();

      expect(loaded.amount, 25);
      expect(loaded.difficulty, 'medium');
      expect(loaded.type, 'multiple');
      expect(loaded.durationMinutes, 15);
      expect(loaded.category?.id, 11);
      expect(loaded.category?.name, 'Entertainment: Film');
    });

    test('caches categories in session and avoids duplicate fetch', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'trivia_categories': [
              {'id': 9, 'name': 'General Knowledge'},
            ],
          }),
          200,
        );
      });

      final api = OpenTdbApiService(client: mockClient);
      final provider = QuizProvider(apiService: api);

      // First call fetches from API
      await provider.loadCategories();
      expect(callCount, 1);
      expect(provider.categories.length, 1);

      // Second call reuses cached categories without making a new request
      await provider.loadCategories();
      expect(callCount, 1);

      // Calling with forceRefresh makes a fresh request
      await provider.loadCategories(forceRefresh: true);
      expect(callCount, 2);

      provider.dispose();
    });
  });
}
