import 'package:app_screenshots/features/screenshot_editor/presentation/pages/screenshot_studio_page.dart';
import 'package:flutter/material.dart';

/// The home screen simply wraps ScreenshotStudioPage which already has its own
/// AppBar, FABs, and content. No extra Scaffold/AppBar to avoid double headers.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenshotStudioPage();
  }
}
