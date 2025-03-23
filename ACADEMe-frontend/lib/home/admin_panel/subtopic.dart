import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../academe_theme.dart';
import '../../localization/l10n.dart';
import 'TopicQuiz.dart'; // Import the TopicQuiz screen
import 'material.dart'; // Import the MaterialScreen
import 'SubTopicContent.dart';
import '../../localization/language_provider.dart'; // Import the LanguageProvider

class SubtopicScreen extends StatefulWidget {
  final String courseId;
  final String topicId;
  final String courseTitle;
  final String topicTitle;
  final String targetLanguage;

  SubtopicScreen({
    required this.courseId,
    required this.topicId,
    required this.courseTitle,
    required this.topicTitle,
    required this.targetLanguage,
  });

  @override
  _SubtopicScreenState createState() => _SubtopicScreenState();
}

class _SubtopicScreenState extends State<SubtopicScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> subtopics = [];
  List<Map<String, dynamic>> materials = [];
  List<Map<String, dynamic>> quizzes = [];
  bool isMenuOpen = false;
  bool isLoading = true;
  final _storage = FlutterSecureStorage(); // Initialize FlutterSecureStorage

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _tabController = TabController(length: 3, vsync: this); // Initialize TabController
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the TabController
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      isLoading = true;
    });

    await _fetchSubtopics();
    await _fetchMaterials();
    await _fetchQuizzes();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchSubtopics() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/?target_language=$targetLanguage");

    try {
      String? token = await _storage.read(key: "access_token"); // Retrieve token
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token", // Add token to headers
          "Content-Type": "application/json; charset=utf-8",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          subtopics = data.cast<Map<String, dynamic>>();
        });
      } else {
        _showError("Failed to fetch subtopics: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching subtopics: $e");
    }
  }

  Future<void> _fetchMaterials() async {
    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/materials/");

    try {
      String? token = await _storage.read(key: "access_token"); // Retrieve token
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token", // Add token to headers
          "Content-Type": "application/json; charset=utf-8",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          materials = data.cast<Map<String, dynamic>>();
        });
      } else {
        _showError("Failed to fetch materials: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching materials: $e");
    }
  }

  Future<void> _fetchQuizzes() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/quizzes/?target_language=$targetLanguage");

    try {
      String? token = await _storage.read(key: "access_token"); // Retrieve token
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token", // Add token to headers
          "Content-Type": "application/json; charset=utf-8",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          quizzes = data.cast<Map<String, dynamic>>();
        });
      } else {
        _showError("Failed to fetch quizzes: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching quizzes: $e");
    }
  }

  void _addSubtopic() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();

        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Add Subtopic')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: L10n.getTranslatedText(context, 'Title')),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: L10n.getTranslatedText(context, 'Description')),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.getTranslatedText(context, 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                  final success = await _submitSubtopic(
                    title: titleController.text,
                    description: descriptionController.text,
                  );
                  if (success) {
                    Navigator.pop(context);
                    _fetchSubtopics();
                  }
                }
              },
              child: Text(L10n.getTranslatedText(context, 'Add')),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _submitSubtopic({required String title, required String description}) async {
    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/");

    try {
      String? token = await _storage.read(key: "access_token"); // Retrieve token
      if (token == null) {
        _showError("No access token found");
        return false;
      }

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token", // Add token to headers
          "Content-Type": "application/json; charset=utf-8",
        },
        body: json.encode({
          "title": title,
          "description": description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        print("✅ Subtopic added successfully: ${responseData["message"]}");
        return true;
      } else {
        _showError("Failed to add subtopic: ${response.body}");
        return false;
      }
    } catch (e) {
      _showError("Error submitting subtopic: $e");
      return false;
    }
  }

  void _addMaterial() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedType;
        String? category;
        String? filePath;
        String? textContent;
        String? optionalText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add Topic Material"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Type"),
                      items: ["text", "video", "image", "audio", "document"]
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedType = value ?? ""),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Category"),
                      items: ["Notes", "Reference Links", "Practice Questions"]
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => category = value ?? ""),
                    ),
                    if (selectedType == "text") ...[
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(labelText: "Text Content"),
                        onChanged: (value) => setDialogState(() => textContent = value),
                      ),
                    ],
                    if (selectedType != null && selectedType != "text") ...[
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles();
                          if (result != null && result.files.single.path != null) {
                            setDialogState(() {
                              filePath = result.files.single.path!;
                            });
                            print("✅ File picked: $filePath");
                          }
                        },
                        icon: Icon(Icons.attach_file),
                        label: Text(L10n.getTranslatedText(context, 'Attach File')),
                      ),
                      if (filePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Selected: ${filePath!.split('/').last}"),
                        ),
                    ],
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: L10n.getTranslatedText(context, 'Optional Text')),
                      onChanged: (value) => setDialogState(() => optionalText = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.getTranslatedText(context, 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedType != null && category != null) {
                      if (selectedType == "text" && textContent != null) {
                        await _uploadMaterial(
                          type: selectedType!,
                          category: category!,
                          optionalText: optionalText,
                          textContent: textContent,
                        );
                        Navigator.pop(context);
                      } else if (selectedType != "text" && filePath != null) {
                        await _uploadMaterial(
                          type: selectedType!,
                          category: category!,
                          optionalText: optionalText,
                          filePath: filePath,
                        );
                        Navigator.pop(context);
                      } else {
                        _showError("Please fill all required fields!");
                      }
                    } else {
                      _showError("Please select type and category!");
                    }
                  },
                  child: Text(L10n.getTranslatedText(context, 'Upload')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadMaterial({
    required String type,
    required String category,
    String? optionalText,
    String? textContent,
    String? filePath,
  }) async {
    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/materials/");

    try {
      String? token = await _storage.read(key: "access_token"); // Retrieve token
      if (token == null) {
        _showError("No access token found");
        return;
      }

      var request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token"; // Add token to headers
      request.fields["type"] = type;
      request.fields["category"] = category;
      if (optionalText != null) {
        request.fields["optional_text"] = optionalText;
      }
      if (type == "text" && textContent != null) {
        request.fields["text_content"] = textContent;
      } else if (filePath != null) {
        // Determine the MIME type based on the file extension
        String mimeType = _getMimeType(filePath);
        request.files.add(
          await http.MultipartFile.fromPath(
            "file",
            filePath,
            contentType: MediaType.parse(mimeType), // Set the correct MIME type
          ),
        );
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Material uploaded successfully!");
        await _fetchMaterials();
      } else {
        _showError("Failed to upload material: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      _showError("Error uploading material: $e");
    }
  }

  // Helper function to determine the MIME type based on the file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream'; // Fallback MIME type
    }
  }

  void _addQuiz() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();

        return AlertDialog(
          title: Text("Add Topic Quiz"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: L10n.getTranslatedText(context, 'Title')),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: L10n.getTranslatedText(context, 'Description')),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.getTranslatedText(context, 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                  final success = await _submitQuiz(
                    title: titleController.text,
                    description: descriptionController.text,
                  );
                  if (success) {
                    Navigator.pop(context);
                    _fetchQuizzes();
                  }
                }
              },
              child: Text(L10n.getTranslatedText(context, 'Add')),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _submitQuiz({required String title, required String description}) async {
    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/quizzes/");

    try {
      String? token = await _storage.read(key: "access_token"); // Retrieve token
      if (token == null) {
        _showError("No access token found");
        return false;
      }

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token", // Add token to headers
          "Content-Type": "application/json; charset=utf-8",
        },
        body: json.encode({
          "title": title,
          "description": description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        print("✅ Quiz added successfully: ${responseData["message"]}");
        return true;
      } else {
        _showError("Failed to add quiz: ${response.body}");
        return false;
      }
    } catch (e) {
      _showError("Error submitting quiz: $e");
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          "${widget.courseTitle} > ${widget.topicTitle}",
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Set tab text color to white
          unselectedLabelColor: Colors.white.withOpacity(0.5), // Set unselected tab text color
          tabs: [
            Tab(text: L10n.getTranslatedText(context, 'Subtopics')),
            Tab(text: L10n.getTranslatedText(context, 'Topic Materials')),
            Tab(text: L10n.getTranslatedText(context, 'Topic Quizzes')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Subtopics Tab
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: _buildList(subtopics, (item) => _buildSubtopicContent(item)),
          ),

          // Topic's Materials Tab
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: _buildMaterialList(),
          ),

          // Topic's Quizzes Tab
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: _buildQuizList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMenuOpen) ...[
            _buildMenuItem(L10n.getTranslatedText(context, 'Add Subtopic'), Icons.note_add, _addSubtopic),
            SizedBox(height: 10),
            _buildMenuItem(L10n.getTranslatedText(context, 'Add Material'), Icons.upload_file, _addMaterial),
            SizedBox(height: 10),
            _buildMenuItem(L10n.getTranslatedText(context, 'Add Quiz'), Icons.quiz, _addQuiz),
          ],
          FloatingActionButton(
            onPressed: () => setState(() => isMenuOpen = !isMenuOpen),
            backgroundColor: AcademeTheme.appColor,
            child: Icon(isMenuOpen ? Icons.close : Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, Widget Function(Map<String, dynamic>) onTap) {
    return items.isNotEmpty
        ? ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: items.map((item) {
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(item["title"] ?? "No Title"),
            subtitle: Text(item["description"] ?? "No Description"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => onTap(item))),
          ),
        );
      }).toList(),
    )
        : Center(child: Text("No items available"));
  }

  Widget _buildSubtopicContent(Map<String, dynamic> item) {
    return SubTopicContent(
      courseId: widget.courseId,
      topicId: widget.topicId,
      courseTitle: widget.courseTitle,
      topicTitle: widget.topicTitle,
      subtopicId: item["id"],
      subtopicTitle: item["title"] ?? "Subtopic Content",
      // targetLanguage: widget.targetLanguage,
    );
  }

  Widget _buildMaterialList() {
    return materials.isNotEmpty
        ? ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(material["type"] ?? "Unknown"),
            subtitle: Text(material["category"] ?? "No category"),
            trailing: Icon(Icons.open_in_new),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MaterialScreen(
                    courseId: widget.courseId,
                    topicId: widget.topicId,
                    materialId: material["id"],
                    materialType: material["type"],
                    materialCategory: material["category"],
                    optionalText: material["optional_text"],
                    textContent: material["text_content"],
                    fileUrl: material["file_url"],
                  ),
                ),
              );
            },
          ),
        );
      },
    )
        : Center(child: Text(L10n.getTranslatedText(context, 'No materials are available')));
  }

  Widget _buildQuizList() {
    return quizzes.isNotEmpty
        ? ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(quiz["title"] ?? "No Title"),
            subtitle: Text(quiz["description"] ?? "No Description"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TopicQuizScreen(
                    courseId: widget.courseId,
                    topicId: widget.topicId,
                    quizId: quiz["id"],
                    courseTitle: widget.courseTitle,
                    topicTitle: widget.topicTitle,
                    quizTitle: quiz["title"],
                    targetLanguage: widget.targetLanguage,
                  ),
                ),
              );
            },
          ),
        );
      },
    )
        : Center(child: Text(L10n.getTranslatedText(context, 'No quizzes available')));
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onPressed) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(title, style: TextStyle(color: Colors.white)),
      backgroundColor: AcademeTheme.appColor,
    );
  }

  void _handleFileClick(String fileUrl, String fileType) {
    print("📂 Opening file: $fileUrl");
  }
}