import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // For file picking
import 'package:http_parser/http_parser.dart'; // For multipart requests
import 'material.dart'; // Import the MaterialScreen
import 'subtopic_quiz.dart'; // Import the SubTopicQuiz screen
import 'package:provider/provider.dart';
import '../../localization/language_provider.dart'; // Import the LanguageProvider

class SubTopicContent extends StatefulWidget {
  final String courseId;
  final String topicId;
  final String subtopicId;
  final String courseTitle;
  final String topicTitle;
  final String subtopicTitle;

  const SubTopicContent({
    super.key,
    required this.courseId,
    required this.topicId,
    required this.subtopicId,
    required this.courseTitle,
    required this.topicTitle,
    required this.subtopicTitle,
  });

  @override
  SubTopicContentState createState() => SubTopicContentState();
}

class SubTopicContentState extends State<SubTopicContent>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> subtopicMaterials = [];
  List<Map<String, dynamic>> subtopicQuizzes = [];
  bool isLoading = true;
  bool isMenuOpen = false; // Track if the FAB menu is open
  final _storage = FlutterSecureStorage(); // Initialize FlutterSecureStorage

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _tabController =
        TabController(length: 2, vsync: this); // Initialize TabController
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

    await _fetchSubtopicMaterials();
    await _fetchSubtopicQuizzes();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchSubtopicMaterials() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/${widget.subtopicId}/materials/?target_language=$targetLanguage");

    try {
      String? token =
          await _storage.read(key: "access_token"); // Retrieve token
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
          subtopicMaterials = data.cast<Map<String, dynamic>>();
        });
      } else {
        _showError(
            "Failed to fetch subtopic materials: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching subtopic materials: $e");
    }
  }

  Future<void> _fetchSubtopicQuizzes() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/${widget.subtopicId}/quizzes/?target_language=$targetLanguage");

    try {
      String? token =
          await _storage.read(key: "access_token"); // Retrieve token
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
          subtopicQuizzes = data.cast<Map<String, dynamic>>();
        });
      } else {
        _showError("Failed to fetch subtopic quizzes: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching subtopic quizzes: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    debugPrint(message);
  }

  void _addSubtopicMaterial() {
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
              title: Text(L10n.getTranslatedText(context, 'Add Subtopic Material')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: L10n.getTranslatedText(context, 'Type')),
                      items: ["text", "video", "image", "audio", "document"]
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedType = value ?? ""),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: L10n.getTranslatedText(context, 'Category')),
                      items: ["Notes", "Reference Links", "Practice Questions"]
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => category = value ?? ""),
                    ),
                    if (selectedType == "text") ...[
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(labelText: "Text Content"),
                        onChanged: (value) =>
                            setDialogState(() => textContent = value),
                      ),
                    ],
                    if (selectedType != null && selectedType != "text") ...[
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles();
                          if (result != null &&
                              result.files.single.path != null) {
                            setDialogState(() {
                              filePath = result.files.single.path!;
                            });
                            debugPrint("✅ File picked: $filePath");
                          }
                        },
                        icon: Icon(Icons.attach_file),
                        label: Text("Attach File"),
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
                      onChanged: (value) =>
                          setDialogState(() => optionalText = value),
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
                        if (!context.mounted) {
                          return; // Now properly wrapped in a block
                        }
                        Navigator.pop(context);
                      } else if (selectedType != "text" && filePath != null) {
                        await _uploadMaterial(
                          type: selectedType!,
                          category: category!,
                          optionalText: optionalText,
                          filePath: filePath,
                        );
                        if (!context.mounted) {
                          return; // Now properly wrapped in a block
                        }
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
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/${widget.subtopicId}/materials/");

    try {
      String? token =
          await _storage.read(key: "access_token"); // Retrieve token
      if (token == null) {
        _showError("No access token found");
        return;
      }

      var request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] =
          "Bearer $token"; // Add token to headers
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
        debugPrint("✅ Material uploaded successfully!");
        await _fetchSubtopicMaterials(); // Refresh the materials list
      } else {
        _showError(
            "Failed to upload material: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      _showError("Error uploading material: $e");
    }
  }

  void _addSubtopicQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descriptionController =
            TextEditingController();

        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Add Subtopic Quiz')),
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
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  final success = await _submitQuiz(
                    title: titleController.text,
                    description: descriptionController.text,
                  );
                  if (!context.mounted) {
                    return; // Now properly wrapped in a block
                  }
                  if (success) {
                    Navigator.pop(context);
                    _fetchSubtopicQuizzes(); // Refresh the quizzes list
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

  Future<bool> _submitQuiz({
    required String title,
    required String description,
  }) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/${widget.subtopicId}/quizzes/");

    try {
      String? token =
          await _storage.read(key: "access_token"); // Retrieve token
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
          "target_language": targetLanguage, // Pass the target language
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        debugPrint("✅ Quiz added successfully: ${responseData["message"]}");
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final targetLanguage = languageProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(widget.subtopicTitle,
            style: TextStyle(color: AcademeTheme.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Set tab text color to white
          unselectedLabelColor:
              Colors.white.withValues(), // Set unselected tab text color
          tabs: [
            Tab(text: L10n.getTranslatedText(context, 'Subtopic Materials')),
            Tab(text: L10n.getTranslatedText(context, 'Subtopic Quizzes')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Subtopic Materials Tab
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: _buildMaterialList(),
                ),

          // Subtopic Quizzes Tab
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: _buildQuizList(targetLanguage, context),
                ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMenuOpen) ...[
            _buildMenuItem(
                L10n.getTranslatedText(context, 'Add Subtopic Materials'),
                Icons.note_add,
                _addSubtopicMaterial),
            SizedBox(height: 10),
            _buildMenuItem(
                L10n.getTranslatedText(context, 'Add Subtopic Quizzes'),
                Icons.quiz,
                _addSubtopicQuestion),
            SizedBox(height: 10),
          ],
          FloatingActionButton(
            onPressed: () => setState(() => isMenuOpen = !isMenuOpen),
            backgroundColor: AcademeTheme.appColor,
            child:
                Icon(isMenuOpen ? Icons.close : Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialList() {
    return subtopicMaterials.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: subtopicMaterials.length,
            itemBuilder: (context, index) {
              final material = subtopicMaterials[index];
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
                          subtopicId: widget.subtopicId, // Add subtopicId
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
        : Center(child: Text("No materials available"));
  }

  Widget _buildQuizList(String targetLanguage, BuildContext context) {
    return subtopicQuizzes.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: subtopicQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = subtopicQuizzes[index];
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
                        builder: (_) => SubTopicQuizScreen(
                          courseId: widget.courseId,
                          topicId: widget.topicId,
                          subtopicId: widget.subtopicId,
                          quizId: quiz["id"],
                          courseTitle: widget.courseTitle,
                          topicTitle: widget.topicTitle,
                          subtopicTitle: widget.subtopicTitle,
                          targetLanguage: targetLanguage,
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
}
