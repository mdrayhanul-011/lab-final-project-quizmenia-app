import 'package:flutter/material.dart';
import 'welcome_screen.dart';

/// Legacy HomeScreen entrypoint forwarding to the WelcomeScreen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WelcomeScreen();
  }
}
