import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/quiz_provider.dart';
import '../widgets/primary_pill_button.dart';
import 'category_screen.dart';
import 'view_answers_screen.dart';

/// Screen 5 & 6 (Result Screens) matching Pages 5 & 6 of App_Screen.pdf
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final result = provider.result;

    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No result found.', style: TextStyle(color: AppColors.textDark)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final scorePercentage = result.scorePercentage;
    final isSuccess = scorePercentage >= 50.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 1. Result Illustration from reference
              Image.asset(
                isSuccess
                    ? 'assets/images/result_congrats.png'
                    : 'assets/images/result_retry.png',
                height: 190,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 16),

              // 2. Title ("Congratulation" or "Keep Trying!")
              Text(
                isSuccess ? 'Congratulation' : 'Keep Trying!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 16),

              // 3. Score Percentage Rounded Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.resultSuccessGreen
                      : AppColors.resultFailureOrange,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: (isSuccess
                              ? AppColors.resultSuccessGreen
                              : AppColors.resultFailureOrange)
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${scorePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: isSuccess
                          ? AppColors.resultSuccessText
                          : AppColors.resultFailureText,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 4. Reference Subtitle Message
              Text(
                isSuccess
                    ? "You've got a great foundation. Ready to try a different category?"
                    : "Don't give up! Practice makes perfect. Try again to improve your score",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // 5. Score & Performance Statistics Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.optionBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Score',
                      value: '${result.score}/${result.totalQuestions}',
                      color: AppColors.primaryTeal,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    Container(width: 1, height: 36, color: AppColors.dividerLine),
                    _StatItem(
                      label: 'Time',
                      value: result.formattedDuration,
                      color: const Color(0xFF3F51B5),
                      icon: Icons.timer_outlined,
                    ),
                    Container(width: 1, height: 36, color: AppColors.dividerLine),
                    _StatItem(
                      label: 'Accuracy',
                      value: '${scorePercentage.toStringAsFixed(0)}%',
                      color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      icon: Icons.analytics_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 6. Action Button: PLAY AGAIN
              PrimaryPillButton(
                text: AppConstants.playAgain,
                onPressed: () {
                  provider.resetQuiz();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryScreen(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),

              const SizedBox(height: 14),

              // 7. Action Button: VIEW ANSWERS
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAnswersScreen(result: result),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.remove_red_eye_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        AppConstants.viewAnswers,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSubtitle,
          ),
        ),
      ],
    );
  }
}
