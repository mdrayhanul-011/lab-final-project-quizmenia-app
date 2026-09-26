import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/trivia_category.dart';
import '../providers/quiz_provider.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/quizzical_logo.dart';
import 'quiz_screen.dart';

/// Screen 3 (Quiz Configuration) matching Page 3 of App_Screen.pdf
class QuizConfigScreen extends StatefulWidget {
  final TriviaCategory? category;

  const QuizConfigScreen({super.key, this.category});

  @override
  State<QuizConfigScreen> createState() => _QuizConfigScreenState();
}

class _QuizConfigScreenState extends State<QuizConfigScreen> {
  int _questionCount = 10;
  String _difficulty = 'Any Difficulty';
  String _questionType = 'Multiple Choice';
  int _durationMinutes = 10;

  final List<String> _difficultyOptions = [
    'Any Difficulty',
    'Easy',
    'Medium',
    'Hard',
  ];

  final List<String> _typeOptions = [
    'Multiple Choice',
    'True / False',
    'Any Type',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuizProvider>();
    _questionCount = provider.config.amount;
    _durationMinutes = provider.config.durationMinutes;

    if (provider.config.difficulty != null) {
      final diff = provider.config.difficulty!.toLowerCase();
      if (diff == 'easy') _difficulty = 'Easy';
      if (diff == 'medium') _difficulty = 'Medium';
      if (diff == 'hard') _difficulty = 'Hard';
    }

    if (provider.config.type != null) {
      final t = provider.config.type!.toLowerCase();
      if (t == 'multiple') _questionType = 'Multiple Choice';
      if (t == 'boolean') _questionType = 'True / False';
    }
  }

  void _syncConfigWithProvider() {
    final provider = context.read<QuizProvider>();
    provider.setAmount(_questionCount);

    String? diffParam;
    if (_difficulty == 'Easy') diffParam = 'easy';
    if (_difficulty == 'Medium') diffParam = 'medium';
    if (_difficulty == 'Hard') diffParam = 'hard';
    provider.setDifficulty(diffParam);

    String? typeParam;
    if (_questionType == 'Multiple Choice') typeParam = 'multiple';
    if (_questionType == 'True / False') typeParam = 'boolean';
    provider.setType(typeParam);

    provider.setDurationMinutes(_durationMinutes);
  }

  Future<void> _startQuiz() async {
    _syncConfigWithProvider();
    final provider = context.read<QuizProvider>();

    final success = await provider.startQuiz();

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const QuizScreen(),
        ),
      );
    } else {
      final errorMsg = provider.quizError ?? 'Failed to load quiz questions.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.primaryTealDark,
          action: SnackBarAction(
            label: 'Retry',
            textColor: AppColors.accentSunburst,
            onPressed: _startQuiz,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = widget.category?.displayName ?? 'General Knowledge';
    final isLoading = context.watch<QuizProvider>().isLoadingQuestions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              // Top Banner Illustration
              Image.asset(
                'assets/images/config_banner.png',
                height: 140,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 12),

              // Title, Subtitle, Category
              const QuizzicalLogo(fontSize: 32),
              const SizedBox(height: 6),
              const Text(
                AppConstants.configuration,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSubtitle,
                ),
              ),

              const SizedBox(height: 24),

              // 1. Number of Questions
              _buildNumberSection(),

              const SizedBox(height: 20),

              // 2. Difficulty Level
              _buildDropdownSection(
                title: 'Difficulty Level',
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFFFF9800),
                iconBg: const Color(0xFFFFF3E0),
                selectedValue: _difficulty,
                items: _difficultyOptions,
                onChanged: (val) {
                  if (val != null) setState(() => _difficulty = val);
                },
              ),

              const SizedBox(height: 20),

              // 3. Question Type
              _buildDropdownSection(
                title: 'Question Type',
                icon: Icons.alt_route_rounded,
                iconColor: const Color(0xFF00BFA5),
                iconBg: const Color(0xFFE0F2F1),
                selectedValue: _questionType,
                items: _typeOptions,
                onChanged: (val) {
                  if (val != null) setState(() => _questionType = val);
                },
              ),

              const SizedBox(height: 20),

              // 4. Overall Quiz Countdown Duration (5–50 minutes)
              _buildDurationSection(),

              const SizedBox(height: 32),

              // 5. START Button
              PrimaryPillButton(
                text: AppConstants.start,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                isLoading: isLoading,
                onPressed: _startQuiz,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE7F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.question_mark_rounded,
                    color: Color(0xFF7E57C2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Number of Questions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Select 1–50',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSubtitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '$_questionCount',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.sliderActive,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.sliderActive,
            inactiveTrackColor: AppColors.sliderActive.withValues(alpha: 0.15),
            thumbColor: AppColors.sliderActive,
            overlayColor: AppColors.sliderActive.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: _questionCount.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            onChanged: (val) {
              setState(() => _questionCount = val.round());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: Color(0xFF3F51B5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Quiz Duration',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Overall countdown (5–50 mins)',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSubtitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '$_durationMinutes mins',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3F51B5),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF3F51B5),
            inactiveTrackColor: const Color(0xFF3F51B5).withValues(alpha: 0.15),
            thumbColor: const Color(0xFF3F51B5),
            overlayColor: const Color(0xFF3F51B5).withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: _durationMinutes.toDouble(),
            min: 5,
            max: 50,
            divisions: 9, // 5, 10, 15, 20, 25, 30, 35, 40, 45, 50
            onChanged: (val) {
              setState(() => _durationMinutes = val.round());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String selectedValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.optionBorder, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSubtitle,
              ),
              items: items.map((val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
