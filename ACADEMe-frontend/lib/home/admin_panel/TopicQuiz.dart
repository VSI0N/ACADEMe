import 'package:flutter/material.dart';
import '../../academe_theme.dart';

class QuizScreen extends StatefulWidget {
  final String courseTitle;

  QuizScreen({required this.courseTitle});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, String>> quizQuestions = [];

  void _addQuizQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController questionController = TextEditingController();
        List<TextEditingController> optionControllers = [
          TextEditingController(),
          TextEditingController(),
        ];
        String correctOption = 'A';

        void addOption(setDialogState) {
          if (optionControllers.length < 4) {
            setDialogState(() {
              optionControllers.add(TextEditingController());
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add Quiz Question"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      decoration: InputDecoration(labelText: "Type the Question"),
                    ),
                    ...List.generate(optionControllers.length, (index) {
                      return TextField(
                        controller: optionControllers[index],
                        decoration: InputDecoration(labelText: "Option ${String.fromCharCode(65 + index)}"),
                      );
                    }),
                    if (optionControllers.length < 4)
                      TextButton(
                        onPressed: () => addOption(setDialogState),
                        child: Text("Add Another Option"),
                      ),
                    DropdownButtonFormField<String>(
                      value: correctOption,
                      items: List.generate(optionControllers.length, (index) {
                        String option = String.fromCharCode(65 + index);
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text("Correct Option: $option"),
                        );
                      }),
                      onChanged: (value) {
                        setDialogState(() {
                          correctOption = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (questionController.text.isNotEmpty &&
                        optionControllers.every((controller) => controller.text.isNotEmpty)) {
                      setState(() {
                        Map<String, String> question = {
                          "question": questionController.text,
                          "correct": correctOption,
                        };
                        for (int i = 0; i < optionControllers.length; i++) {
                          question[String.fromCharCode(65 + i)] = optionControllers[i].text;
                        }
                        quizQuestions.add(question);
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          "${widget.courseTitle} > Quiz",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: quizQuestions.isEmpty
            ? Center(child: Text("No quiz questions added yet."))
            : ListView.builder(
          itemCount: quizQuestions.length,
          itemBuilder: (context, index) {
            final question = quizQuestions[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${index + 1}. ${question["question"]}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Column(
                      children: question.keys
                          .where((key) => key.length == 1 && RegExp(r'[A-D]').hasMatch(key))
                          .map((option) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: question["correct"] == option
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text("$option) ", style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(question[option]!)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuizQuestion,
        backgroundColor: AcademeTheme.appColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
