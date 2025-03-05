import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'file_view.dart';
import 'package:ACADEMe/widget/chat_history_drawer.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ASKMe extends StatefulWidget {
  @override
  _ASKMeState createState() => _ASKMeState();
}

class _ASKMeState extends State<ASKMe> {
  final ScrollController _scrollController = ScrollController();
  String selectedLanguage = "en"; // Default: English
  List<Map<String, String>> chatMessages = [];
  final TextEditingController _textController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _timer;
  int _seconds = 0;
  bool isConverting = false; // To track the loading state

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Key for the drawer

  String searchQuery = "";
  List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'Spanish', 'code': 'es'},
    {'name': 'French', 'code': 'fr'},
    {'name': 'German', 'code': 'de'},
    {'name': 'Hindi', 'code': 'hi'},
    {'name': 'Chinese', 'code': 'zh'},
    {'name': 'Japanese', 'code': 'ja'},
    {'name': 'Bengali', 'code': 'bn'},
  ];

  List<Map<String, String>> _getFilteredLanguages() {
    if (searchQuery.isEmpty) {
      return languages; // If search query is empty, show all languages
    } else {
      return languages
          .where((language) => language['name']!
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList(); // Filter the languages based on the search query
    }
  }

  // For the chat history
  List<ChatSession> chatHistory = [
    ChatSession(title: "Chat with AI", timestamp: "Feb 22, 2025"),
    ChatSession(title: "Math Help", timestamp: "Feb 21, 2025"),
  ];

  void _loadChatSession(ChatSession chat) {
    print("Selected chat: ${chat.title}");
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose(); // Keep only this
  }

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    bool hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      print("Recording permission not granted.");
    }
  }

  void _showPromptDialog(File file, String fileType) {
    // This is unchanged
    TextEditingController promptController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Optional Prompt"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text(file.path.split('/').last),
              subtitle:
                  Text("${(file.lengthSync() / 1024).toStringAsFixed(1)}KB"),
            ),
            TextField(
              controller: promptController,
              decoration: InputDecoration(
                hintText: "Enter your prompt (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadFile(file, fileType, promptController.text);
            },
            child: Text("Upload"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile(String fileType) async {
    // This is unchanged
    FileType type;
    List<String>? allowedExtensions;

    switch (fileType) {
      case 'Image':
        type = FileType.image;
        break;
      case 'Document':
        type = FileType.custom;
        allowedExtensions = ['pdf', 'docx', 'txt'];
        break;
      case 'Video':
        type = FileType.video;
        break;
      case 'Audio':
        type = FileType.audio;
        break;
      default:
        return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      //This is unchanged
      type: type,
      allowedExtensions: allowedExtensions,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      _showPromptDialog(file, fileType);
    } else {
      print("❌ File selection canceled.");
    }
  }

  Future<void> _uploadFile(File file, String fileType,
      [String prompt = '']) async {
    //ASKMe backend URL
    var url = Uri.parse(
        'http://10.0.2.2:8000/api/process_${fileType.toLowerCase()}');

    var request = http.MultipartRequest('POST', url);
    request.fields.addAll({
      'prompt': prompt.isNotEmpty ? prompt : 'Describe this image',
      'source_lang': 'auto',
      'target_lang': selectedLanguage,
    });

    String fileFieldName = (fileType == 'Image') ? 'image' : 'file';
    request.files
        .add(await http.MultipartFile.fromPath(fileFieldName, file.path));

    var response = await request.send();
    String responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      try {
        var decodedResponse = jsonDecode(responseBody);
        String aiResponse = decodedResponse is Map<String, dynamic>
            ? decodedResponse.values.first.toString()
            : responseBody;

        setState(() {
          chatMessages.add({
            "role": "user",
            "text": "Uploaded $fileType",
            "fileInfo": file.path, // ✅ Save the image file path
            "fileType": fileType,
          });
          chatMessages.add({
            "role": "assistant",
            "text": aiResponse,
          });
        });
      } catch (e) {
        setState(() {
          chatMessages.add({
            "role": "assistant",
            "text": responseBody,
          });
        });
      }
    } else {
      setState(() {
        chatMessages.add({
          "role": "assistant",
          "text": "⚠️ Error uploading file: $responseBody",
        });
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      String? path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _timer?.cancel();
        _seconds = 0;
      });

      if (path != null) {
        File file = File(path);
        print(
            "Audio file path: $path, Size: ${file.existsSync() ? file.lengthSync() : 'File not found'} bytes");

        if (file.existsSync()) {
          print("File exists, uploading...");
          await _uploadSpeech(file);
        } else {
          print("File does NOT exist. Path: $path");
        }
      } else {
        print("Recording path is null.");
      }
    } else {
      // Request microphone permission
      PermissionStatus micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        print("Microphone permission not granted.");

        return;
      }

      // Prepare file path for recording in WAV format
      Directory tempDir = await getApplicationDocumentsDirectory();
      String filePath =
          '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      try {
        // Start recording with WAV format
        print("Starting recording at path: $filePath");
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav), // WAV format
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _seconds = 0;
        });

        // Timer for tracking recording duration
        _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
          setState(() {
            _seconds++;
          });
        });
      } catch (e) {
        print("Error starting recording: $e");
      }
    }
  }

