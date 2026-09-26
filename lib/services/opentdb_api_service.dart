import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import '../models/quiz_question.dart';
import '../models/trivia_category.dart';
import 'api_exceptions.dart';

/// Service responsible for fetching trivia data from OpenTDB (Open Trivia Database).
class OpenTdbApiService {
  static const String _categoriesEndpoint = 'https://opentdb.com/api_category.php';
  static const String _questionsEndpoint = 'https://opentdb.com/api.php';
  static const Duration _timeoutDuration = Duration(seconds: 12);

  final http.Client _client;
  final HtmlUnescape _unescape;

  OpenTdbApiService({
    http.Client? client,
    HtmlUnescape? unescape,
  })  : _client = client ?? http.Client(),
        _unescape = unescape ?? HtmlUnescape();

  /// Fetches the complete list of trivia categories from OpenTDB.
  Future<List<TriviaCategory>> fetchCategories() async {
    try {
      final uri = Uri.parse(_categoriesEndpoint);
      final response = await _client.get(uri).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        if (response.statusCode == 429) {
          throw const OpenTdbRateLimitException();
        }
        throw ApiException(
          'Failed to load categories (HTTP ${response.statusCode}).',
          response.statusCode,
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawCategories = data['trivia_categories'] as List<dynamic>? ?? [];

      final categories = rawCategories
          .map((cat) => TriviaCategory.fromJson(cat as Map<String, dynamic>))
          .toList();

      // Sort categories alphabetically by display name for pleasant presentation
      categories.sort((a, b) => a.displayName.compareTo(b.displayName));
      return categories;
    } on SocketException {
      throw const NetworkException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw const NetworkException('Connection timed out while loading categories. Please retry.');
    } on FormatException {
      throw const ApiException('Invalid data format received from OpenTDB.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error while loading categories: $e');
    }
  }

  /// Fetches quiz questions based on amount, category, difficulty, and type.
  Future<List<QuizQuestion>> fetchQuestions({
    int amount = 10,
    int? categoryId,
    String? difficulty,
    String? type,
  }) async {
    try {
      final queryParams = <String, String>{
        'amount': amount.clamp(1, 50).toString(),
      };

      if (categoryId != null && categoryId > 0) {
        queryParams['category'] = categoryId.toString();
      }

      if (difficulty != null &&
          difficulty.isNotEmpty &&
          difficulty.toLowerCase() != 'any') {
        queryParams['difficulty'] = difficulty.toLowerCase();
      }

      if (type != null &&
          type.isNotEmpty &&
          type.toLowerCase() != 'any') {
        queryParams['type'] = type.toLowerCase();
      }

      final uri = Uri.parse(_questionsEndpoint).replace(queryParameters: queryParams);
      final response = await _client.get(uri).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        if (response.statusCode == 429) {
          throw const OpenTdbRateLimitException();
        }
        throw ApiException(
          'Failed to fetch questions (HTTP ${response.statusCode}).',
          response.statusCode,
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final responseCode = data['response_code'] as int? ?? 0;

      // Handle OpenTDB specific response codes
      _handleResponseCode(responseCode);

      final resultsList = data['results'] as List<dynamic>? ?? [];

      if (resultsList.isEmpty) {
        throw const OpenTdbNoResultsException();
      }

      final questions = resultsList.map((item) {
        return QuizQuestion.fromJson(
          item as Map<String, dynamic>,
          unescape: _unescape,
        );
      }).toList();

      return questions;
    } on SocketException {
      throw const NetworkException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw const NetworkException('Quiz request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Failed to parse quiz response data.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error while fetching quiz: $e');
    }
  }

  /// Maps OpenTDB numeric response codes to typed exceptions.
  void _handleResponseCode(int code) {
    switch (code) {
      case 0:
        return; // Success
      case 1:
        throw const OpenTdbNoResultsException();
      case 2:
        throw const OpenTdbInvalidParameterException();
      case 3:
        throw const OpenTdbTokenNotFoundException();
      case 4:
        throw const OpenTdbTokenEmptyException();
      case 5:
        throw const OpenTdbRateLimitException();
      default:
        throw OpenTdbException(code, 'OpenTDB returned error code: $code');
    }
  }

  void dispose() {
    _client.close();
  }
}
