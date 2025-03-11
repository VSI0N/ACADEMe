import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/courses/linear_algebra/quiz.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class flashCard extends StatefulWidget {
  @override
  _flashCardState createState() => _flashCardState();
}

class _flashCardState extends State<flashCard> {
  final PageController _pageController = PageController(); // ✅ Page controller added
  late YoutubePlayerController _controller;
  bool _isPlaying = false;
  bool _isShorts = false;
  int _currentPage = 0; // ✅ Tracks current page for progress indicator
  double _swipeProgress = 0.0;
  bool _hasNavigated = false;


  @override
  void initState() {
    super.initState();
    String videoUrl = "https://youtube.com/shorts/uUExkZM_M8I?si=owSdXTD12FIz_ifN";
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    _isShorts = videoUrl.contains("/shorts/");

    _controller = YoutubePlayerController(
      initialVideoId: videoId!,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    )..addListener(() {
      final position = _controller.value.position.inSeconds;
      final duration = _controller.metadata.duration.inSeconds;

      if (!_hasNavigated && position > 0 && position >= duration - 1) { // ✅ Ensures full playback
        _hasNavigated = true;
        _navigateToQuiz();
      }
    });
  }

  void _navigateToQuiz() {
    Future.delayed(Duration(seconds: 1), () { // ✅ Small delay for smooth transition
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LessonQuestionPage()),
        );
      }
    });
  }

  void _toggleVideo() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _swipeProgress = 0.0;
      if (_currentPage == 1) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcademeTheme.appColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'I - Introduction',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Progress Indicator Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == 0 ? Colors.yellow[700] : Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == 1 ? Colors.yellow[700] : Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 4,
            width: double.infinity,
            color: Colors.white,
          ),
          SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Linear Algebra',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails details) {
                double screenWidth = MediaQuery.of(context).size.width;
                double tapPosition = details.globalPosition.dx;
                if (tapPosition > screenWidth * 0.6 && _currentPage < 1) {
                  _pageController.nextPage(duration: Duration(milliseconds: 350), curve: Curves.easeInOutCubic);
                } else if (tapPosition < screenWidth * 0.4 && _currentPage > 0) {
                  _pageController.previousPage(duration: Duration(milliseconds: 350), curve: Curves.easeInOutCubic);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                child: Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        physics: BouncingScrollPhysics(),
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              index == 0 ? _buildTextContent() : _buildVideoContent(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildNextPageShadow() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.centerRight,
  //         end: Alignment.centerLeft,
  //         colors: [
  //           Colors.black.withOpacity(0.1), // Darker on the right side
  //           Colors.transparent,             // Fades towards the left
  //         ],
  //       ),
  //     ),
  //   );
  // }


  Widget _buildTextContent() {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Linear algebra is a branch of mathematics that deals with vector spaces, linear equations, and transformations.\n\n"
              "It provides the foundation for various applications in engineering, physics, computer science, and data science. "
              "The core concepts include matrices, determinants, eigenvalues, eigenvectors, and systems of linear equations.\n\n"
              "These tools help solve complex problems involving multiple variables and dimensions. "
              "Linear algebra is widely used in artificial intelligence, cryptography, image processing, and scientific computing, making it an essential subject for modern technological advancements.\n\n"
              "A real-life example of linear algebra is Google’s PageRank algorithm, which ranks web pages based on their relevance.",
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return GestureDetector(
      onTap: _toggleVideo,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        height: _isShorts ? MediaQuery.of(context).size.height * 0.7 : 300,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
          ),
        ),
      ),
    );
  }
}
