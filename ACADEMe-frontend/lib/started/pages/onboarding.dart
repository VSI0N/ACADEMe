import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      "title": "Education",
      "description":
      "Empowering every learner with a dynamic, personalized, high-quality educational experienece & community support",
      "imagePath": "assets/images/books-and-apple.png",
    },
    {
      "title": "Progress Tracking",
      "description":
      "AI-driven progress tracking adapts to individual Learning needs, bridging knowledge gaps for personalized imporvement",
      "imagePath": "assets/images/growth-graph.png",
    },
    {
      "title": "ASKMe",
      "description":
      "An AI Powered chatbot to help you with your quries and doubts. Takes in Images, videos and can give reponses in your native language.",
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
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
                        height: height * 0.3, // Adjusted height for better positioning
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
                  minHeight: height * 0.22, // Give enough space even on small phones
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
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Important: makes Column wrap its content
                    children: [
                      Text(
                        onboardingData[_currentPage]['title']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: width * 0.047,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      Text(
                        onboardingData[_currentPage]['description']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: width * 0.033,
                          color: Colors.grey[600],
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
                                vertical: height * 0.013, horizontal: width * 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            "Get Started",
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.039,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _skipToLastPage,
                              child: Text(
                                "Skip",
                                style: GoogleFonts.poppins(
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _goToNextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                padding: EdgeInsets.symmetric(
                                    vertical: height * 0.01, horizontal: width * 0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Next",
                                style: GoogleFonts.poppins(
                                  fontSize: width * 0.04,
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
