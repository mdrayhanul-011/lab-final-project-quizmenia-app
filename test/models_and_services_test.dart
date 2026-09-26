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
  group('TriviaCategory Model', () {
    test('parses json correctly and handles prefixes', () {
      final json = {'id': 11, 'name': 'Entertainment: Film'};
      final category = TriviaCategory.fromJson(json);

      expect(category.id, 11);
      expect(category.name, 'Entertainment: Film');
      expect(category.displayName, 'Film');
      expect(category.group, 'Entertainment');
    });

    test('handles category without prefix', () {
      final json = {'id': 9, 'name': 'General Knowledge'};
      final category = TriviaCategory.fromJson(json);

      expect(category.id, 9);
      expect(category.displayName, 'General Knowledge');
      expect(category.group, 'General');
    });
  });

  group('QuizQuestion Model', () {
    test('unescapes HTML entities in question and answers', () {
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

      expect(question.question, 'What is "The Lord of the Rings" author\'s name?');
      expect(question.correctAnswer, 'J. R. R. Tolkien');
      expect(question.answers.length, 4);
      expect(question.answers.contains('J. R. R. Tolkien'), isTrue);
      expect(question.checkAnswer('J. R. R. Tolkien'), isTrue);
      expect(question.checkAnswer('George R. R. Martin'), isFalse);
    });

    test('handles boolean questions with True and False options', () {
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
  });

  group('UserAnswer & QuizResult Data Structures', () {
    final sampleQuestion = QuizQuestion(
      category: 'General',
      type: 'multiple',
      difficulty: 'easy',
      question: 'Capital of France?',
      correctAnswer: 'Paris',
      incorrectAnswers: ['Rome', 'Berlin', 'Madrid'],
    );

    test('correctly identifies answered vs unanswered and correctness', () {
      final answeredCorrect = UserAnswer(
        question: sampleQuestion,
        questionIndex: 0,
        selectedAnswer: 'Paris',
      );
      expect(answeredCorrect.isAnswered, isTrue);
      expect(answeredCorrect.isUnanswered, isFalse);
      expect(answeredCorrect.isCorrect, isTrue);

      final answeredWrong = UserAnswer(
        question: sampleQuestion,
        questionIndex: 1,
        selectedAnswer: 'Rome',
      );
      expect(answeredWrong.isCorrect, isFalse);
      expect(answeredWrong.isIncorrect, isTrue);

      final unanswered = UserAnswer(
        question: sampleQuestion,
        questionIndex: 2,
        selectedAnswer: null,
      );
      expect(unanswered.isAnswered, isFalse);
      expect(unanswered.isUnanswered, isTrue);
      expect(unanswered.isCorrect, isFalse);
    });

    test('QuizResult aggregates metrics correctly', () {
      final answers = [
        UserAnswer(
          question: sampleQuestion,
          questionIndex: 0,
          selectedAnswer: 'Paris',
        ),
        UserAnswer(
          question: sampleQuestion,
          questionIndex: 1,
          selectedAnswer: 'Berlin',
        ),
        UserAnswer(
          question: sampleQuestion,
          questionIndex: 2,
          selectedAnswer: null,
        ),
      ];

      final result = QuizResult(
        userAnswers: answers,
        totalDuration: const Duration(seconds: 75),
      );

      expect(result.totalQuestions, 3);
      expect(result.score, 1);
      expect(result.incorrectCount, 1);
      expect(result.unansweredCount, 1);
      expect(result.scorePercentage, closeTo(33.33, 0.1));
      expect(result.formattedDuration, '01:15');
      expect(result.correctAnswers.length, 1);
      expect(result.incorrectAnswers.length, 1);
      expect(result.unansweredQuestions.length, 1);
    });
  });

  group('OpenTdbApiService', () {
    test('fetches categories successfully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'trivia_categories': [
              {'id': 9, 'name': 'General Knowledge'},
              {'id': 10, 'name': 'Entertainment: Books'},
            ],
          }),
          200,
        );
      });

      final service = OpenTdbApiService(client: mockClient);
      final categories = await service.fetchCategories();

      expect(categories.length, 2);
      expect(categories.any((c) => c.id == 9), isTrue);
    });

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

    test('handles OpenTDB Response Code 5 (Rate Limit)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'response_code': 5, 'results': []}),
          200,
        );
      });

      final service = OpenTdbApiService(client: mockClient);
      expect(
        () => service.fetchQuestions(),
        throwsA(isA<OpenTdbRateLimitException>()),
      );
    });
  });

  group('QuizProvider', () {
    test('updates configuration correctly', () {
      const initialConfig = QuizConfig(amount: 5);
      final updated = initialConfig.copyWith(amount: 20, difficulty: 'medium');
      expect(updated.amount, 20);
      expect(updated.difficulty, 'medium');

      final provider = QuizProvider();
      provider.setAmount(15);
      provider.setDifficulty('hard');
      provider.setType('multiple');

      expect(provider.config.amount, 15);
      expect(provider.config.difficulty, 'hard');
      expect(provider.config.type, 'multiple');
    });

    test('answers questions, navigates and finishes quiz', () async {
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
                'type': 'boolean',
                'difficulty': 'easy',
                'category': 'General',
                'question': 'Q2?',
                'correct_answer': 'True',
                'incorrect_answers': ['False'],
              },
            ],
          }),
          200,
        );
      });

      final service = OpenTdbApiService(client: mockClient);
      final provider = QuizProvider(apiService: service);

      final success = await provider.startQuiz();
      expect(success, isTrue);
      expect(provider.totalQuestions, 2);
      expect(provider.isQuizActive, isTrue);

      // Answer Q1
      provider.selectCurrentAnswer('A1');
      expect(provider.isCurrentAnswered, isTrue);
      expect(provider.currentSelectedAnswer, 'A1');

      // Next
      provider.nextQuestion();
      expect(provider.currentQuestionIndex, 1);
      expect(provider.isLastQuestion, isTrue);

      // Finish quiz without answering Q2
      final result = provider.finishQuiz();
      expect(result.totalQuestions, 2);
      expect(result.score, 1);
      expect(result.unansweredCount, 1);
      expect(provider.isQuizActive, isFalse);
      expect(provider.isQuizCompleted, isTrue);
    });
  });
}
