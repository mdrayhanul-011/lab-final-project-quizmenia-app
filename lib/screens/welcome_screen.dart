import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/quizzical_logo.dart';
import 'category_screen.dart';

/// Screen 1 (Welcome Screen) matching Page 1 of App_Screen.pdf
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Illustration with decorative soft blobs
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft ambient background circle
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withValues(alpha: 0.05),
                          ),
                        ),
                        // Preserved 3D Boy Illustration from reference
                        Image.asset(
                          'assets/images/welcome_boy.png',
                          width: 280,
                          height: 280,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Branding & Subtitle
                    Column(
                      children: [
                        const QuizzicalLogo(fontSize: 38),
                        const SizedBox(height: 12),
                        const Text(
                          AppConstants.appSubtitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSubtitle,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Star Divider Line
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: AppColors.dividerLine,
                                thickness: 1.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(
                                Icons.star_rounded,
                                color: AppColors.accentSunburst,
                                size: 22,
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: AppColors.dividerLine,
                                thickness: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Action Button: GET STARTED ->
                    PrimaryPillButton(
                      text: AppConstants.getStarted,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CategoryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
