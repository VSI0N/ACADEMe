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

// Singleton cache manager for subtopics
class SubtopicCacheManager {
  static final SubtopicCacheManager _instance = SubtopicCacheManager._internal();
  factory SubtopicCacheManager() => _instance;
  SubtopicCacheManager._internal();

  final Map<String, CachedSubtopicData> _cache = {};
  DateTime? _appStartTime;

  void setAppStartTime() {
    _appStartTime = DateTime.now();
  }

  bool shouldRefreshCache(String key) {
    if (_appStartTime == null) return true;

    final cachedData = _cache[key];
    if (cachedData == null) return true;

    // Refresh if cached before app start (from previous session)
    if (cachedData.timestamp.isBefore(_appStartTime!)) return true;

    // Refresh if cache is older than 10 minutes (configurable)
    final cacheAge = DateTime.now().difference(cachedData.timestamp);
    return cacheAge.inMinutes > 10;
  }

  void cacheSubtopics(String key, List<Map<String, dynamic>> subtopics, String language) {
    _cache[key] = CachedSubtopicData(
      subtopics: subtopics,
      language: language,
      timestamp: DateTime.now(),
    );
  }

  CachedSubtopicData? getCachedSubtopics(String key, String currentLanguage) {
    final cachedData = _cache[key];
    if (cachedData == null) return null;

    // Invalidate cache if language changed
    if (cachedData.language != currentLanguage) return null;

    return cachedData;
  }

  void clearCache() {
    _cache.clear();
  }

  void removeCacheEntry(String key) {
    _cache.remove(key);
  }
}

class CachedSubtopicData {
  final List<Map<String, dynamic>> subtopics;
  final String language;
  final DateTime timestamp;

  CachedSubtopicData({
    required this.subtopics,
    required this.language,
    required this.timestamp,
  });
}

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  List<Map<String, dynamic>> subtopics = [];
  List<Map<String, dynamic>> ongoingSubtopics = [];
  List<Map<String, dynamic>> completedSubtopics = [];
  bool isLoading = true;
  bool isRefreshing = false;
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final SubtopicCacheManager _cacheManager = SubtopicCacheManager();

  String get _cacheKey => '${widget.courseId}_${widget.topicId}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _loadSubtopics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, check if we need to refresh
      _checkAndRefreshIfNeeded();
    }
  }

  Future<void> _checkAndRefreshIfNeeded() async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;

    if (_cacheManager.shouldRefreshCache(_cacheKey) ||
        _cacheManager.getCachedSubtopics(_cacheKey, currentLanguage) == null) {
      await _fetchSubtopicsFromAPI(showRefreshIndicator: true);
    }
  }

  Future<void> _loadSubtopics() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;

    // Try to load from cache first
    final cachedData = _cacheManager.getCachedSubtopics(_cacheKey, currentLanguage);

    if (cachedData != null && !_cacheManager.shouldRefreshCache(_cacheKey)) {
      // Use cached data
      _updateSubtopicLists(cachedData.subtopics);
      setState(() => isLoading = false);

      // Optional: Fetch fresh data in background for next time
      _fetchSubtopicsFromAPI(showRefreshIndicator: false);
    } else {
      // Fetch fresh data
      await _fetchSubtopicsFromAPI(showRefreshIndicator: false);
    }
  }

  Future<void> _fetchSubtopicsFromAPI({bool showRefreshIndicator = false}) async {
    if (!mounted) return;

    if (showRefreshIndicator) {
      setState(() => isRefreshing = true);
    }

    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        debugPrint("❌ Missing access token");
        return;
      }

      if (!mounted) return;

      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
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

        // Cache the fresh data
        _cacheManager.cacheSubtopics(_cacheKey, allSubtopics, targetLanguage);

        _updateSubtopicLists(allSubtopics);
      } else {
        debugPrint("❌ Failed to fetch subtopics: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching subtopics: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  void _updateSubtopicLists(List<Map<String, dynamic>> allSubtopics) {
    setState(() {
      subtopics = allSubtopics;
      ongoingSubtopics = allSubtopics
          .where((s) => s["progress"] > 0 && s["progress"] < 100)
          .toList();
      completedSubtopics =
          allSubtopics.where((s) => s["progress"] == 100).toList();
    });
  }

  Future<void> _onRefresh() async {
    await _fetchSubtopicsFromAPI(showRefreshIndicator: true);
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
        actions: [
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isRefreshing ? null : _onRefresh,
          ),
        ],
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
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSubtopicList(subtopics),
                  _buildSubtopicList(ongoingSubtopics),
                  _buildSubtopicList(completedSubtopics),
                ],
              ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(L10n.getTranslatedText(context, 'No subtopics available')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: Text(L10n.getTranslatedText(context, 'Refresh')),
            ),
          ],
        ),
      );
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