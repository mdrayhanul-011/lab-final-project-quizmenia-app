import 'package:flutter_test/flutter_test.dart';
import 'package:quizmenia/constants/app_constants.dart';
import 'package:quizmenia/main.dart';

void main() {
  testWidgets('App smoke test loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const QuizApp());
    expect(find.text(AppConstants.appName), findsWidgets);
  });
}
