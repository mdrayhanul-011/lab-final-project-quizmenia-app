import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/quiz_provider.dart';
import '../widgets/primary_pill_button.dart';
import 'result_screen.dart';

/// Screen 4 (Active Quiz Screen) matching Page 4 of App_Screen.pdf
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _hasNavigatedToResult = false;

  void _navigateToResult() {
    if (_hasNavigatedToResult) return;
    _hasNavigatedToResult = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ResultScreen(),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit Quiz?',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
          style: TextStyle(color: AppColors.textSubtitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSubtitle)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<QuizProvider>().resetQuiz();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        // Auto-navigate if timer expired or quiz completed
        if (provider.isQuizCompleted && !_hasNavigatedToResult) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToResult();
          });
        }

        final currentQuestion = provider.currentQuestion;
        if (currentQuestion == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
          );
        }

        final currentIndex = provider.currentQuestionIndex;
        final totalQuestions = provider.totalQuestions;
        final selectedAnswer = provider.currentSelectedAnswer;
        final progressRatio = (currentIndex + 1) / totalQuestions;
        final isLast = provider.isLastQuestion;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Top Header Bar: Progress Count (7/10), Overall Timer, and EXIT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Overall Quiz Countdown Timer badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.optionBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: AppColors.primaryTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              provider.formattedRemainingTime,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Question progress: "7/10"
                      Text(
                        '${currentIndex + 1}/$totalQuestions',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),

                      // EXIT button
                      InkWell(
                        onTap: _confirmExit,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                AppConstants.exit,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: AppColors.textDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Continuous Top Progress Bar Line (Blue)
                Container(
                  width: double.infinity,
                  height: 4.5,
                  color: AppColors.progressTrack,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progressRatio.clamp(0.0, 1.0),
                    child: Container(
                      height: 4.5,
                      color: AppColors.sliderActive,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Question & Answers scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // White Rounded Question Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentQuestion.category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtitle,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Question text
                              Text(
                                currentQuestion.question,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Answer Options (4 for multiple choice, True/False for boolean)
                        ...currentQuestion.answers.map((answer) {
                          final isSelected = selectedAnswer == answer;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _OptionTile(
                              text: answer,
                              isSelected: isSelected,
                              onTap: () {
                                provider.selectCurrentAnswer(answer);
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 4. Bottom Button: Next / Submit
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: PrimaryPillButton(
                    text: isLast ? AppConstants.submit : AppConstants.next,
                    onPressed: () {
                      if (isLast) {
                        provider.finishQuiz();
                        _navigateToResult();
                      } else {
                        provider.nextQuestion();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.optionSelectedBackground
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.optionSelectedBorder
                  : AppColors.optionBorder,
              width: isSelected ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: isSelected
                        ? AppColors.optionSelectedText
                        : AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Radio indicator
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? AppColors.optionSelectedBorder
                    : AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
