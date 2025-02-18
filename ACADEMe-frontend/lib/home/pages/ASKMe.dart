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
          .where((language) =>
          language['name']!.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList(); // Filter the languages based on the search query
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose(); // Keep only this
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      // Optional: Add logic if needed when the user scrolls
    });
  }


  void _showPromptDialog(File file, String fileType) {
    TextEditingController promptController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("Add Optional Prompt"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.attach_file),
                  title: Text(file.path
                      .split('/')
                      .last),
                  subtitle: Text(
                      "${(file.lengthSync() / 1024).toStringAsFixed(1)}KB"),
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
        return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
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


  Future<void> _uploadFile(File file, String fileType, [String prompt = '']) async {
    //ASKMe backend URL
    var url = Uri.parse('http://10.0.2.2:8000/api/process_${fileType.toLowerCase()}');

    var request = http.MultipartRequest('POST', url);
    request.fields.addAll({
      'prompt': prompt.isNotEmpty ? prompt : 'Describe this image',
      'source_lang': 'auto',
      'target_lang': selectedLanguage,
    });

    String fileFieldName = (fileType == 'Image') ? 'image' : 'file';
    request.files.add(await http.MultipartFile.fromPath(fileFieldName, file.path));

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
            "fileInfo": file.path,  // ✅ Save the image file path
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
      String? path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null && File(path).existsSync()) {
        await _uploadFile(File(path), "Audio"); // ✅ No need to pass an empty prompt manually
      } else {
        print("Recording failed or file not found");
      }
    } else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();

      if (statuses[Permission.microphone]?.isGranted == true &&
          statuses[Permission.storage]?.isGranted == true) {
        Directory tempDir = await getTemporaryDirectory();
        String filePath = '${tempDir.path}/recording.m4a';

        await _audioRecorder.start(
          RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
        setState(() => _isRecording = true);
      } else {
        print("Permission denied");
      }
    }
  }


  void _sendMessage() async {
    String message = _textController.text.trim();
    if (message.isNotEmpty) {
      //ASKMe backend URL
      var url = Uri.parse('http://10.0.2.2:8000/api/process_text');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'text': message,
          'target_language': selectedLanguage
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          chatMessages.add({"role": "user", "text": message});
          chatMessages.add(
              {"role": "ai", "text": jsonDecode(response.body)['response']});
          _textController.clear();
        });

        // Scroll to the bottom after a short delay to ensure UI updates first
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
                .where((language) =>
                language['name']!.toLowerCase().startsWith(searchQuery.toLowerCase()))
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
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Opacity(opacity: 0,
                child: IconButton(icon: Icon(Icons.menu), onPressed: () {})),
            Expanded(
              child: Text(
                'ASKMe',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: newChatIcon(), onPressed: () {}),
                IconButton(
                  icon: Icon(Icons.more_vert, size: 28, color: Colors.white),
                  onPressed: () {
                    _showLanguageSelection();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: chatMessages.isEmpty
          ? _buildInitialUI()
          : _buildChatUI(context),
      bottomNavigationBar: AnimatedPadding(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Adjusts when keyboard appears
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: Icon(Icons.attach_file, color: AcademeTheme.appColor, size: 27),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (BuildContext context) {
                        return Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAttachmentOption(context, Icons.image, "Image", Colors.blue, 'Image'),
                              _buildAttachmentOption(context, Icons.insert_drive_file, "Document", Colors.green, 'Document'),
                              _buildAttachmentOption(context, Icons.video_library, "Video", Colors.orange, 'Video'),
                              _buildAttachmentOption(context, Icons.audiotrack, "Audio", Colors.purple, 'Audio'),
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
                  alignment: Alignment.centerRight, // Align mic icon inside TextField
                  children: [
                    TextField(
                      controller: _textController,
                      maxLines: 2, // Single-line input
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        contentPadding: EdgeInsets.only(left: 20, right: 60, top: 14, bottom: 14), // Adjusted padding
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded shape
                          borderSide: BorderSide(color: Colors.grey, width: 1.5), // Outline border
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey, width: 1.5), // Subtle gray outline
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5), // Highlighted color when active
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

              SizedBox(width: 12), // Added space between text field and send button

              Container(
                width: 42,
                height: 42,
                // decoration: BoxDecoration(
                //   shape: BoxShape.circle,
                //   color: AcademeTheme.appColor,
                // ),
                child: IconButton(
                  icon: Icon(Icons.send, color: AcademeTheme.appColor, size: 25),
                  onPressed: _sendMessage,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),


              // Container(
              //   width: 30,
              //   height: 30,
              //   decoration: BoxDecoration(shape: BoxShape.circle, color: AcademeTheme.appColor),
              //   child: IconButton(
              //     icon: Icon(Icons.send, color: Colors.white, size: 24),
              //     onPressed: _sendMessage,
              //     padding: EdgeInsets.zero,
              //     constraints: BoxConstraints(),
              //   ),
              // ),
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
      title: Text(
          label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        _pickFile(fileType);
      },
    );
  }

  Widget _languageTile(String language, String code, BuildContext modalContext) {
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
                Image.asset(
                    'assets/icons/ASKMe_dark.png', width: 120.0, height: 120.0),
                SizedBox(height: 15),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Hey there! I am ',
                          style: _textStyle(Colors.black)),
                      TextSpan(
                          text: 'ASKMe', style: _textStyle(Colors.amber[700]!)),
                      TextSpan(text: ' your\npersonal tutor.',
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
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            if (message.containsKey("fileType") && message["fileType"] == "Image")
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(imagePath: message["fileInfo"]!),
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
                  colors: [Colors.blue[300]!, Colors.blue[700]!], // Subtle gradient for user
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null, // No gradient for AI
                color: isUser ? null : Colors.grey[300]!, // Flat color for AI
                borderRadius: BorderRadius.circular(isUser ? 20 : 15), // More rounding for user messages
                boxShadow: isUser
                    ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15), // Soft shadow for user messages
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
            decoration: BoxDecoration(color: AcademeTheme.appColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            child: Center(
                child: Icon(Icons.add, size: 12, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(home: ASKMe(), debugShowCheckedModeBanner: false));
}
