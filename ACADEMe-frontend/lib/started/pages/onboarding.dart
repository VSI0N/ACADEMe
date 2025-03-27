import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/started/pages/signup_view.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key}); // Added named key parameter

  @override
  State<OnboardingFlow> createState() => OnboardingFlowState();
}

class OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Education",
      "description":
          "Empowering every learner with a dynamic, personalized, high-quality educational experience & community support",
      "imagePath": "assets/images/books-and-apple.png",
    },
    {
      "title": "Progress Tracking",
      "description":
          "AI-driven progress tracking adapts to individual learning needs, bridging knowledge gaps for personalized improvement",
      "imagePath": "assets/images/growth-graph.png",
    },
    {
      "title": "ASKMe",
      "description":
          "An AI powered chatbot to help you with your queries and doubts. Takes in Images, videos and can give responses in your native language.",
      "imagePath": "assets/images/idea.png",
    },
  ];

  void _goToNextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 500), curve: Curves.ease);
    } else {
      _navigateToSignUp();
    }
  }

  Future<void> _navigateToSignUp() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignUpView()),
    );
  }

  Future<void> _skipToLastPage() async {
    for (int i = _currentPage; i < onboardingData.length; i++) {
      if (!mounted) return;
      setState(() => _currentPage = i);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    await _navigateToSignUp();
  }

  LinearGradient _getGradientForPage(int pageIndex) {
    List<Color> gradients = [
      const Color(0xFFA898E7),
      const Color(0xFFFCB69F),
      const Color(0xFF74EBD5),
    ];
    return LinearGradient(
      colors: [gradients[pageIndex], Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: _getGradientForPage(_currentPage),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    Center(
                      child: Image.asset(
                        onboardingData[index]['imagePath']!,
                        height: height * 0.3,
                      ),
                    ),
                    const Spacer(flex: 5),
                  ],
                );
              },
            ),
            Positioned(
              bottom: height * 0.06,
              left: height * 0.02,
              right: height * 0.02,
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  minHeight: height * 0.22,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        onboardingData[_currentPage]['title']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: width * 0.047,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      Text(
                        onboardingData[_currentPage]['description']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: width * 0.033,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: height * 0.016),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          onboardingData.length,
                          (index) => buildDot(isActive: index == _currentPage),
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _currentPage == onboardingData.length - 1
                            ? ElevatedButton(
                                onPressed: _goToNextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow,
                                  padding: EdgeInsets.symmetric(
                                      vertical: height * 0.013,
                                      horizontal: width * 0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  "Get Started",
                                  style: TextStyle(
                                    fontSize: width * 0.039,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: _skipToLastPage,
                                    child: Text(
                                      "Skip",
                                      style: TextStyle(
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _goToNextPage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.yellow,
                                      padding: EdgeInsets.symmetric(
                                          vertical: height * 0.01,
                                          horizontal: width * 0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      "Next",
                                      style: TextStyle(
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 10 : 8,
      height: isActive ? 10 : 8,
      decoration: BoxDecoration(
        color: isActive ? AcademeTheme.appColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}
