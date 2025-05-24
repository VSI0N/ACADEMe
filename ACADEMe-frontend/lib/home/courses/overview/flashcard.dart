import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../localization/language_provider.dart';
import '../../../widget/whatsapp_audio.dart';
import 'quiz.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Global cache manager for topic details
class TopicCacheManager {
  static final TopicCacheManager _instance = TopicCacheManager._internal();
  factory TopicCacheManager() => _instance;
  TopicCacheManager._internal();

  final Map<String, Map<String, dynamic>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, bool> _fetchInProgress = {};

  // Increased cache duration to 24 hours for better performance
  static const Duration _cacheDuration = Duration(hours: 24);

  String _getCacheKey(String courseId, String topicId, String language) {
    return '${courseId}_${topicId}_$language';
  }

  Map<String, dynamic>? getCachedData(String courseId, String topicId, String language) {
    final key = _getCacheKey(courseId, topicId, language);
    final timestamp = _cacheTimestamps[key];

    if (timestamp == null || DateTime.now().difference(timestamp) > _cacheDuration) {
      // Cache expired or doesn't exist
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _cache[key];
  }

  void setCachedData(String courseId, String topicId, String language, Map<String, dynamic> data) {
    final key = _getCacheKey(courseId, topicId, language);
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    _fetchInProgress[key] = false;
  }

  bool isFetchInProgress(String courseId, String topicId, String language) {
    final key = _getCacheKey(courseId, topicId, language);
    return _fetchInProgress[key] ?? false;
  }

  void setFetchInProgress(String courseId, String topicId, String language, bool inProgress) {
    final key = _getCacheKey(courseId, topicId, language);
    _fetchInProgress[key] = inProgress;
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _fetchInProgress.clear();
  }

  void clearCacheForTopic(String courseId, String topicId) {
    final keysToRemove = _cache.keys
        .where((key) => key.startsWith('${courseId}_$topicId'))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _fetchInProgress.remove(key);
    }
  }
}

// App lifecycle manager to track app state
class AppLifecycleManager {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  DateTime? _lastAppOpenTime;
  DateTime? _sessionStartTime;
  bool _isFirstOpenAfterAppStart = true;
  final Set<String> _fetchedTopicsInSession = {};

  bool get shouldRefreshCache {
    if (_isFirstOpenAfterAppStart) {
      _isFirstOpenAfterAppStart = false;
      _sessionStartTime = DateTime.now();
      _lastAppOpenTime = DateTime.now();
      return true;
    }

    // Refresh if app was closed for more than 1 hour
    if (_lastAppOpenTime == null ||
        DateTime.now().difference(_lastAppOpenTime!) > const Duration(hours: 1)) {
      _sessionStartTime = DateTime.now();
      _lastAppOpenTime = DateTime.now();
      _fetchedTopicsInSession.clear();
      return true;
    }

    return false;
  }

  bool shouldFetchTopicInSession(String courseId, String topicId) {
    final topicKey = '${courseId}_$topicId';
    return !_fetchedTopicsInSession.contains(topicKey);
  }

  void markTopicFetchedInSession(String courseId, String topicId) {
    final topicKey = '${courseId}_$topicId';
    _fetchedTopicsInSession.add(topicKey);
  }

  void markAppAsOpened() {
    _lastAppOpenTime = DateTime.now();
  }

  void startNewSession() {
    _sessionStartTime = DateTime.now();
    _fetchedTopicsInSession.clear();
  }
}

class FlashCard extends StatefulWidget {
  final List<Map<String, String>> materials;
  final List<Map<String, dynamic>> quizzes;
  final Function()? onQuizComplete;
  final int initialIndex;
  final String courseId;
  final String topicId;
  final String subtopicId;
  final String subtopicTitle;

  const FlashCard({
    super.key,
    required this.materials,
    required this.quizzes,
    this.onQuizComplete,
    this.initialIndex = 0,
    required this.courseId,
    required this.topicId,
    required this.subtopicId,
    required this.subtopicTitle,
  });

  @override
  FlashCardState createState() => FlashCardState();
}

