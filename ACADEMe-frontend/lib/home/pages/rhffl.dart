import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_file/open_file.dart';
import 'package:ACADEMe/widget/audio_payer_widget.dart';
import 'package:ACADEMe/widget/full_screen_video.dart';
import 'package:ACADEMe/widget/typing_indicator.dart';

class AskMe extends StatefulWidget {
  String? initialMessage;
  AskMe({super.key, this.initialMessage});

  @override
  AskMeState createState() => AskMeState();
}

class AskMeState extends State<AskMe> {
  final ScrollController _scrollController = ScrollController();
  String selectedLanguage = "en"; // Default: English
  List<Map<String, dynamic>> chatMessages = [];

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
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // For the chat history

  void _loadChatSession(ChatSession chat) {
    debugPrint("Selected chat: ${chat.title}");
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
    if (widget.initialMessage != null) {
      _sendMessage(widget.initialMessage!);
    }
  }

  Future<void> _initRecorder() async {
    bool hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      debugPrint("Recording permission not granted.");
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
        debugPrint("❌ Invalid file type.");
        return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions:
      (type == FileType.custom) ? allowedExtensions : null, // ✅ Fix
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      _showPromptDialog(file, fileType);
    } else {
      debugPrint("❌ File selection canceled.");
    }
  }

  Future<void> _uploadFile(File file, String fileType,
      [String prompt = '']) async {
    var url = Uri.parse(
        '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/process_${fileType.toLowerCase()}');

    var request = http.MultipartRequest('POST', url);
    request.fields.addAll({
      'prompt': prompt.isNotEmpty ? prompt : 'Describe this file',
      'source_lang': 'auto',
      'target_lang': selectedLanguage,
    });

    String fileFieldName = (fileType == 'Image') ? 'image' : 'file';
    String? mimeType = lookupMimeType(file.path);
    mimeType ??=
    (fileType == 'Video') ? 'video/mp4' : 'application/octet-stream';

    request.files.add(await http.MultipartFile.fromPath(
      fileFieldName,
      file.path,
      contentType: MediaType.parse(mimeType),
    ));

    // Add user message to chat
    setState(() {
      chatMessages.add({
        "role": "user",
        "text": prompt.isNotEmpty ? prompt : "Uploaded $fileType",
        "fileInfo": file.path,
        "fileType": fileType,
        "status": prompt.isNotEmpty ? prompt : "Processing..."
      });

      // Add a "typing indicator" for the AI response
      chatMessages.add({
        "role": "assistant",
        "text": "...",
        "isTyping": true, // ✅ Used to identify typing indicator
      });
    });

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(responseBody);
        String aiResponse = decodedResponse is Map<String, dynamic>
            ? decodedResponse.values.first.toString()
            : responseBody;

        setState(() {
          // Remove typing indicator
          chatMessages.removeWhere((msg) => msg["isTyping"] == true);

          // Add actual AI response
          chatMessages.add({
            "role": "assistant",
            "text": aiResponse,
          });
        });
      } else {
        setState(() {
          chatMessages.removeWhere((msg) => msg["isTyping"] == true);
          chatMessages.add({
            "role": "assistant",
            "text": "⚠️ Error uploading file: $responseBody",
          });
        });
      }
    } catch (e) {
      setState(() {
        chatMessages.removeWhere((msg) => msg["isTyping"] == true);
        chatMessages.add({
          "role": "assistant",
          "text": "⚠️ Error connecting to server.",
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
        debugPrint(
            "Audio file path: $path, Size: ${file.existsSync() ? file.lengthSync() : 'File not found'} bytes");

        if (file.existsSync()) {
          debugPrint("File exists, uploading...");
          await _uploadSpeech(file);
        } else {
          debugPrint("File does NOT exist. Path: $path");
        }
      } else {
        debugPrint("Recording path is null.");
      }
    } else {
      // Request microphone permission
      PermissionStatus micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint("Microphone permission not granted.");

        return;
      }

      // Prepare file path for recording in WAV format
      Directory tempDir = await getApplicationDocumentsDirectory();
      String filePath =
          '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      try {
        // Start recording with WAV format
        debugPrint("Starting recording at path: $filePath");
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
        debugPrint("Error starting recording: $e");
      }
    }
  }

