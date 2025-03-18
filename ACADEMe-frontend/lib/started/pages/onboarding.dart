import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/pages/bottomNav.dart';
import 'package:ACADEMe/started/pages/signup_view.dart';

class OnboardingFlow extends StatefulWidget {
  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Education is the best\nlearn ever",
      "description":
      "It is a long established fact that a reader will be distracted by the readable content.",
      "imagePath": "assets/images/books-and-apple.png",
    },
    {
      "title": "Learn Anytime, Anywhere",
      "description":
      "With our app, learning is more flexible and accessible than ever before.",
      "imagePath": "assets/images/growth-graph.png",
    },
    {
      "title": "Achieve Your Goals",
      "description":
      "Our platform helps you track progress and achieve success effortlessly.",
      "imagePath": "assets/images/idea.png",
    },
  ];

  void _goToNextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
          duration: Duration(milliseconds: 500), curve: Curves.ease);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignUpView()),
      );
    }
  }

  void _skipToLastPage() async {
    for (int i = _currentPage; i < onboardingData.length; i++) {
      setState(() => _currentPage = i);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300), // Fast transition
        curve: Curves.linear,
      );
      await Future.delayed(Duration(milliseconds: 300)); // Small delay for effect
    }

    // Navigate to SignUpView after animations complete
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignUpView()),
    );
  }


  LinearGradient _getGradientForPage(int pageIndex) {
    List<Color> gradients = [
      Color(0xFFA898E7),
      Color(0xFFFCB69F),
      Color(0xFF74EBD5),
    ];
    return LinearGradient(
      colors: [gradients[pageIndex], Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(milliseconds: 500),
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
                        height: 250, // Adjusted height for better positioning
                      ),
                    ),
                    const Spacer(flex: 5),
                  ],
                );
              },
            ),
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                height: 240,
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
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            onboardingData[_currentPage]['title']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            onboardingData[_currentPage]['description']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              onboardingData.length,
                                  (index) =>
                                  buildDot(isActive: index == _currentPage),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _currentPage == onboardingData.length - 1
                          ? ElevatedButton(
                        onPressed: _goToNextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "Get Started",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _skipToLastPage(),
                            child: Text(
                              "Skip",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _goToNextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              "Next",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
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