class FlashCardState extends State<FlashCard> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentPage = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasNavigated = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  String topicTitle = "Loading...";
  bool _showSwipeHint = true;
  bool isLoading = true;

  // Cache managers
  final TopicCacheManager _cacheManager = TopicCacheManager();
  final AppLifecycleManager _lifecycleManager = AppLifecycleManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.initialIndex;
    _loadSwipeHintState();
    _initializeTopicData();

    if (widget.materials.isEmpty && widget.quizzes.isEmpty) {
      Future.delayed(Duration.zero, () {
        if (widget.onQuizComplete != null) {
          widget.onQuizComplete!();
        }
      });
    } else {
      _setupVideoController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _lifecycleManager.markAppAsOpened();

      // Optional: Refresh data if app was in background for too long
      if (_lifecycleManager.shouldRefreshCache) {
        debugPrint("🔄 App resumed after long time, refreshing cache");
        _initializeTopicData();
      }
    } else if (state == AppLifecycleState.paused) {
      // App is going to background
      debugPrint("📱 App paused");
    }
  }

  Future<void> _loadSwipeHintState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showSwipeHint = prefs.getBool('show_swipe_hint') ?? true;
    });
  }

  void _handleSwipe() async {
    if (_showSwipeHint) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_swipe_hint', false);
      setState(() {
        _showSwipeHint = false;
      });
    }
  }

  Future<void> _initializeTopicData() async {
    if (!mounted) return;

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    // Check if fetch is already in progress
    if (_cacheManager.isFetchInProgress(widget.courseId, widget.topicId, targetLanguage)) {
      debugPrint("🔄 Fetch already in progress, waiting...");
      return;
    }

    // Check cache first
    final cachedData = _cacheManager.getCachedData(
        widget.courseId,
        widget.topicId,
        targetLanguage
    );

    final shouldRefresh = _lifecycleManager.shouldRefreshCache;
    final shouldFetch = _lifecycleManager.shouldFetchTopicInSession(widget.courseId, widget.topicId);

    if (cachedData != null && !shouldRefresh && !shouldFetch) {
      // Use cached data - no network request needed
      debugPrint("✅ Using cached topic details (no fetch needed)");
      updateTopicDetails(cachedData);
      setState(() {
        isLoading = false;
      });
    } else if (cachedData != null && !shouldRefresh) {
      // Show cached data immediately, but still fetch fresh data in background
      debugPrint("⚡ Using cached data, fetching fresh data in background");
      updateTopicDetails(cachedData);
      setState(() {
        isLoading = false;
      });

      // Fetch fresh data in background without showing loading
      _fetchTopicDetailsInBackground();
    } else {
      // Fetch from backend with loading indicator
      debugPrint("🔄 Fetching topic details from backend");
      await fetchTopicDetails();
    }
  }

  Future<void> _fetchTopicDetailsInBackground() async {
    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    if (_cacheManager.isFetchInProgress(widget.courseId, widget.topicId, targetLanguage)) {
      return;
    }

    _cacheManager.setFetchInProgress(widget.courseId, widget.topicId, targetLanguage, true);

    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) {
        debugPrint("❌ Missing access token for background fetch");
        return;
      }

      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final dynamic jsonData = jsonDecode(responseBody);

        Map<String, dynamic>? data;
        if (jsonData is List) {
          if (jsonData.isNotEmpty && jsonData[0] is Map<String, dynamic>) {
            data = jsonData[0];
          }
        } else if (jsonData is Map<String, dynamic>) {
          data = jsonData;
        }

        if (data != null) {
          // Cache the fresh data
          _cacheManager.setCachedData(
              widget.courseId,
              widget.topicId,
              targetLanguage,
              data
          );

          // Mark as fetched in current session
          _lifecycleManager.markTopicFetchedInSession(widget.courseId, widget.topicId);

          // Update UI with fresh data if still mounted
          if (mounted) {
            updateTopicDetails(data);
          }

          debugPrint("🔄 Background fetch completed successfully");
        }
      }
    } catch (e) {
      debugPrint("❌ Background fetch error: $e");
    } finally {
      _cacheManager.setFetchInProgress(widget.courseId, widget.topicId, targetLanguage, false);
    }
  }

  Future<void> fetchTopicDetails() async {
    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    // Prevent concurrent fetches
    if (_cacheManager.isFetchInProgress(widget.courseId, widget.topicId, targetLanguage)) {
      debugPrint("🔄 Fetch already in progress");
      return;
    }

    _cacheManager.setFetchInProgress(widget.courseId, widget.topicId, targetLanguage, true);

    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint("❌ Missing access token");
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (!mounted) {
      _cacheManager.setFetchInProgress(widget.courseId, widget.topicId, targetLanguage, false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(
        const Duration(seconds: 15), // Increased timeout
        onTimeout: () {
          throw TimeoutException('Request timeout', const Duration(seconds: 15));
        },
      );

      debugPrint("🔹 API Response: ${response.body}");

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final dynamic jsonData = jsonDecode(responseBody);

        Map<String, dynamic>? data;
        if (jsonData is List) {
          if (jsonData.isNotEmpty && jsonData[0] is Map<String, dynamic>) {
            data = jsonData[0];
          }
        } else if (jsonData is Map<String, dynamic>) {
          data = jsonData;
        }

        if (data != null) {
          // Cache the data
          _cacheManager.setCachedData(
              widget.courseId,
              widget.topicId,
              targetLanguage,
              data
          );

          // Mark as fetched in current session
          _lifecycleManager.markTopicFetchedInSession(widget.courseId, widget.topicId);

          updateTopicDetails(data);
        } else {
          debugPrint("❌ Unexpected JSON structure");
        }
      } else {
        debugPrint("❌ Failed to fetch topic details: ${response.statusCode}");
        // Try to use any available cached data as fallback
        final fallbackData = _cacheManager.getCachedData(
            widget.courseId,
            widget.topicId,
            targetLanguage
        );
        if (fallbackData != null) {
          debugPrint("📱 Using cached data as fallback");
          updateTopicDetails(fallbackData);
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching topic details: $e");

      // Try to use cached data as fallback
      final fallbackData = _cacheManager.getCachedData(
          widget.courseId,
          widget.topicId,
          targetLanguage
      );
      if (fallbackData != null) {
        debugPrint("📱 Using cached data due to network error");
        updateTopicDetails(fallbackData);
      }
    } finally {
      _cacheManager.setFetchInProgress(widget.courseId, widget.topicId, targetLanguage, false);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void updateTopicDetails(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        topicTitle = data["title"]?.toString() ?? "Untitled Topic";
      });
    }
  }

  void _setupVideoController() {
    // Dispose previous controllers and remove listener
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _chewieController?.dispose();

    _videoController = null;
    _chewieController = null;

    if (_currentPage < widget.materials.length &&
        widget.materials[_currentPage]["type"] == "video") {
      _videoController = VideoPlayerController.network(
        widget.materials[_currentPage]["content"]!,
      );

      _videoController!.initialize().then((_) {
        if (!mounted) return;

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowMuting: true,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
        );

        setState(() {});

        // Add listener for video completion
        _videoController!.addListener(_videoListener);
      }).catchError((error) {
        debugPrint("Error initializing video: $error");
      });
    }
  }

  void _videoListener() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        !_videoController!.value.isPlaying &&
        _videoController!.value.position >= _videoController!.value.duration) {
      _videoController!.removeListener(_videoListener);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _nextMaterialOrQuiz();
        }
      });
    }
  }

  Map<String, dynamic> _currentMaterial() {
    if (_currentPage < widget.materials.length) {
      return widget.materials[_currentPage];
    } else {
      return {
        "type": "quiz",
        "quiz": widget.quizzes[_currentPage - widget.materials.length],
      };
    }
  }

  Future<void> _sendProgressToBackend() async {
    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint("❌ Missing access token");
      return;
    }

    final material = _currentMaterial();
    final materialId = material["id"] ?? "material_$_currentPage";

    if (materialId == null) {
      debugPrint("❌ Material ID is null");
      return;
    }

    debugPrint("✅ Material ID: $materialId");

    final progressList = await _fetchProgressList();
    final progressExists = progressList.any((progress) =>
    progress["material_id"] == materialId &&
        progress["activity_type"] == "reading");

    if (progressExists) {
      debugPrint("✅ Progress already exists for material ID: $materialId");
      return;
    }

    final progressData = {
      "course_id": widget.courseId,
      "topic_id": widget.topicId,
      "subtopic_id": widget.subtopicId,
      "material_id": materialId,
      "quiz_id": null,
      "score": 0,
      "status": "completed",
      "activity_type": "reading",
      "metadata": {"time_spent": "5 minutes"},
      "timestamp": DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/progress/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(progressData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint("✅ Progress updated successfully");
      } else {
        debugPrint("❌ Failed to update progress: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error updating progress: $e");
    }
  }

  Future<List<dynamic>> _fetchProgressList() async {
    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint("❌ Missing access token");
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/progress/?target_language=en'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody is Map<String, dynamic> &&
            responseBody.containsKey("progress")) {
          return responseBody["progress"];
        }
      } else if (response.statusCode == 404) {
        debugPrint("✅ No progress records found, returning empty list");
        return [];
      } else {
        debugPrint("❌ Failed to fetch progress: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching progress: $e");
    }
    return [];
  }

  Future<void> _nextMaterialOrQuiz() async {
    await _sendProgressToBackend();

    if (_currentPage < widget.materials.length + widget.quizzes.length - 1) {
      setState(() {
        _currentPage++;
      });

      // Force the Swiper to update by using a key and rebuilding it
      _setupVideoController();
    } else {
      if (widget.onQuizComplete != null) {
        widget.onQuizComplete!();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _showSwipeHint = false;
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.materials.isEmpty && widget.quizzes.isEmpty) {
      return Scaffold(
        backgroundColor: AcademeTheme.appColor,
        body: Container(),
      );
    }

    return Scaffold(
      backgroundColor: AcademeTheme.appColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          L10n.getTranslatedText(context, 'Subtopic Materials'),
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          // Add refresh button for manual cache refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () async {
              setState(() {
                isLoading = true;
              });
              // Clear cache for this topic and refetch
              _cacheManager.clearCacheForTopic(widget.courseId, widget.topicId);
              await fetchTopicDetails();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(),
          _buildSubtopicTitle(widget.subtopicTitle),
          if (isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      L10n.getTranslatedText(context, 'Loading...'),
                      style: TextStyle(
                        color: AcademeTheme.appColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Swiper(
                      key: ValueKey<int>(_currentPage),
                      itemWidth: constraints.maxWidth,
                      itemHeight: constraints.maxHeight,
                      loop: false,
                      duration: 600,
                      layout: SwiperLayout.STACK,
                      axisDirection: AxisDirection.right,
                      index: _currentPage,
                      onIndexChanged: (index) {
                        _handleSwipe();
                        if (_currentPage != index) {
                          setState(() {
                            _currentPage = index;
                          });
                          _setupVideoController();

                          if (index < widget.materials.length) {
                            _sendProgressToBackend();
                          }
                        }
                      },
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(0),
                                bottomRight: Radius.circular(0),
                              ),
                              child: _buildMaterial(index < widget.materials.length
                                  ? widget.materials[index]
                                  : {
                                "type": "quiz",
                                "quiz": widget.quizzes[index - widget.materials.length],
                              }),
                            ),
                            AnimatedOpacity(
                              opacity: _currentPage == index ? 0.0 : 0.2,
                              duration: const Duration(milliseconds: 500),
                              child: IgnorePointer(
                                ignoring: true,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(40),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                      bottomLeft: Radius.circular(0),
                                      bottomRight: Radius.circular(0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_showSwipeHint && index == 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/swipe_left_no_bg.gif',
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                      itemCount: widget.materials.length + widget.quizzes.length,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: List.generate(
              widget.materials.length + widget.quizzes.length, (index) {
            return Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.yellow[700]
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSubtopicTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)
          ],
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMaterial(Map<String, dynamic> material) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _getMaterialWidget(material),
        ),
      ],
    );
  }

  Widget _getMaterialWidget(Map<String, dynamic> material) {
    switch (material["type"]) {
      case "text":
        return _buildTextContent(material["content"]!);
      case "video":
        return _buildVideoContent(material["content"]!);
      case "image":
        return _buildImageContent(material["content"]!);
      case "audio":
        return _buildAudioContent(material["content"]!);
      case "document":
        return _buildDocumentContent(material["content"]!);
      case "quiz":
        return _buildQuizContent(material["quiz"]);
      default:
        return Center(child: Text(L10n.getTranslatedText(context, 'Unsupported content type')));
    }
  }

  Widget _buildTextContent(String content) {
    // Convert escaped newlines and handle markdown symbols
    String processedContent =
    content.replaceAll(r'\n', '\n').replaceAll('<br>', '\n');

    return buildStyledContainer(
      Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _formattedText(processedContent),
            ),
          ),
          if (widget.quizzes.isEmpty &&
              _currentPage == widget.materials.length - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onQuizComplete != null) {
                    widget.onQuizComplete!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  L10n.getTranslatedText(context, 'Mark as Completed'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _formattedText(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 16));
        continue;
      }

      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isSpecialLine(line) ? Colors.transparent : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: _parseLineContent(line),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _parseLineContent(String line) {
    if (line.startsWith('#')) {
      return _processHeading(line);
    }
    if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
      return _buildBulletPoint(line);
    }
    if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
      return _buildNumberedListItem(line);
    }
    if (line.trim().startsWith('> ')) {
      return _buildQuote(line);
    }
    return _parseInlineFormatting(line);
  }

  bool _isSpecialLine(String line) {
    return line.startsWith('#') ||
        line.trim().startsWith('- ') ||
        line.trim().startsWith('* ') ||
        RegExp(r'^\d+\.\s').hasMatch(line.trim()) ||
        line.trim().startsWith('> ');
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          child: Icon(
            Icons.circle,
            size: 10,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _parseInlineFormatting(
            text.replaceFirst(RegExp(r'^[-*]\s+'), ''),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedListItem(String text) {
    final numberMatch = RegExp(r'^(\d+)\.').firstMatch(text);
    final number = numberMatch?.group(1) ?? '•';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '$number.',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _parseInlineFormatting(
            text.replaceFirst(RegExp(r'^\d+\.\s+'), ''),
          ),
        ),
      ],
    );
  }

  Widget _buildQuote(String text) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.blue[300]!, width: 4)),
        color: Colors.blue[50],
      ),
      child: _parseInlineFormatting(
        text.replaceFirst('> ', ''),
      ),
    );
  }

  // Update the _parseInlineFormatting method
  Widget _parseInlineFormatting(String text,
      {bool isHeading = false, int level = 1}) {
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    final pattern = RegExp(
      r'(\*\*(.*?)\*\*|__(.*?)__|\*(.*?)\*|_(.*?)_|`(.*?)`|\[(.*?)\]\((.*?)\))',
      dotAll: true,
    );

    while (true) {
      final match = pattern.firstMatch(text.substring(lastIndex));
      if (match == null) break;

      if (match.start > 0) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, lastIndex + match.start),
          style: _getBaseTextStyle(isHeading, level),
        ));
      }

      if (match.group(1) != null) {
        spans.add(_createStyledSpan(match, isHeading, level));
      }

      lastIndex += match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: _getBaseTextStyle(isHeading, level),
      ));
    }

    return RichText(
      text: TextSpan(
        style: _getBaseTextStyle(isHeading, level),
        children: spans,
      ),
    );
  }