// Upload Speech Function
  Future<void> _uploadSpeech(File file) async {
    try {
      if (!file.existsSync() || file.lengthSync() == 0) {
        debugPrint("❌ File does not exist or is empty.");
        return;
      }
      debugPrint("File size: ${file.lengthSync()} bytes");

      setState(() {
        isConverting = true;
      });

      // Backend API URL
      var url = Uri.parse(
          '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/process_stt');

      var request = http.MultipartRequest('POST', url);

      // Ensure the selected language is not empty
      selectedLanguage = selectedLanguage.isNotEmpty ? selectedLanguage : "hi";
      debugPrint("Selected target language: $selectedLanguage");

      request.fields.addAll({
        'prompt': 'इस ऑडियो को हिंदी में लिखो',
        'source_lang': 'auto', // Let the server detect the source language
        'target_lang':
        selectedLanguage, // Send the selected language for the response
      });

      final mimeType = lookupMimeType(file.path) ?? "audio/flac";
      debugPrint("Detected MIME type: $mimeType");

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ));

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      debugPrint("Server response: $responseBody");

      if (response.statusCode == 200) {
        debugPrint("✅ Audio uploaded successfully!");

        var decodedResponse = jsonDecode(responseBody);

        // Fix: Extract detected language correctly
        String detectedLang = decodedResponse['language'] ?? 'unknown';
        debugPrint("Detected Language: $detectedLang");

        // If the detected language is Hindi and user hasn't explicitly chosen another language
        if (detectedLang == 'hi' && selectedLanguage == "auto") {
          setState(() {
            selectedLanguage =
            'hi'; // Update language to Hindi if detected language is Hindi
          });
          debugPrint("✅ Updated selected language to Hindi");
        }

        // Proceed with handling the server response (your AI response)
        await _handleServerResponse(decodedResponse);
      } else {
        debugPrint("❌ Upload failed with status: ${response.statusCode}");
        debugPrint("Server response: $responseBody");

        setState(() {
          chatMessages.add({
            "role": "assistant",
            "text": "❌ Audio upload failed. Server response: $responseBody",
          });
        });
      }
    } catch (e) {
      debugPrint("❌ Error uploading audio: $e");
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
        debugPrint("❌ No text key in server response");
      }
    } catch (e) {
      debugPrint("❌ Error handling server response: $e");
    }
  }

  // Send Message Function
  void _sendMessage(String message) async {
    setState(() {
      chatMessages.add({"role": "user", "text": message});
      chatMessages.add({"role": "ai", "isTyping": true}); // Typing Indicator
    });

    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    var url = Uri.parse(
        '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/process_text');

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': message, 'target_language': selectedLanguage},
      );

      if (response.statusCode == 200) {
        String aiResponse = utf8.decode(response.bodyBytes);
        String aiMessage = jsonDecode(aiResponse)['response'];

        setState(() {
          chatMessages[chatMessages.length - 1] = {
            "role": "ai",
            "text": aiMessage,
            "isTyping": false
          };
        });

        Future.delayed(Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } else {
        setState(() {
          chatMessages[chatMessages.length - 1] = {
            "role": "ai",
            "text": "Oops! Something went wrong. Please try again.",
            "isTyping": false
          };
        });
      }
    } catch (error) {
      setState(() {
        chatMessages[chatMessages.length - 1] = {
          "role": "ai",
          "text":
          "Error connecting to the server. Please check your internet connection.",
          "isTyping": false
        };
      });
    }
  }

  void _showLanguageSelection() {
    showModalBottomSheet(
      context: context,
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
                    L10n.getTranslatedText(context, 'Select Output Language'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),

                  // Search bar with live filtering
                  TextField(
                    decoration: InputDecoration(
                      labelText:
                      L10n.getTranslatedText(context, 'Search Languages'),
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
    List<ChatSession> chatHistory = [
      ChatSession(
          title: L10n.getTranslatedText(context, 'Chat with AI'),
          timestamp: "Feb 22, 2025"),
      ChatSession(
          title: L10n.getTranslatedText(context, 'Math Help'),
          timestamp: "Feb 21, 2025"),
    ];

    return Scaffold(
      key: _scaffoldKey, // Attach key to control drawer
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // Removes the reserved space for the menu
        title: SizedBox(
          height: kToolbarHeight, // Ensures full height usage
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.menu, size: 28, color: Colors.white), // Custom menu icon
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer(); // Open the drawer
                  },
                ),
              ),
              Center(
                child: Text(
                  'ASKMe',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
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
              ),
            ],
          ),
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
              SizedBox(
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
                                  L10n.getTranslatedText(context, 'Image'), Colors.blue, 'Image'),
                              _buildAttachmentOption(
                                  context,
                                  Icons.insert_drive_file,
                                  L10n.getTranslatedText(context, 'Document'),
                                  Colors.green,
                                  'Document'),
                              _buildAttachmentOption(
                                  context,
                                  Icons.video_library,
                                  L10n.getTranslatedText(context, 'Video'),
                                  Colors.orange,
                                  'Video'),
                              _buildAttachmentOption(context, Icons.audiotrack,
                                  L10n.getTranslatedText(context, 'Audio'), Colors.purple, 'Audio'),
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
                            ? L10n.getTranslatedText(context, 'Converting ... ')
                            : (_isRecording
                            ? L10n.getTranslatedText(
                            context, 'Recording ... ${_seconds}s')
                            : L10n.getTranslatedText(
                            context, 'Type a message ...')),
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
              SizedBox(
                width: 42,
                height: 42,
                child: IconButton(
                  icon:
                  Icon(Icons.send, color: AcademeTheme.appColor, size: 25),
                  onPressed: () {
                    String message = _textController.text.trim();
                    _sendMessage(message);
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
                          text: L10n.getTranslatedText(
                              context, 'Hey there! I am '),
                          style: _textStyle(Colors.black)),
                      TextSpan(
                          text: 'ASKMe', style: _textStyle(Colors.amber[700]!)),
                      TextSpan(
                          text: L10n.getTranslatedText(
                              context, ' your\npersonal tutor.'),
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
                _buildButton(
                    Icons.help_outline,
                    L10n.getTranslatedText(context, 'Clear Your Doubts'),
                    Colors.lightBlue.shade400),
                _buildButton(
                    Icons.quiz,
                    L10n.getTranslatedText(context, 'Explain / Quiz'),
                    Colors.orange.shade400),
                _buildButton(
                    Icons.upload_file,
                    L10n.getTranslatedText(context, 'Upload Study Materials'),
                    Colors.green.shade500),
                _buildButton(Icons.more_horiz,
                    L10n.getTranslatedText(context, 'More'), Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatUI(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      padding: EdgeInsets.all(10),
      controller: _scrollController,
      itemCount: chatMessages.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> message = chatMessages[index];
        bool isUser = message["role"] == "user";

        return Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Display Image
            if (message.containsKey("fileType") &&
                message["fileType"] == "Image")
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenImage(imagePath: message["fileInfo"]),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(message["fileInfo"]),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Display Video
            if (message.containsKey("fileType") &&
                message["fileType"] == "Video")
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenVideo(videoPath: message["fileInfo"]),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black12,
                      ),
                    ),
                    Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
                  ],
                ),
              ),

            // Display Audio
            if (message.containsKey("fileType") &&
                message["fileType"] == "Audio")
              Container(
                width: MediaQuery.of(context).size.width * 0.75,
                margin: EdgeInsets.symmetric(vertical: 5),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AudioPlayerWidget(audioPath: message["fileInfo"]),
              ),

            // Display Document
            if (message.containsKey("fileType") &&
                message["fileType"] != "Image" &&
                message["fileType"] != "Video" &&
                message["fileType"] != "Audio")
              GestureDetector(
                onTap: () {
                  OpenFile.open(message["fileInfo"]);
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.55,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Open Document",
                          style: TextStyle(color: Colors.blue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Chat Message Bubble
            if (message.containsKey("text") && message["isTyping"] != true)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
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
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : null,
                          color: isUser ? null : Colors.grey[300]!,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isUser
                              ? [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 6,
                              offset: Offset(2, 4),
                            ),
                          ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _parseInlineBoldText(message["text"], isUser),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (!isUser && message["isTyping"] != true)
              Positioned(
                bottom: -10,
                left: 0,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.flag, color: Colors.grey[600], size: 18),
                      onPressed: () {
                        _showReportDialog(context, message);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.content_copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: message["text"]));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // Typing Indicator
            if (message["isTyping"] == true) TypingIndicator(),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, Map<String, dynamic> message) {
    TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Report Message')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              TextField(
                controller: reportController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "${L10n.getTranslatedText(context, 'Enter your reason for reporting')}...",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.getTranslatedText(context, 'Cancel')),
            ),
            TextButton(
              onPressed: () {
                _submitReport(message, reportController.text);
                Navigator.pop(context);
              },
              child: Text(L10n.getTranslatedText(context, 'Send')),
            ),
          ],
        );
      },
    );
  }

  void _submitReport(Map<String, dynamic> message, String reportReason) {
    print("Reported message: ${message["text"]} | Reason: $reportReason");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Report submitted."),
        duration: Duration(seconds: 2),
      ),
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

  /// **Helper function to parse inline bold text (e.g., *bold* or **bold**)**
  Widget _parseInlineBoldText(String text, bool isUser) {
    List<InlineSpan> spans = [];
    List<String> parts = text.split(RegExp(r'(\*\*|\*)'));

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // Odd indices are bold text (treat as keys)
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isUser ? Colors.white : Colors.black87,
          ),
        ));
      } else {
        // Even indices are regular text (treat as values)
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            fontSize: 16,
            color: isUser ? Colors.white : Colors.black87,
          ),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}