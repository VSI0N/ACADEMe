import 'academe_theme.dart';
import 'started/pages/askme_view.dart';
import 'started/components/center_next_button.dart';
import 'home/pages/home_view.dart';
import 'started/pages/progress_view.dart';
import 'started/pages/education_view.dart';
import 'started/pages/get-started_view.dart';
import 'started/components/top_back_skip_view.dart';
import 'started/pages/signup_view.dart';
import 'package:flutter/material.dart';

class AcademeScreen extends StatefulWidget {
  const AcademeScreen({super.key});

  @override
  _AcademeScreenState createState() => _AcademeScreenState();
}

class _AcademeScreenState extends State<AcademeScreen>
    with TickerProviderStateMixin {
  AnimationController? _animationController;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 8));
    _animationController?.animateTo(0.0);
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(_animationController?.value);
    return Scaffold(
      backgroundColor: AcademeTheme.white,
      body: ClipRect(
        child: Stack(
          children: [
            GetStartedView(
              animationController: _animationController!,
            ),
            EducationView(
              animationController: _animationController!,
            ),
            AskMeView(
              animationController: _animationController!,
            ),
            ProgressView(
              animationController: _animationController!,
            ),
            SignUpView(
              animationController: _animationController!,
            ),
            TopBackSkipView(
              onBackClick: _onBackClick,
              onSkipClick: _onSkipClick,
              animationController: _animationController!,
            ),
            CenterNextButton(
              animationController: _animationController!,
              onNextClick: _onNextClick,
            ),
          ],
        ),
      ),
    );
  }

  void _onSkipClick() {
    _animationController?.animateTo(0.8,
        duration: Duration(milliseconds: 1200));
  }

  void _onBackClick() {
    if (_animationController!.value >= 0 &&
        _animationController!.value <= 0.2) {
      _animationController?.animateTo(0.0);
    } else if (_animationController!.value > 0.2 &&
        _animationController!.value <= 0.4) {
      _animationController?.animateTo(0.2);
    } else if (_animationController!.value > 0.4 &&
        _animationController!.value <= 0.6) {
      _animationController?.animateTo(0.4);
    } else if (_animationController!.value > 0.6 &&
        _animationController!.value <= 0.8) {
      _animationController?.animateTo(0.6);
    } else if (_animationController!.value > 0.8 &&
        _animationController!.value <= 1.0) {
      _animationController?.animateTo(0.8);
    }
  }

  void _onNextClick() {
    if (_animationController!.value >= 0 &&
        _animationController!.value <= 0.2) {
      _animationController?.animateTo(0.4);
    } else if (_animationController!.value > 0.2 &&
        _animationController!.value <= 0.4) {
      _animationController?.animateTo(0.6);
    } else if (_animationController!.value > 0.4 &&
        _animationController!.value <= 0.6) {
      _animationController?.animateTo(0.8);
    } else if (_animationController!.value > 0.6 &&
        _animationController!.value <= 0.8) {
      _signUpClick();
    }
  }

  void _signUpClick() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ));
  }
}