// Upload Speech Function
  Future<void> _uploadSpeech(File file) async {
    try {
      if (!file.existsSync() || file.lengthSync() == 0) {
        print("❌ File does not exist or is empty.");
        return;
      }
      print("File size: ${file.lengthSync()} bytes");

      setState(() {
        isConverting = true;
      });

      // Backend API URL
      var url = Uri.parse(
          'http://10.0.2.2:8000/api/process_stt');

      var request = http.MultipartRequest('POST', url);

      // Ensure the selected language is not empty
      selectedLanguage = selectedLanguage.isNotEmpty ? selectedLanguage : "hi";
      print("Selected target language: $selectedLanguage");

      request.fields.addAll({
        'prompt': 'इस ऑडियो को हिंदी में लिखो',
        'source_lang': 'auto', // Let the server detect the source language
        'target_lang':
            selectedLanguage, // Send the selected language for the response
      });

      final mimeType = lookupMimeType(file.path) ?? "audio/wav";
      print("Detected MIME type: $mimeType");

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ));

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print("Server response: $responseBody");

      if (response.statusCode == 200) {
        print("✅ Audio uploaded successfully!");

        var decodedResponse = jsonDecode(responseBody);

        // Fix: Extract detected language correctly
        String detectedLang = decodedResponse['language'] ?? 'unknown';
        print("Detected Language: $detectedLang");

        // If the detected language is Hindi and user hasn't explicitly chosen another language
        if (detectedLang == 'hi' && selectedLanguage == "auto") {
          setState(() {
            selectedLanguage =
                'hi'; // Update language to Hindi if detected language is Hindi
          });
          print("✅ Updated selected language to Hindi");
        }

        // Proceed with handling the server response (your AI response)
        await _handleServerResponse(decodedResponse);
      } else {
        print("❌ Upload failed with status: ${response.statusCode}");
        print("Server response: $responseBody");

        setState(() {
          chatMessages.add({
            "role": "assistant",
            "text": "❌ Audio upload failed. Server response: $responseBody",
          });
        });
      }
    } catch (e) {
      print("❌ Error uploading audio: $e");
      setState(() {
        chatMessages.add({
          "role": "assistant",
          "text": "❌ Error uploading audio: $e",
        });
      });
    } finally {
      setState(() {
        isConverting = false;
      });
    }
  }

