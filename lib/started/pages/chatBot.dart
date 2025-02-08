import 'package:flutter/material.dart';

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  _ChatbotState createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(_controller.text);
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.indigoAccent,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: const Text(
            "ASKMe",
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigoAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _messages[index],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),

          // AI Chatbot Welcome Message (With Profile Icon)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Profile Icon
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellow,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: const Icon(Icons.person, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 8),

                // Welcome Message Container
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigoAccent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(0),  // Rounded corner
                        topRight: Radius.circular(12), // Rounded corner
                        bottomLeft: Radius.circular(12), // Sharp corner
                        bottomRight: Radius.circular(12), // Rounded corner
                      ),
                    ),
                    child: const Text(
                      "Welcome to ACADAMe, I am your personal tutor enabling you with "
                          "the abundance of resources and help you with the quizzes and "
                          "clear your doubts, you can add any other files you want to "
                          "learn from at a simplified and run through manner, you can "
                          "add the solutions and explanations to your personal notes.",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),


                // Floating Feature Buttons (Document & Screen Icons)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.desktop_windows, color: Colors.grey),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_copy, color: Colors.grey),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chat Input Field + Extra Buttons
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                // Add Button
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.indigoAccent),
                  onPressed: () {},
                ),

                // Text Field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // Send Button
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigoAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