// Add this new helper method
  TextSpan _createStyledSpan(RegExpMatch match, bool isHeading, int level) {
    final baseStyle = _getBaseTextStyle(isHeading, level);

    if (match.group(2) != null) {
      // **Bold**
      return TextSpan(
        text: match.group(2),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple[800],
        ),
      );
    } else if (match.group(3) != null) {
      // __Bold__
      return TextSpan(
        text: match.group(3),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.amber[50],
        ),
      );
    } else if (match.group(4) != null) {
      // *Italic*
      return TextSpan(
        text: match.group(4),
        style: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.teal[800],
        ),
      );
    } else if (match.group(5) != null) {
      // _Italic_
      return TextSpan(
        text: match.group(5),
        style: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.underline,
          decorationColor: Colors.teal[300],
        ),
      );
    } else if (match.group(6) != null) {
      // `Code`
      return TextSpan(
        text: match.group(6),
        style: baseStyle.copyWith(
          fontFamily: 'FiraCode',
          backgroundColor: Colors.grey[100],
        ),
      );
    } else if (match.group(7) != null) {
      // [Link](url)
      return TextSpan(
        text: match.group(7),
        style: baseStyle.copyWith(
          color: Colors.blue[700],
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue[300],
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchUrl(Uri.parse(match.group(8)!)),
      );
    }

    return TextSpan(text: match.group(0), style: baseStyle);
  }