// Handle the server response and update the input field with the "text" part
  Future<void> _handleServerResponse(Map<String, dynamic> response) async {
    try {
      if (response.containsKey('text')) {
        String responseText = response['text'];

        // Update the input field with the 'text' part of the response
        _textController.text = responseText;
      } else {
        print("❌ No text key in server response");
      }
    } catch (e) {
      print("❌ Error handling server response: $e");
    }
  }

  // Send Message Function
  void _sendMessage() async {
    String message = _textController.text.trim();
    if (message.isNotEmpty) {
      // ASKMe backend URL
      var url = Uri.parse(
          'http://10.0.2.2:8000/api/process_text');

      try {
        var response = await http.post(
          url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'text': message,
            'target_language': selectedLanguage, // Use selectedLanguage here
          },
        );

        if (response.statusCode == 200) {
          // Decode the response properly to support all languages
          String aiResponse = utf8.decode(response.bodyBytes);
          String aiMessage = jsonDecode(aiResponse)['response'];

          setState(() {
            chatMessages.add({"role": "user", "text": message});
            chatMessages.add({"role": "ai", "text": aiMessage});
            _textController.clear();
          });

          // Scroll to the bottom after a short delay
          Future.delayed(Duration(milliseconds: 100), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        } else {
          print("Failed to send message: ${response.statusCode}");
        }
      } catch (error) {
        print("Error sending message: $error");
      }
    }
  }

  void _showLanguageSelection() {
    showModalBottomSheet(
      context: this.context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        String searchQuery = ""; // Local state for search query

        return StatefulBuilder(
          builder: (context, setModalState) {
            List<Map<String, String>> filteredLanguages = languages
                .where((language) => language['name']!
                    .toLowerCase()
                    .startsWith(searchQuery.toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Select Output Language",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),

                  // Search bar with live filtering
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Languages',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      setModalState(() {
                        searchQuery = query; // Live update search query
                      });
                    },
                  ),
                  SizedBox(height: 10),

                  // Scrollable list of filtered languages
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredLanguages.length,
                      itemBuilder: (context, index) {
                        var language = filteredLanguages[index];
                        return _languageTile(
                          language['name'] ?? '',
                          language['code'] ?? '',
                          modalContext,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Attach key to control drawer
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.menu,
              size: 28, color: Colors.white), // Custom hamburger icon
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'ASKMe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: newChatIcon(), onPressed: () {}),
                IconButton(
                  icon: Icon(Icons.translate, size: 28, color: Colors.white),
                  onPressed: () {
                    _showLanguageSelection();
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // Drawer for chat history
      drawer: ChatHistoryDrawer(
        chatHistory: chatHistory,
        onSelectChat: (chat) {
          _loadChatSession(chat);
        },
      ),

      body: chatMessages.isEmpty
          ? _buildInitialUI() // Your chat UI when no messages
          : _buildChatUI(context), // Your chat UI when messages exist

      bottomNavigationBar: AnimatedPadding(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: Icon(Icons.attach_file,
                      color: AcademeTheme.appColor, size: 27),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (BuildContext context) {
                        return Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAttachmentOption(context, Icons.image,
                                  "Image", Colors.blue, 'Image'),
                              _buildAttachmentOption(
                                  context,
                                  Icons.insert_drive_file,
                                  "Document",
                                  Colors.green,
                                  'Document'),
                              _buildAttachmentOption(
                                  context,
                                  Icons.video_library,
                                  "Video",
                                  Colors.orange,
                                  'Video'),
                              _buildAttachmentOption(context, Icons.audiotrack,
                                  "Audio", Colors.purple, 'Audio'),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      controller: _textController,
                      maxLines: 2,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: isConverting
                            ? "Converting ... "
                            : (_isRecording
                                ? "Recording ... ${_seconds}s"
                                : "Type a message ..."),
                        contentPadding: EdgeInsets.only(
                            left: 20, right: 60, top: 14, bottom: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              BorderSide(color: Colors.grey[300]!, width: 1.5),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 15,
                      child: GestureDetector(
                        onTap: _toggleRecording,
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: AcademeTheme.appColor,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                child: IconButton(
                  icon:
                      Icon(Icons.send, color: AcademeTheme.appColor, size: 25),
                  onPressed: () {
                    _sendMessage();
                    setState(() {
                      _textController
                          .clear(); // Clear input field after sending message
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _textStyle(Color color) {
    return TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600);
  }

  Widget _buildButton(IconData icon, String text, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(text),
    );
  }

  Widget _buildAttachmentOption(BuildContext context, IconData icon,
      String label, Color color, String fileType) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        _pickFile(fileType);
      },
    );
  }

  Widget _languageTile(
      String language, String code, BuildContext modalContext) {
    return ListTile(
      title: Text(language),
      trailing: selectedLanguage == code
          ? Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        setState(() {
          selectedLanguage = code;
        });
        Navigator.pop(modalContext); // Use the passed modalContext
      },
    );
  }

  Widget _buildInitialUI() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Image.asset('assets/icons/ASKMe_dark.png',
                    width: 120.0, height: 120.0),
                SizedBox(height: 15),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: 'Hey there! I am ',
                          style: _textStyle(Colors.black)),
                      TextSpan(
                          text: 'ASKMe', style: _textStyle(Colors.amber[700]!)),
                      TextSpan(
                          text: ' your\npersonal tutor.',
                          style: _textStyle(Colors.black)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            SizedBox(height: 40),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              alignment: WrapAlignment.center,
              children: [
                _buildButton(Icons.help_outline, 'Clear Your Doubts',
                    Colors.lightBlue.shade400),
                _buildButton(
                    Icons.quiz, 'Explain / Quiz', Colors.orange.shade400),
                _buildButton(Icons.upload_file, 'Upload Study Materials',
                    Colors.green.shade500),
                _buildButton(Icons.more_horiz, 'More', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatUI(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(10),
      controller: _scrollController,
      itemCount: chatMessages.length,
      itemBuilder: (context, index) {
        Map<String, String> message = chatMessages[index];
        bool isUser = message["role"] == "user";

        return Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              CircleAvatar(
                backgroundImage: AssetImage("assets/icons/ASKMe_dark.png"),
                radius: 20,
              ),
            if (isUser)
              CircleAvatar(
                backgroundImage: AssetImage("assets/images/userImage.png"),
                radius: 20,
              ),
            if (message.containsKey("fileType") &&
                message["fileType"] == "Image")
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenImage(imagePath: message["fileInfo"]!),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(message["fileInfo"]!),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: isUser
                    ? MediaQuery.of(context).size.width * 0.60
                    : MediaQuery.of(context).size.width * 0.80,
              ),
              padding: EdgeInsets.all(15),
              margin: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          Colors.blue[300]!,
                          Colors.blue[700]!
                        ], // Subtle gradient for user
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null, // No gradient for AI
                color: isUser ? null : Colors.grey[300]!, // Flat color for AI
                borderRadius: BorderRadius.circular(
                    isUser ? 20 : 15), // More rounding for user messages
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                              0.15), // Soft shadow for user messages
                          blurRadius: 6,
                          offset: Offset(2, 4),
                        ),
                      ]
                    : [], // No shadow for AI messages
              ),
              child: Text(
                message["text"]!,
                style: TextStyle(
                  fontSize: 16,
                  color: isUser ? Colors.white : Colors.black,
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Widget newChatIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: AcademeTheme.appColor, shape: BoxShape.circle),
          child: Icon(Icons.chat_bubble_outline, size: 26, color: Colors.white),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
                color: AcademeTheme.appColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            child:
                Center(child: Icon(Icons.add, size: 12, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(home: ASKMe(), debugShowCheckedModeBanner: false));
}
