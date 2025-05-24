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

class FlashCardState extends State<FlashCard>
    with WidgetsBindingObserver, TickerProviderStateMixin {
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

  // Animation controllers for smooth transitions
  late AnimationController _loadingAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _progressAnimation;

  // State management for smoother transitions
  bool _isVideoInitializing = false;
  bool _contentReady = false;
  Map<int, bool> _materialReadyStates = {};

  // Cache managers
  final TopicCacheManager _cacheManager = TopicCacheManager();
  final AppLifecycleManager _lifecycleManager = AppLifecycleManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.initialIndex;

    // Initialize animation controllers
    _initializeAnimations();

    _loadSwipeHintState();
    _initializeTopicData();

    if (widget.materials.isEmpty && widget.quizzes.isEmpty) {
      Future.delayed(Duration.zero, () {
        if (widget.onQuizComplete != null) {
          widget.onQuizComplete!();
        }
      });
    } else {
      _setupVideoControllerSmooth();
    }
  }

  void _initializeAnimations() {
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _loadingAnimation = CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutQuart,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    );

    // Start loading animation
    _loadingAnimationController.repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _lifecycleManager.markAppAsOpened();

      if (_lifecycleManager.shouldRefreshCache) {
        debugPrint("🔄 App resumed after long time, refreshing cache");
        _initializeTopicDataSmooth();
      }
    } else if (state == AppLifecycleState.paused) {
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

  Future<void> _initializeTopicDataSmooth() async {
    if (!mounted) return;

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    if (_cacheManager.isFetchInProgress(widget.courseId, widget.topicId, targetLanguage)) {
      debugPrint("🔄 Fetch already in progress, waiting...");
      return;
    }

    final cachedData = _cacheManager.getCachedData(
        widget.courseId,
        widget.topicId,
        targetLanguage
    );

    final shouldRefresh = _lifecycleManager.shouldRefreshCache;
    final shouldFetch = _lifecycleManager.shouldFetchTopicInSession(widget.courseId, widget.topicId);

    if (cachedData != null && !shouldRefresh && !shouldFetch) {
      debugPrint("✅ Using cached topic details (no fetch needed)");
      await _updateTopicDetailsSmooth(cachedData);
    } else if (cachedData != null && !shouldRefresh) {
      debugPrint("⚡ Using cached data, fetching fresh data in background");
      await _updateTopicDetailsSmooth(cachedData);
      _fetchTopicDetailsInBackground();
    } else {
      debugPrint("🔄 Fetching topic details from backend");
      await fetchTopicDetails();
    }
  }

  Future<void> _initializeTopicData() async {
    await _initializeTopicDataSmooth();
  }

  Future<void> _updateTopicDetailsSmooth(Map<String, dynamic> data) async {
    if (mounted) {
      // Animate content in smoothly
      await _contentAnimationController.forward();

      setState(() {
        topicTitle = data["title"]?.toString() ?? "Untitled Topic";
        _contentReady = true;
      });

      // Stop loading animation and fade out loading state
      _loadingAnimationController.stop();

      // Animate loading out and content in
      await Future.wait([
        _loadingAnimationController.reverse(),
        Future.delayed(const Duration(milliseconds: 200)),
      ]);

      setState(() {
        isLoading = false;
      });
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
          _cacheManager.setCachedData(
              widget.courseId,
              widget.topicId,
              targetLanguage,
              data
          );

          _lifecycleManager.markTopicFetchedInSession(widget.courseId, widget.topicId);

          if (mounted) {
            // Smooth update without loading indicator
            setState(() {
              topicTitle = data?["title"]?.toString() ?? "Untitled Topic";
            });
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

    if (_cacheManager.isFetchInProgress(widget.courseId, widget.topicId, targetLanguage)) {
      debugPrint("🔄 Fetch already in progress");
      return;
    }

    _cacheManager.setFetchInProgress(widget.courseId, widget.topicId, targetLanguage, true);

    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint("❌ Missing access token");
      await _handleLoadingComplete();
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
        const Duration(seconds: 15),
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
          _cacheManager.setCachedData(
              widget.courseId,
              widget.topicId,
              targetLanguage,
              data
          );

          _lifecycleManager.markTopicFetchedInSession(widget.courseId, widget.topicId);

          await _updateTopicDetailsSmooth(data);
        } else {
          debugPrint("❌ Unexpected JSON structure");
          await _handleLoadingComplete();
        }
      } else {
        debugPrint("❌ Failed to fetch topic details: ${response.statusCode}");
        final fallbackData = _cacheManager.getCachedData(
            widget.courseId,
            widget.topicId,
            targetLanguage
        );
        if (fallbackData != null) {
          debugPrint("📱 Using cached data as fallback");
          await _updateTopicDetailsSmooth(fallbackData);
        } else {
          await _handleLoadingComplete();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching topic details: $e");

      final fallbackData = _cacheManager.getCachedData(
          widget.courseId,
          widget.topicId,
          targetLanguage
      );
      if (fallbackData != null) {
        debugPrint("📱 Using cached data due to network error");
        await _updateTopicDetailsSmooth(fallbackData);
      } else {
        await _handleLoadingComplete();
      }
    } finally {
      _cacheManager.setFetchInProgress(widget.courseId, widget.topicId, targetLanguage, false);
    }
  }

  Future<void> _handleLoadingComplete() async {
    if (mounted) {
      _loadingAnimationController.stop();
      await _loadingAnimationController.reverse();
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateTopicDetails(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        topicTitle = data["title"]?.toString() ?? "Untitled Topic";
      });
    }
  }

  void _setupVideoControllerSmooth() {
    _setupVideoController();
  }

  void _setupVideoController() {
    if (_isVideoInitializing) return;

    final currentPageIsVideo = _currentPage < widget.materials.length &&
        widget.materials[_currentPage]["type"] == "video";

    if (!currentPageIsVideo) {
      _disposeVideoControllers();
      return;
    }

    final videoUrl = widget.materials[_currentPage]["content"]!;

    if (_videoController != null &&
        _videoController!.dataSource == videoUrl &&
        _videoController!.value.isInitialized) {
      return;
    }

    _isVideoInitializing = true;
    _disposeVideoControllers();

    _videoController = VideoPlayerController.network(videoUrl);

    _videoController!.initialize().then((_) {
      if (!mounted) return;

      // Add a small delay for smoother transition
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowMuting: true,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
        );

        setState(() {
          _materialReadyStates[_currentPage] = true;
          _isVideoInitializing = false;
        });

        _videoController!.addListener(_videoListener);
      });
    }).catchError((error) {
      debugPrint("Error initializing video: $error");
      setState(() {
        _isVideoInitializing = false;
      });
    });
  }

  void _disposeVideoControllers() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
  }

  void _videoListener() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        !_videoController!.value.isPlaying &&
        _videoController!.value.position >= _videoController!.value.duration) {
      _videoController!.removeListener(_videoListener);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _nextMaterialOrQuizSmooth();
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

  Future<void> _nextMaterialOrQuizSmooth() async {
    // Start progress animation
    await _progressAnimationController.forward(from: 0);

    // Send progress with smooth transition
    await Future.wait([
      _sendProgressToBackend(),
      Future.delayed(const Duration(milliseconds: 200)),
    ]);

    if (_currentPage < widget.materials.length + widget.quizzes.length - 1) {
      setState(() {
        _currentPage++;
      });

      // Smooth setup delay for next material
      await Future.delayed(const Duration(milliseconds: 250));
      _setupVideoController();
    } else {
      if (widget.onQuizComplete != null) {
        // Add a subtle delay before completing
        await Future.delayed(const Duration(milliseconds: 300));
        widget.onQuizComplete!();
      }
    }

    // Reset progress animation smoothly
    await Future.delayed(const Duration(milliseconds: 150));
    await _progressAnimationController.reverse();
  }

  Future<void> _nextMaterialOrQuiz() async {
    await _nextMaterialOrQuizSmooth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _showSwipeHint = false;

    // Dispose animation controllers
    _loadingAnimationController.dispose();
    _contentAnimationController.dispose();
    _progressAnimationController.dispose();

    _disposeVideoControllers();
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
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            L10n.getTranslatedText(context, 'Subtopic Materials'),
            key: ValueKey(L10n.getTranslatedText(context, 'Subtopic Materials')),
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: AnimatedRotation(
              turns: isLoading ? 1 : 0,
              duration: const Duration(milliseconds: 800),
              child: const Icon(Icons.refresh, color: Colors.black),
            ),
            onPressed: isLoading ? null : () async {
              setState(() {
                isLoading = true;
              });
              _loadingAnimationController.repeat();
              _cacheManager.clearCacheForTopic(widget.courseId, widget.topicId);
              await fetchTopicDetails();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicatorSmooth(),
          _buildSubtopicTitleSmooth(widget.subtopicTitle),
          if (isLoading)
            Expanded(
              child: FadeTransition(
                opacity: _loadingAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                          CurvedAnimation(
                            parent: _loadingAnimationController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AcademeTheme.appColor,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _loadingAnimation,
                        child: Text(
                          L10n.getTranslatedText(context, 'Loading...'),
                          style: TextStyle(
                            color: AcademeTheme.appColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: FadeTransition(
                opacity: _contentAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_contentAnimation),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Swiper(
                          // Remove the ValueKey to prevent rebuilding
                          itemWidth: constraints.maxWidth,
                          itemHeight: constraints.maxHeight,
                          loop: false,
                          duration: 400, // Reduced duration for smoother swipe
                          layout: SwiperLayout.STACK,
                          axisDirection: AxisDirection.right,
                          index: _currentPage,
                          onIndexChanged: (index) {
                            _handleSwipe();
                            if (_currentPage != index) {
                              setState(() {
                                _currentPage = index;
                              });

                              // Smooth transition delay
                              Future.delayed(const Duration(milliseconds: 150), () {
                                _setupVideoController();
                              });

                              if (index < widget.materials.length) {
                                _sendProgressToBackend();
                              }
                            }
                          },
                          itemBuilder: (context, index) {
                            return _buildMaterialCardSmooth(
                              index < widget.materials.length
                                  ? widget.materials[index]
                                  : {
                                "type": "quiz",
                                "quiz": widget.quizzes[index - widget.materials.length],
                              },
                              index,
                            );
                          },
                          itemCount: widget.materials.length + widget.quizzes.length,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialCardSmooth(Map<String, dynamic> material, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            child: _buildMaterial(material),
          ),
          AnimatedOpacity(
            opacity: _currentPage == index ? 0.0 : 0.15,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(30),
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
                child: AnimatedOpacity(
                  opacity: _showSwipeHint ? 0.8 : 0.0,
                  duration: const Duration(milliseconds: 500),
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
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicatorSmooth() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: List.generate(
              widget.materials.length + widget.quizzes.length, (index) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentPage >= index
                      ? Colors.yellow[700]
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: _currentPage == index
                      ? [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSubtopicTitleSmooth(String title) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            title,
            key: ValueKey(title),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeInQuart,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('${material["type"]}_${material.hashCode}'),
        child: _buildMaterialContent(material),
      ),
    );
  }

  Widget _buildMaterialContent(Map<String, dynamic> material) {
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
        return Center(
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              L10n.getTranslatedText(context, 'Unsupported content type'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildTextContent(String content) {
    String processedContent = content.replaceAll(r'\n', '\n').replaceAll('<br>', '\n');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      child: buildStyledContainer(
        Column(
          children: [
            Expanded(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuart,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child: _formattedText(processedContent),
                  ),
                ),
              ),
            ),
            if (widget.quizzes.isEmpty && _currentPage == widget.materials.length - 1)
              AnimatedSlide(
                offset: const Offset(0, 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
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
                        elevation: 3,
                        shadowColor: Colors.yellow.withOpacity(0.3),
                      ),
                      child: Text(
                        L10n.getTranslatedText(context, 'Mark as Completed'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        AnimatedContainer(
          duration: Duration(milliseconds: 200 + (i * 50).clamp(0, 400)),
          curve: Curves.easeOutQuart,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isSpecialLine(line) ? Colors.transparent : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 300 + (i * 30).clamp(0, 200)),
            child: _parseLineContent(line),
          ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      child: buildStyledContainer(
        Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeInQuart,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: _chewieController == null ||
                    _videoController == null ||
                    !_videoController!.value.isInitialized
                    ? Container(
                  key: const ValueKey('video_loading'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeInOutCubic,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(
                              opacity: value,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AcademeTheme.appColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          "${L10n.getTranslatedText(context, 'Loading video')}...",
                          style: TextStyle(
                            color: AcademeTheme.appColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : Container(
                  key: ValueKey('video_${videoUrl.hashCode}'),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutQuart,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 500),
                            child: Chewie(controller: _chewieController!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.quizzes.isEmpty && _currentPage == widget.materials.length - 1)
              AnimatedSlide(
                offset: const Offset(0, 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
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
                        elevation: 3,
                        shadowColor: Colors.yellow.withOpacity(0.3),
                      ),
                      child: Text(
                        L10n.getTranslatedText(context, 'Mark as Completed'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(String imageUrl) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      child: buildStyledContainer(
        Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuart,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder<BoxFit>(
                    future: _getImageFit(imageUrl),
                    builder: (context, snapshot) {
                      BoxFit fit = snapshot.data ?? BoxFit.cover;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        switchInCurve: Curves.easeOutQuart,
                        switchOutCurve: Curves.easeInQuart,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                ),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          key: ValueKey(imageUrl),
                          placeholder: (context, url) => Container(
                            key: const ValueKey('image_loading'),
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeInOutCubic,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (0.2 * value),
                                    child: Opacity(
                                      opacity: value,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AcademeTheme.appColor,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            key: const ValueKey('image_error'),
                            child: AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 400),
                              child: const Icon(
                                Icons.error,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          fit: fit,
                          alignment: Alignment.center,
                          fadeInDuration: const Duration(milliseconds: 400),
                          fadeInCurve: Curves.easeOutQuart,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (widget.quizzes.isEmpty && _currentPage == widget.materials.length - 1)
              AnimatedSlide(
                offset: const Offset(0, 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
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
                        elevation: 3,
                        shadowColor: Colors.yellow.withOpacity(0.3),
                      ),
                      child: Text(
                        L10n.getTranslatedText(context, 'Mark as Completed'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      child: buildStyledContainer(
        AnimatedPadding(
          padding: const EdgeInsets.all(8.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 500),
            child: WhatsAppAudioPlayer(audioUrl: audioUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentContent(String docUrl) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      child: buildStyledContainer(
        Column(
          children: [
            Expanded(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint("Document URL: $docUrl");
                        launchUrl(Uri.parse(docUrl));
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 3,
                        shadowColor: Colors.blue.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        L10n.getTranslatedText(context, 'Open Document'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.quizzes.isEmpty && _currentPage == widget.materials.length - 1)
              AnimatedSlide(
                offset: const Offset(0, 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint("Navigating to PDF Viewer with URL: $docUrl");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: Text(L10n.getTranslatedText(context, 'Document')),
                              ),
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
                        elevation: 3,
                        shadowColor: Colors.yellow.withOpacity(0.3),
                      ),
                      child: Text(
                        L10n.getTranslatedText(context, 'Mark as Completed'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent(Map<String, dynamic> quiz) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      child: buildStyledContainer(
        AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          child: QuizPage(
            quizzes: [quiz],
            onQuizComplete: () {
              _nextMaterialOrQuiz();
            },
            courseId: widget.courseId,
            topicId: widget.topicId,
            subtopicId: widget.subtopicId,
          ),
        ),
      ),
    );
  }

  Widget buildStyledContainer(Widget child) {
    final height = MediaQuery.of(context).size.height;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
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
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutQuart,
            switchOutCurve: Curves.easeInQuart,
            child: child,
          ),
        ),
      ),
    );
  }

}