// Add explicit base text style
  TextStyle _getBaseTextStyle(bool isHeading, int level) {
    return TextStyle(
      fontSize: isHeading ? _getHeadingSize(level) : 17,
      fontWeight: isHeading ? FontWeight.w800 : FontWeight.w400,
      color: Colors.grey[850],
      height: 1.6,
      letterSpacing: isHeading ? -0.5 : 0.3,
      fontFamily: 'Roboto',
      decoration: TextDecoration.none,
    );
  }

  double _getHeadingSize(int level) {
    switch (level) {
      case 1:
        return 24;
      case 2:
        return 20;
      case 3:
        return 18;
      default:
        return 16;
    }
  }

// Helper method for processing headings
  Widget _processHeading(String text) {
    final level = text.split(' ')[0].length;
    final content = text.substring(level).trim();

    return Padding(
      padding: EdgeInsets.only(
        top: level == 1 ? 24 : 16,
        bottom: 12,
      ),
      child: _parseInlineFormatting(
        content,
        isHeading: true,
        level: level.clamp(1, 3),
      ),
    );
  }

  Widget _buildVideoContent(String videoUrl) {
    return buildStyledContainer(
      Column(
        children: [
          Expanded(
            child: _chewieController == null ||
                    _videoController == null ||
                    !_videoController!.value.isInitialized
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "${L10n.getTranslatedText(context, 'Loading video')}...",
                        style: TextStyle(
                          color: AcademeTheme.appColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {});
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      ),
                    ),
                  ),
          ),
          if (widget.quizzes.isEmpty &&
              _currentPage == widget.materials.length - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onQuizComplete != null) {
                    widget.onQuizComplete!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  L10n.getTranslatedText(context, 'Mark as Completed'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent(String imageUrl) {
    return buildStyledContainer(
      Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<BoxFit>(
                future: _getImageFit(imageUrl),
                builder: (context, snapshot) {
                  BoxFit fit = snapshot.data ?? BoxFit.cover;
                  return CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                    fit: fit,
                    alignment: Alignment.center,
                  );
                },
              ),
            ),
          ),
          if (widget.quizzes.isEmpty &&
              _currentPage == widget.materials.length - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onQuizComplete != null) {
                    widget.onQuizComplete!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  L10n.getTranslatedText(context, 'Mark as Completed'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<BoxFit> _getImageFit(String imageUrl) async {
    final Completer<ImageInfo> completer = Completer();
    final ImageStream stream =
        NetworkImage(imageUrl).resolve(const ImageConfiguration());

    final listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    }, onError: (dynamic exception, StackTrace? stackTrace) {
      completer.completeError(exception);
    });

    stream.addListener(listener);

    try {
      final ImageInfo imageInfo = await completer.future;
      final int width = imageInfo.image.width;
      final int height = imageInfo.image.height;
      stream.removeListener(listener);

      if (width > height) {
        return BoxFit.contain;
      } else {
        return BoxFit.cover;
      }
    } catch (e) {
      stream.removeListener(listener);
      return BoxFit.cover;
    }
  }

  Widget _buildAudioContent(String audioUrl) {
    return buildStyledContainer(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: WhatsAppAudioPlayer(audioUrl: audioUrl),
      ),
    );
  }

  Widget _buildDocumentContent(String docUrl) {
    return buildStyledContainer(
      Column(
        children: [
          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  debugPrint("Document URL: $docUrl");
                  launchUrl(Uri.parse(docUrl));
                },
                child: Text(L10n.getTranslatedText(context, 'Open Document')),
              ),
            ),
          ),
          if (widget.quizzes.isEmpty &&
              _currentPage == widget.materials.length - 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  debugPrint("Navigating to PDF Viewer with URL: $docUrl");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(L10n.getTranslatedText(context, 'Document'))),
                        body: SfPdfViewer.network(docUrl),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  L10n.getTranslatedText(context, 'Mark as Completed'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizContent(Map<String, dynamic> quiz) {
    return buildStyledContainer(
      QuizPage(
        quizzes: [quiz],
        onQuizComplete: () {
          _nextMaterialOrQuiz();
        },
        courseId: widget.courseId,
        topicId: widget.topicId,
        subtopicId: widget.subtopicId,
      ),
    );
  }

  Widget buildStyledContainer(Widget child) {
    final height = MediaQuery.of(context).size.height;
    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: height * 1.5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
          ],
        ),
        child: child,
      ),
    );
  }
}
