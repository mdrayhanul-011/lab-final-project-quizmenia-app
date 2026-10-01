import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/quiz_config.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../models/trivia_category.dart';
import '../models/user_answer.dart';
import '../services/api_exceptions.dart';
import '../services/opentdb_api_service.dart';
import '../services/quiz_preferences_service.dart';
import '../utils/category_asset_helper.dart';

/// Central state management for Quizmenia using Provider.
/// Coordinates quiz lifecycle, single overall countdown timer across all questions,
/// question navigation, answer tracking, time-spent calculation, result compilation,
/// and SharedPreferences persistence of user's last quiz configuration.
class QuizProvider with ChangeNotifier {
  final OpenTdbApiService _apiService;
  final QuizPreferencesService _prefsService;

  QuizProvider({
    OpenTdbApiService? apiService,
    QuizPreferencesService? prefsService,
  })  : _apiService = apiService ?? OpenTdbApiService(),
        _prefsService = prefsService ?? QuizPreferencesService() {
    loadSavedConfig();
  }

  // ---------------------------------------------------------------------------
  // Categories State & Session Caching
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
  bool _hasUserModifiedConfig = false;
  QuizConfig get config => _config;

  Future<void> loadSavedConfig() async {
    try {
      final saved = await _prefsService.loadLastConfig(availableCategories: _categories);
      if (!_hasUserModifiedConfig) {
        _config = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  void setAmount(int amount) {
    _hasUserModifiedConfig = true;
    _config = _config.copyWith(amount: amount.clamp(1, 50));
    _saveConfigDebounced();
    notifyListeners();
  }

  void setCategory(TriviaCategory? category) {
    _hasUserModifiedConfig = true;
    if (category == null) {
      _config = _config.copyWith(clearCategory: true);
    } else {
      _config = _config.copyWith(category: category);
    }
    _saveConfigDebounced();
    notifyListeners();
  }

  void setDifficulty(String? difficulty) {
    _hasUserModifiedConfig = true;
    if (difficulty == null || difficulty.isEmpty || difficulty.toLowerCase() == 'any') {
      _config = _config.copyWith(clearDifficulty: true);
    } else {
      _config = _config.copyWith(difficulty: difficulty);
    }
    _saveConfigDebounced();
    notifyListeners();
  }

  void setType(String? type) {
    _hasUserModifiedConfig = true;
    if (type == null || type.isEmpty || type.toLowerCase() == 'any') {
      _config = _config.copyWith(clearType: true);
    } else {
      _config = _config.copyWith(type: type);
    }
    _saveConfigDebounced();
    notifyListeners();
  }

  /// Sets the single overall countdown duration in minutes (1–50 mins).
  void setDurationMinutes(int minutes) {
    _hasUserModifiedConfig = true;
    _config = _config.copyWith(durationMinutes: minutes.clamp(1, 50));
    _saveConfigDebounced();
    notifyListeners();
  }

  void updateConfig(QuizConfig newConfig) {
    _hasUserModifiedConfig = true;
    _config = newConfig;
    _saveConfigDebounced();
    notifyListeners();
  }

  void _saveConfigDebounced() {
    unawaited(_prefsService.saveLastConfig(_config));
  }

  // ---------------------------------------------------------------------------
  // Active Quiz State & Overall Countdown Timer
  // ---------------------------------------------------------------------------
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {}; // questionIndex -> answer
  final Map<int, Duration> _questionTimeMap = {}; // questionIndex -> duration spent
  DateTime? _questionStartTime;

  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _initialDurationSeconds = 0;
  bool _hasAutoSubmitted = false;
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

  // Timer Getters
  int get remainingSeconds => _remainingSeconds;
  int get initialDurationSeconds => _initialDurationSeconds;
  bool get hasAutoSubmitted => _hasAutoSubmitted;
  bool get isTimeUp => _remainingSeconds <= 0 && _isQuizCompleted;

  /// Formatted countdown clock "MM:SS" (e.g. "10:00", "09:59")
  String get formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Linear fraction of remaining time from 1.0 (start) down to 0.0 (time up)
  double get timerProgress {
    if (_initialDurationSeconds <= 0) return 0.0;
    return (_remainingSeconds / _initialDurationSeconds).clamp(0.0, 1.0);
  }

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
  // Actions: Categories (Cached during session)
  // ---------------------------------------------------------------------------

  /// Loads trivia categories from OpenTDB. Caches results once loaded.
  Future<void> loadCategories({bool forceRefresh = false}) async {
    // If already loaded and not forcing refresh, reuse cached categories
    if (_categories.isNotEmpty && !forceRefresh) return;
    if (_isLoadingCategories) return;

    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final fetchedCategories = await _apiService.fetchCategories();
      _categories = fetchedCategories
          .where(CategoryAssetHelper.isSupportedCategory)
          .toList();
      _categoriesError = null;

      // Re-map saved category if needed
      if (_config.category != null) {
        final match = _categories.where((c) => c.id == _config.category!.id);
        if (match.isNotEmpty) {
          _config = _config.copyWith(category: match.first);
        }
      }
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
    _questionTimeMap.clear();
    _currentQuestionIndex = 0;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _stopwatch.reset();
    _hasAutoSubmitted = false;
    notifyListeners();

    // Persist current configuration via SharedPreferences
    unawaited(_prefsService.saveLastConfig(_config));

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
      _questionStartTime = DateTime.now();
      _startCountdownTimer();
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

  /// Starts the single overall countdown timer that runs continuously across all questions.
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _initialDurationSeconds = _config.totalDurationSeconds;
    _remainingSeconds = _initialDurationSeconds;
    _hasAutoSubmitted = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _countdownTimer = null;
        _handleTimeUp();
      }
    });
  }

