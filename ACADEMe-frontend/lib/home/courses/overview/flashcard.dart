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

class FlashCard extends StatefulWidget {
  final List<Map<String, String>> materials;
  final List<Map<String, dynamic>> quizzes;
  final Function()? onQuizComplete;
  final int initialIndex;
  final String courseId;
  final String topicId;
  final String subtopicId;

  const FlashCard({
    super.key,
    required this.materials,
    required this.quizzes,
    this.onQuizComplete,
    this.initialIndex = 0,
    required this.courseId,
    required this.topicId,
    required this.subtopicId,
  });

  @override
  FlashCardState createState() => FlashCardState();
}

class FlashCardState extends State<FlashCard> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentPage = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasNavigated = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  String topicTitle = "Loading...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    fetchTopicDetails();

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

  Future<void> fetchTopicDetails() async {
    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint("❌ Missing access token");
      return;
    }
    if (!mounted) {
      return; // Ensure widget is still active before using context
    }

    // Get the target language from the app's language provider
    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      debugPrint("🔹 API Response: ${response.body}"); // ✅ Log the response

      if (response.statusCode == 200) {
        // Decode the response body using UTF-8
        final String responseBody = utf8.decode(response.bodyBytes);
        final dynamic jsonData = jsonDecode(responseBody);

        if (jsonData is List) {
          if (jsonData.isNotEmpty && jsonData[0] is Map<String, dynamic>) {
            final Map<String, dynamic> data = jsonData[0];
            updateTopicDetails(data);
          } else {
            debugPrint(
                "❌ Unexpected JSON format (List but empty or incorrect structure)");
          }
        } else if (jsonData is Map<String, dynamic>) {
          updateTopicDetails(jsonData);
        } else {
          debugPrint("❌ Unexpected JSON structure: ${jsonData.runtimeType}");
        }
      } else {
        debugPrint("❌ Failed to fetch topic details: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching topic details: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateTopicDetails(Map<String, dynamic> data) {
    setState(() {
      topicTitle = data["title"]?.toString() ?? "Untitled Topic";
    });
  }

  void _setupVideoController() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;

    if (_currentPage < widget.materials.length &&
        widget.materials[_currentPage]["type"] == "video") {
      _videoController = VideoPlayerController.network(
          widget.materials[_currentPage]["content"]!);

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

        _videoController!.addListener(() {
          if (!_hasNavigated &&
              _videoController!.value.isInitialized &&
              _videoController!.value.position >=
                  _videoController!.value.duration) {
            _hasNavigated = true;
            Future.delayed(const Duration(milliseconds: 500), () {
              _hasNavigated = false;
              _nextMaterialOrQuiz();
            });
          }
        });
      }).catchError((error) {
        debugPrint("Error initializing video: $error");
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
      );

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
      );

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

  void _nextMaterialOrQuiz() async {
    await _sendProgressToBackend();

    if (_currentPage < widget.materials.length + widget.quizzes.length - 1) {
      setState(() {
        _currentPage++;
        _hasNavigated = false;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        _setupVideoController();
      });
    } else {
      if (widget.onQuizComplete != null) {
        widget.onQuizComplete!();
      }
    }
  }

  @override
  void dispose() {
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(),
          _buildSubtopicTitle(topicTitle),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Swiper(
                    itemWidth: constraints.maxWidth,
                    itemHeight: constraints.maxHeight,
                    loop: false,
                    duration: 600,
                    layout: SwiperLayout.STACK,
                    axisDirection: AxisDirection.right,
                    index: _currentPage,
                    onIndexChanged: (index) {
                      if (_currentPage != index) {
                        setState(() {
                          _currentPage = index;
                          _setupVideoController();
                        });

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
                            child:
                                _buildMaterial(index < widget.materials.length
                                    ? widget.materials[index]
                                    : {
                                        "type": "quiz",
                                        "quiz": widget.quizzes[
                                            index - widget.materials.length],
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
          isLoading ? "Loading..." : topicTitle,
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
        return const Center(child: Text("Unsupported content type"));
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
                child: const Text(
                  "Mark as Completed",
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
    List<Widget> lines = [];
    final lineStrings = text.split('\n');

    for (int i = 0; i < lineStrings.length; i++) {
      final line = lineStrings[i];
      if (line.isEmpty) {
        lines.add(const SizedBox(height: 16));
        continue;
      }

      // Check for headings first
      if (line.startsWith('#')) {
        lines.add(_processHeading(line));
      }
      // Check for lists
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        lines.add(_buildBulletPoint(line));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
        lines.add(_buildNumberedListItem(line));
      }
      // Process regular text with inline formatting
      else {
        lines.add(_parseInlineFormatting(line));
      }

      // Add spacing between lines
      if (i != lineStrings.length - 1) {
        lines.add(const SizedBox(height: 8));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Widget _parseInlineFormatting(String text,
      {bool isHeading = false, int level = 1}) {
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    // Improved regex pattern for markdown parsing
    final pattern = RegExp(
      r'(\*\*|\*|`|\[.*?\]\(.*?\))',
      dotAll: true,
    );

    while (true) {
      final match = pattern.firstMatch(text.substring(lastIndex));
      if (match == null) break;

      // Add text before the match
      if (match.start > 0) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, lastIndex + match.start),
          style: _getTextStyle(isHeading, level),
        ));
      }

      final matchedText =
          text.substring(lastIndex + match.start, lastIndex + match.end);
      lastIndex += match.end;

      // Handle different markdown symbols
      switch (matchedText[0]) {
        case '*':
          if (matchedText.length > 1 && matchedText[1] == '*') {
            // Bold text
            final endMatch = text.indexOf('**', lastIndex);
            if (endMatch != -1) {
              spans.add(TextSpan(
                text: text.substring(lastIndex, endMatch),
                style: _getTextStyle(isHeading, level).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ));
              lastIndex = endMatch + 2;
            }
          } else {
            // Italic text
            final endMatch = text.indexOf('*', lastIndex);
            if (endMatch != -1) {
              spans.add(TextSpan(
                text: text.substring(lastIndex, endMatch),
                style: _getTextStyle(isHeading, level).copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ));
              lastIndex = endMatch + 1;
            }
          }
          break;

        case '`':
          // Code block
          final endMatch = text.indexOf('`', lastIndex);
          if (endMatch != -1) {
            spans.add(TextSpan(
              text: text.substring(lastIndex, endMatch),
              style: _getTextStyle(isHeading, level).copyWith(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey[200],
              ),
            ));
            lastIndex = endMatch + 1;
          }
          break;

        case '[':
          // Link handling
          final linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
          final linkMatch = linkRegex.firstMatch(text.substring(lastIndex - 1));
          if (linkMatch != null) {
            spans.add(TextSpan(
              text: linkMatch.group(1),
              style: _getTextStyle(isHeading, level).copyWith(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrl(Uri.parse(linkMatch.group(2)!)),
            ));
            lastIndex += linkMatch.end - 1;
          }
          break;
      }
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: _getTextStyle(isHeading, level),
      ));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: spans,
      ),
    );
  }

// Helper methods for styling
  TextStyle _getTextStyle(bool isHeading, int level) {
    if (isHeading) {
      return TextStyle(
        fontSize: _getHeadingSize(level),
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );
    }
    return const TextStyle(
      fontSize: 16,
      color: Colors.black87,
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

// Helper methods for building list items
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: _parseInlineFormatting(
                text.replaceFirst(RegExp(r'^[-*]\s+'), '')),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedListItem(String text) {
    final numberMatch = RegExp(r'^(\d+)\.').firstMatch(text);
    final number = numberMatch?.group(1) ?? '•';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number.', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: _parseInlineFormatting(
                text.replaceFirst(RegExp(r'^\d+\.\s+'), '')),
          ),
        ],
      ),
    );
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
                      const SizedBox(height: 16),
                      Text(
                        "Loading video...",
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
                child: const Text(
                  "Mark as Completed",
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
                child: const Text(
                  "Mark as Completed",
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
                child: const Text("Open Document"),
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
                        appBar: AppBar(title: const Text("Document")),
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
                child: const Text(
                  "Mark as Completed",
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
