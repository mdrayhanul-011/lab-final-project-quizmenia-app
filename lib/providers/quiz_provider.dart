import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/quiz_config.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../models/trivia_category.dart';
import '../models/user_answer.dart';
import '../services/api_exceptions.dart';
import '../services/opentdb_api_service.dart';

/// Central state management for Quizmenia using Provider.
/// Handles category discovery, quiz configuration, question lifecycle,
/// user answers, timing, and result generation.
class QuizProvider with ChangeNotifier {
  final OpenTdbApiService _apiService;

  QuizProvider({OpenTdbApiService? apiService})
      : _apiService = apiService ?? OpenTdbApiService();

  // ---------------------------------------------------------------------------
  // Categories State
  // ---------------------------------------------------------------------------
  List<TriviaCategory> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;

  List<TriviaCategory> get categories => List.unmodifiable(_categories);
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;
  bool get hasCategories => _categories.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Quiz Configuration State
  // ---------------------------------------------------------------------------
  QuizConfig _config = const QuizConfig();
  QuizConfig get config => _config;

  void setAmount(int amount) {
    _config = _config.copyWith(amount: amount.clamp(1, 50));
    notifyListeners();
  }

  void setCategory(TriviaCategory? category) {
    if (category == null) {
      _config = _config.copyWith(clearCategory: true);
    } else {
      _config = _config.copyWith(category: category);
    }
    notifyListeners();
  }

  void setDifficulty(String? difficulty) {
    if (difficulty == null || difficulty.isEmpty || difficulty.toLowerCase() == 'any') {
      _config = _config.copyWith(clearDifficulty: true);
    } else {
      _config = _config.copyWith(difficulty: difficulty);
    }
    notifyListeners();
  }

  void setType(String? type) {
    if (type == null || type.isEmpty || type.toLowerCase() == 'any') {
      _config = _config.copyWith(clearType: true);
    } else {
      _config = _config.copyWith(type: type);
    }
    notifyListeners();
  }

  void setTimePerQuestion(int seconds) {
    _config = _config.copyWith(timePerQuestionSeconds: seconds);
    notifyListeners();
  }

  void updateConfig(QuizConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Active Quiz State
  // ---------------------------------------------------------------------------
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {}; // questionIndex -> selectedAnswer
  final Stopwatch _stopwatch = Stopwatch();

  bool _isLoadingQuestions = false;
  String? _quizError;
  bool _isQuizActive = false;
  bool _isQuizCompleted = false;

  QuizResult? _result;

  List<QuizQuestion> get questions => List.unmodifiable(_questions);
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, String> get selectedAnswers => Map.unmodifiable(_selectedAnswers);
  bool get isLoadingQuestions => _isLoadingQuestions;
  String? get quizError => _quizError;
  bool get isQuizActive => _isQuizActive;
  bool get isQuizCompleted => _isQuizCompleted;
  QuizResult? get result => _result;

  int get totalQuestions => _questions.length;
  bool get hasQuestions => _questions.isNotEmpty;
  bool get isFirstQuestion => _currentQuestionIndex == 0;
  bool get isLastQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex == _questions.length - 1;

  QuizQuestion? get currentQuestion {
    if (_questions.isEmpty ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentQuestionIndex];
  }

  String? get currentSelectedAnswer => _selectedAnswers[_currentQuestionIndex];
  bool get isCurrentAnswered => _selectedAnswers.containsKey(_currentQuestionIndex);

  int get answeredCount => _selectedAnswers.length;
  int get unansweredCount =>
      _questions.isEmpty ? 0 : _questions.length - _selectedAnswers.length;

  Duration get elapsedTime => _stopwatch.elapsed;

  // ---------------------------------------------------------------------------
  // Actions: Categories
  // ---------------------------------------------------------------------------

  /// Loads trivia categories from OpenTDB. Caches results once loaded.
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (_categories.isNotEmpty && !forceRefresh) return;

    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();

    try {
      _categories = await _apiService.fetchCategories();
      _categoriesError = null;
    } on ApiException catch (e) {
      _categoriesError = e.message;
    } catch (e) {
      _categoriesError = 'Failed to load categories. Please try again.';
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Actions: Quiz Lifecycle
  // ---------------------------------------------------------------------------

  /// Fetches questions using current configuration and begins a new quiz session.
  Future<bool> startQuiz() async {
    _isLoadingQuestions = true;
    _quizError = null;
    _isQuizActive = false;
    _isQuizCompleted = false;
    _result = null;
    _selectedAnswers.clear();
    _currentQuestionIndex = 0;
    _stopwatch.reset();
    notifyListeners();

    try {
      final fetchedQuestions = await _apiService.fetchQuestions(
        amount: _config.amount,
        categoryId: _config.category?.id,
        difficulty: _config.difficulty,
        type: _config.type,
      );

      if (fetchedQuestions.isEmpty) {
        throw const OpenTdbNoResultsException();
      }

      _questions = fetchedQuestions;
      _isQuizActive = true;
      _stopwatch.start();
      _quizError = null;
      return true;
    } on ApiException catch (e) {
      _quizError = e.message;
      return false;
    } catch (e) {
      _quizError = 'Unexpected error starting quiz: $e';
      return false;
    } finally {
      _isLoadingQuestions = false;
      notifyListeners();
    }
  }

  /// Records a user's selected answer for a specific question index.
  void selectAnswer(int questionIndex, String answer) {
    if (!_isQuizActive || questionIndex < 0 || questionIndex >= _questions.length) {
      return;
    }
    _selectedAnswers[questionIndex] = answer;
    notifyListeners();
  }

  /// Records an answer for the currently displayed question.
  void selectCurrentAnswer(String answer) {
    selectAnswer(_currentQuestionIndex, answer);
  }

  /// Clears the answer for a specific question (marks as unanswered).
  void clearAnswer(int questionIndex) {
    if (_selectedAnswers.containsKey(questionIndex)) {
      _selectedAnswers.remove(questionIndex);
      notifyListeners();
    }
  }

  /// Navigates to the next question.
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// Navigates to the previous question.
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Jumps directly to a given question index.
  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length && index != _currentQuestionIndex) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  /// Completes the active quiz, aggregates metrics, and generates a QuizResult.
  QuizResult finishQuiz() {
    _stopwatch.stop();

    final userAnswers = <UserAnswer>[];
    for (var i = 0; i < _questions.length; i++) {
      userAnswers.add(
        UserAnswer(
          question: _questions[i],
          questionIndex: i,
          selectedAnswer: _selectedAnswers[i],
        ),
      );
    }

    final quizResult = QuizResult(
      userAnswers: userAnswers,
      totalDuration: _stopwatch.elapsed,
      categoryTitle: _config.category?.name ?? 'All Categories',
      difficulty: _config.difficulty ?? 'Any',
    );

    _result = quizResult;
    _isQuizActive = false;
    _isQuizCompleted = true;
    notifyListeners();

    return quizResult;
  }

  /// Resets active quiz state back to initial configuration screen.
  void resetQuiz() {
    _stopwatch.reset();
    _questions = [];
    _currentQuestionIndex = 0;
    _selectedAnswers.clear();
    _isQuizActive = false;
    _isQuizCompleted = false;
    _result = null;
    _quizError = null;
    _isLoadingQuestions = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _apiService.dispose();
    super.dispose();
  }
}