  /// Internal handler called when countdown reaches 00:00.
  /// Automatically submits the entire quiz, calculates the score,
  /// leaves unanswered questions as unanswered, and completes the quiz.
  void _handleTimeUp() {
    if (!_isQuizActive || _isQuizCompleted) return;
    _hasAutoSubmitted = true;
    finishQuiz();
  }

  void _recordTimeOnCurrentQuestion() {
    if (_questionStartTime != null) {
      final spent = DateTime.now().difference(_questionStartTime!);
      _questionTimeMap[_currentQuestionIndex] =
          (_questionTimeMap[_currentQuestionIndex] ?? Duration.zero) + spent;
    }
    _questionStartTime = DateTime.now();
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
      _recordTimeOnCurrentQuestion();
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// Navigates to the previous question.
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _recordTimeOnCurrentQuestion();
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Jumps directly to a given question index.
  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length && index != _currentQuestionIndex) {
      _recordTimeOnCurrentQuestion();
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  /// Completes the active quiz, stops timer, aggregates metrics, and generates a QuizResult.
  QuizResult finishQuiz() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _stopwatch.stop();

    // Prevent duplicate result generation
    if (_isQuizCompleted && _result != null) {
      return _result!;
    }

    _recordTimeOnCurrentQuestion();

    // Determine actual elapsed time
    final elapsed = _initialDurationSeconds > 0
        ? Duration(seconds: _initialDurationSeconds - _remainingSeconds)
        : _stopwatch.elapsed;

    final userAnswers = <UserAnswer>[];
    for (var i = 0; i < _questions.length; i++) {
      userAnswers.add(
        UserAnswer(
          question: _questions[i],
          questionIndex: i,
          selectedAnswer: _selectedAnswers[i],
          timeSpent: _questionTimeMap[i] ?? Duration.zero,
        ),
      );
    }

    final quizResult = QuizResult(
      userAnswers: userAnswers,
      totalDuration: elapsed,
      selectedDuration: _config.totalDuration,
      categoryTitle: _config.category?.name ?? 'All Categories',
      difficulty: _config.difficulty ?? 'Any',
    );

    _result = quizResult;
    _isQuizActive = false;
    _isQuizCompleted = true;
    notifyListeners();

    return quizResult;
  }

  /// Resets active quiz session state for "Play Again".
  /// Clears questions, answers, result, and stops old timers while preserving the user's configuration.
  void resetQuiz({bool keepConfig = true}) {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _remainingSeconds = 0;
    _initialDurationSeconds = 0;
    _hasAutoSubmitted = false;
    _stopwatch.reset();
    _questions = [];
    _questionTimeMap.clear();
    _questionStartTime = null;
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
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _stopwatch.stop();
    _apiService.dispose();
    super.dispose();
  }
}
