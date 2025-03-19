import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';

class LessonQuestionPage extends StatefulWidget {
  final List<Map<String, dynamic>> quizzes;
  final Function()? onQuizComplete;

  const LessonQuestionPage(
      {super.key, required this.quizzes, this.onQuizComplete});

  @override
  _LessonQuestionPageState createState() => _LessonQuestionPageState();
}

class _LessonQuestionPageState extends State<LessonQuestionPage> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;

  void _showResultPopup(bool isCorrect) {
    // Show a dialog with the result and an icon
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) {
        return AlertDialog(
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          content: Column(
            mainAxisSize: MainAxisSize.min, // Minimize the height of the dialog
            children: [
              Icon(
                isCorrect ? Icons.check : Icons.close,
                color: Colors.white,
                size: 48, // Icon size
              ),
              const SizedBox(height: 16), // Spacing between icon and text
              Text(
                isCorrect ? "Correct Answer!" : "Wrong Answer!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (isCorrect) ...[
                const SizedBox(height: 8), // Spacing between text and bonus
                const Text(
                  "+1 🔥",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    // Navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close the dialog
      if (_currentQuestionIndex < widget.quizzes.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswer = null;
        });
      } else {
        // All quizzes completed
        if (widget.onQuizComplete != null) {
          widget.onQuizComplete!();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quizzes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Quiz',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text("No quizzes available", style: TextStyle(fontSize: 18)),
        ),
      );
    }

    final currentQuiz = widget.quizzes[_currentQuestionIndex];
    final questionText =
        currentQuiz["question_text"] ?? "No question text available";
    final options =
        (currentQuiz["options"] as List<dynamic>?)?.cast<String>() ??
            ["No options available"];
    final correctOption = currentQuiz["correct_option"] as int? ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quiz',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Box with Increased Minimum Height
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 155, // Set minimum height here
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AcademeTheme.appColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        questionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Answer Options
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Two options per row
                        crossAxisSpacing: 12, // Horizontal spacing
                        mainAxisSpacing: 12, // Vertical spacing
                        childAspectRatio: 1.5, // Adjust aspect ratio
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAnswer = index;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedAnswer == index
                                  ? AcademeTheme.appColor
                                  : Colors.white,
                              border: Border.all(
                                color: AcademeTheme.appColor,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                options[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedAnswer == index
                                      ? Colors.white
                                      : AcademeTheme.appColor,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit Button Fixed at Bottom
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedAnswer != null) {
                    bool isCorrect = _selectedAnswer == correctOption;
                    _showResultPopup(isCorrect); // Show result popup
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select an answer!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
