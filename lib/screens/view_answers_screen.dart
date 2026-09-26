import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/quiz_result.dart';
import '../models/user_answer.dart';

/// Screen 7 (View Answers / Review)
/// Shows questions, selected answers, and correct answers with clear visual cues.
class ViewAnswersScreen extends StatefulWidget {
  final QuizResult result;

  const ViewAnswersScreen({super.key, required this.result});

  @override
  State<ViewAnswersScreen> createState() => _ViewAnswersScreenState();
}

class _ViewAnswersScreenState extends State<ViewAnswersScreen> {
  String _selectedFilter = 'All';

  List<UserAnswer> _getFilteredAnswers() {
    switch (_selectedFilter) {
      case 'Correct':
        return widget.result.correctAnswers;
      case 'Wrong':
        return widget.result.incorrectAnswers;
      case 'Unanswered':
        return widget.result.unansweredQuestions;
      default:
        return widget.result.userAnswers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredAnswers();
    final result = widget.result;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'View Answers',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All (${result.totalQuestions})',
                      isSelected: _selectedFilter == 'All',
                      onTap: () => setState(() => _selectedFilter = 'All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Correct (${result.score})',
                      isSelected: _selectedFilter == 'Correct',
                      color: AppColors.optionSelectedBorder,
                      onTap: () => setState(() => _selectedFilter = 'Correct'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Wrong (${result.incorrectCount})',
                      isSelected: _selectedFilter == 'Wrong',
                      color: const Color(0xFFC62828),
                      onTap: () => setState(() => _selectedFilter = 'Wrong'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Unanswered (${result.unansweredCount})',
                      isSelected: _selectedFilter == 'Unanswered',
                      color: const Color(0xFFE65100),
                      onTap: () => setState(() => _selectedFilter = 'Unanswered'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Question List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No questions in this filter.',
                        style: TextStyle(
                          color: AppColors.textSubtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final answerItem = filtered[index];
                        return _ReviewCard(
                          answerItem: answerItem,
                          itemNumber: answerItem.questionIndex + 1,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primaryTeal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.optionBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final UserAnswer answerItem;
  final int itemNumber;

  const _ReviewCard({
    required this.answerItem,
    required this.itemNumber,
  });

  @override
  Widget build(BuildContext context) {
    final question = answerItem.question;
    final isCorrect = answerItem.isCorrect;
    final isUnanswered = answerItem.isUnanswered;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    if (isCorrect) {
      badgeBg = AppColors.reviewCorrectBg;
      badgeText = AppColors.reviewCorrectText;
      badgeLabel = 'Correct';
      badgeIcon = Icons.check_circle_rounded;
    } else if (isUnanswered) {
      badgeBg = AppColors.reviewUnansweredBg;
      badgeText = AppColors.reviewUnansweredText;
      badgeLabel = 'Unanswered';
      badgeIcon = Icons.remove_circle_outline_rounded;
    } else {
      badgeBg = AppColors.reviewWrongBg;
      badgeText = AppColors.reviewWrongText;
      badgeLabel = 'Incorrect';
      badgeIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.optionBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Question number & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $itemNumber',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeText),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Question Text
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Display all answer options with highlights
          ...question.answers.map((choice) {
            final isThisCorrectAnswer = question.checkAnswer(choice);
            final isThisUserSelected = answerItem.selectedAnswer == choice;

            Color optionBg = AppColors.optionBackground;
            Color optionBorder = AppColors.optionBorder;
            Color optionTextColor = AppColors.textDark;
            Widget? statusTag;

            if (isThisCorrectAnswer) {
              // Correct answer is always GREEN
              optionBg = AppColors.reviewCorrectBg;
              optionBorder = AppColors.reviewCorrectText;
              optionTextColor = AppColors.reviewCorrectText;
              statusTag = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.reviewCorrectText,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Correct Answer',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            } else if (isThisUserSelected) {
              // User's wrong answer is DEEP RED
              optionBg = AppColors.reviewWrongBg;
              optionBorder = AppColors.reviewWrongText;
              optionTextColor = AppColors.reviewWrongText;
              statusTag = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.reviewWrongText,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Your Answer',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: optionBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: optionBorder,
                  width: (isThisCorrectAnswer || isThisUserSelected) ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      choice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (isThisCorrectAnswer || isThisUserSelected)
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: optionTextColor,
                      ),
                    ),
                  ),
                  if (statusTag != null) ...[
                    const SizedBox(width: 8),
                    statusTag,
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
