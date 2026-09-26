import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Renders the "Quizzical" brand logo with the characteristic yellow sunburst
/// rays above the letter 'Q', exactly as shown in App_Screen.pdf.
class QuizzicalLogo extends StatelessWidget {
  final double fontSize;
  final bool center;

  const QuizzicalLogo({
    super.key,
    this.fontSize = 32,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -fontSize * 0.35,
                  left: fontSize * 0.1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: -0.4,
                        child: Container(
                          width: fontSize * 0.08,
                          height: fontSize * 0.22,
                          decoration: BoxDecoration(
                            color: AppColors.accentSunburst,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(width: fontSize * 0.08),
                      Container(
                        width: fontSize * 0.08,
                        height: fontSize * 0.28,
                        decoration: BoxDecoration(
                          color: AppColors.accentSunburst,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: fontSize * 0.08),
                      Transform.rotate(
                        angle: 0.4,
                        child: Container(
                          width: fontSize * 0.08,
                          height: fontSize * 0.22,
                          decoration: BoxDecoration(
                            color: AppColors.accentSunburst,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Quizzical',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
