import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/academe_theme.dart';
import '../../utils/constants/image_strings.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';

class SubtopicViewScreen extends StatefulWidget {
  final String courseId;
  final String topicId;

  const SubtopicViewScreen({
    super.key,
    required this.courseId,
    required this.topicId,
  });

  @override
  State<SubtopicViewScreen> createState() => _SubtopicViewScreenState();
}

class _SubtopicViewScreenState extends State<SubtopicViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> subtopics = [];
  List<Map<String, dynamic>> ongoingSubtopics = [];
  List<Map<String, dynamic>> completedSubtopics = [];
  bool isLoading = true;
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSubtopics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubtopics() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        debugPrint("❌ Missing access token");
        return;
      }
      if (!mounted) {
        return; // Ensure widget is still active before using context
      }

      // Get the language provider before async gap
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      final targetLanguage = languageProvider.locale.languageCode;

      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final allSubtopics = data.map((subtopic) {
          final progress = (subtopic["progress"] ?? 0.0).toDouble();
          return {
            "id": subtopic["id"],
            "title": subtopic["title"],
            "progress": progress,
            "image": subtopic["image"] ?? AImages.typography,
          };
        }).toList();

        setState(() {
          subtopics = allSubtopics;
          ongoingSubtopics = allSubtopics
              .where((s) => s["progress"] > 0 && s["progress"] < 100)
              .toList();
          completedSubtopics =
              allSubtopics.where((s) => s["progress"] == 100).toList();
        });
      } else {
        debugPrint("❌ Failed to fetch subtopics: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching subtopics: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          L10n.getTranslatedText(context, 'Subtopics'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            labelStyle: const TextStyle(fontSize: 16),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 4, color: Colors.blue),
            ),
            tabs: [
              Tab(text: L10n.getTranslatedText(context, 'ALL')),
              Tab(text: L10n.getTranslatedText(context, 'ON GOING')),
              Tab(text: L10n.getTranslatedText(context, 'COMPLETED')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubtopicList(subtopics),
                _buildSubtopicList(ongoingSubtopics),
                _buildSubtopicList(completedSubtopics),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtopicList(List<Map<String, dynamic>> subtopicList) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }
    if (subtopicList.isEmpty) {
      return Center(
          child:
              Text(L10n.getTranslatedText(context, 'No subtopics available')));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: subtopicList.length,
      itemBuilder: (context, index) => _buildSubtopicCard(subtopicList[index]),
    );
  }

  Widget _buildSubtopicCard(Map<String, dynamic> subtopic) {
    return GestureDetector(
      onTap: () => _handleSubtopicTap(subtopic),
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade300, blurRadius: 5, spreadRadius: 2)
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  subtopic["image"],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subtopic["title"],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: (subtopic["progress"] / 100).clamp(0.0, 1.0),
                    color: Colors.blue,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubtopicTap(Map<String, dynamic> subtopic) async {
    await storage.write(key: 'subtopic_id', value: subtopic["id"]);
    // Uncomment when MaterialViewScreen is ready
    // if (mounted) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => MaterialViewScreen(subtopicId: subtopic["id"]),
    //     ),
    //   );
    // }
  }
}
