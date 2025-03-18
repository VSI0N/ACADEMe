import 'package:ACADEMe/started/pages/get-started_view.dart';
import 'package:ACADEMe/started/pages/onboarding.dart';

import 'academe_theme.dart';
import 'package:flutter/material.dart';
import 'started/pages/signup_view.dart';

class AcademeScreen extends StatelessWidget {
  const AcademeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcademeTheme.white,
      body: OnboardingFlow(),
    );
  }
}