import 'dart:async';

import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widget/document_preview.dart';
import '../../../widget/whatsapp_audio.dart';
import 'quiz.dart'; // Import the quiz widget
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class FlashCard extends StatefulWidget {
  final List<Map<String, String>> materials; // Ensure correct type
  final List<Map<String, dynamic>> quizzes;
  final Function()? onQuizComplete;
  final int initialIndex; // Add initialIndex parameter
  final String courseId; // Add courseId
  final String topicId; // Add topicId
  final String subtopicId; // Add subtopicId

  const FlashCard({
    super.key,
    required this.materials,
    required this.quizzes,
    this.onQuizComplete,
    this.initialIndex = 0, // Default to 0
    required this.courseId,
    required this.topicId,
    required this.subtopicId,
  });

  @override
  _FlashCardState createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentPage = 0;
  late YoutubePlayerController _youtubeController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasNavigated = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String backendUrl = dotenv.env['BACKEND_URL'] ??
      'http://10.0.2.2:8000'; // Replace with your backend URL

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex; // Set initial index

    // Check if the subtopic has no materials or quizzes
    if (widget.materials.isEmpty && widget.quizzes.isEmpty) {
      // If there are no materials or quizzes, trigger the onQuizComplete callback
      Future.delayed(Duration.zero, () {
        if (widget.onQuizComplete != null) {
          widget.onQuizComplete!();
        }
      });
    } else {
      // Otherwise, set up the video controller as usual
      _setupVideoController();
    }
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
        print("Error initializing video: $error");
      });
    }
  }

  Map<String, dynamic> _currentMaterial() {
    if (_currentPage < widget.materials.length) {
      return widget.materials[_currentPage];
    } else {
      // Return the quiz data
      return {
        "type": "quiz",
        "quiz": widget.quizzes[_currentPage - widget.materials.length],
      };
    }
  }

  Future<void> _sendProgressToBackend() async {
    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      print("❌ Missing access token");
      return;
    }

    final material = _currentMaterial();
    final materialId = material["id"] ??
        "material_${_currentPage}"; // Fallback to index if ID is missing

    if (materialId == null) {
      print("❌ Material ID is null");
      return;
    }

    print("✅ Material ID: $materialId");

    // Fetch the progress list for the current material_id
    final progressList = await _fetchProgressList();

    // Check if any progress entry with the same material_id exists
    final progressExists = progressList.any((progress) =>
    progress["material_id"] == materialId &&
        progress["activity_type"] == "reading");

    if (progressExists) {
      print("✅ Progress already exists for material ID: $materialId");
      return;
    }

    final progressData = {
      "course_id": widget.courseId,
      "topic_id": widget.topicId,
      "subtopic_id": widget.subtopicId,
      "material_id": materialId,
      "quiz_id": null, // Since this is for material, quiz_id is null
      "score": 0, // No score for material
      "status": "completed",
      "activity_type": "reading",
      "metadata": {
        "time_spent": "5 minutes", // Example metadata
      },
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
        print("✅ Progress updated successfully");
      } else {
        print("❌ Failed to update progress: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error updating progress: $e");
    }
  }

  Future<List<dynamic>> _fetchProgressList() async {
    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      print("❌ Missing access token");
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
          return responseBody["progress"]; // Return the progress list
        }
      } else if (response.statusCode == 404) {
        // Handle 404 error by returning an empty list
        print("✅ No progress records found, returning empty list");
        return [];
      } else {
        print("❌ Failed to fetch progress: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching progress: $e");
    }
    return [];
  }

  void _nextMaterialOrQuiz() async {
    // Send progress to backend before moving to the next material/quiz
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
      // Trigger callback when all materials and quizzes are completed
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
    // Check if the subtopic has no materials or quizzes
    if (widget.materials.isEmpty && widget.quizzes.isEmpty) {
      // Return an empty container or a loading indicator
      return Scaffold(
        backgroundColor: AcademeTheme.appColor,
        body: Container(), // Or use a loading indicator if needed
      );
    }

    // Otherwise, build the normal UI
    return Scaffold(
      backgroundColor: AcademeTheme.appColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Subtopic Materials',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(),
          _buildSubtopicTitle(_currentMaterial()["title"] ?? "Subtopic"),
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

                        // Send progress to backend when swiping to the next material
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
                                  color: Colors.black.withOpacity(0.4),
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
        return const Center(child: Text("Unsupported content type"));
    }
  }

  Widget _buildTextContent(String content) {
    return buildStyledContainer(
      Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _formattedText(content), // Use markdown formatting
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

  Widget _buildVideoContent(String videoUrl) {
    return buildStyledContainer(
      Column(
        children: [
          Expanded(
            child: _chewieController == null ||
                _videoController == null ||
                !_videoController!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
              onTap: () {
                setState(() {});
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Chewie(controller: _chewieController!),
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
                  BoxFit fit = snapshot.data ?? BoxFit.cover; // Default cover
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
        // Landscape
        return BoxFit.contain; // or BoxFit.fitWidth
      } else {
        // Portrait
        return BoxFit.cover;
      }
    } catch (e) {
      stream.removeListener(listener);
      return BoxFit.cover; // Default fallback
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
                  print("Document URL: $docUrl"); // Print URL here
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
                  print(
                      "Navigating to PDF Viewer with URL: $docUrl"); // Print URL before navigation
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
      LessonQuestionPage(
        quizzes: [quiz], // Pass the quiz data
        onQuizComplete: () {
          // Move to the next material or quiz
          _nextMaterialOrQuiz();
        },
        courseId: widget.courseId, // Pass courseId
        topicId: widget.topicId, // Pass topicId
        subtopicId: widget.subtopicId, // Pass subtopicId
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
            topLeft: Radius.circular(20), // Top-left corner has a radius of 20
            topRight:
            Radius.circular(20), // Top-right corner has a radius of 20
            bottomLeft:
            Radius.circular(0), // Bottom-left corner has a radius of 0
            bottomRight:
            Radius.circular(0), // Bottom-right corner has a radius of 0
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
          ],
        ),
        child: child,
      ),
    );
  }

  /// **Formats raw text with bold headings, bullet points, and other markdown symbols**
  Widget _formattedText(String text) {
    List<Widget> formattedWidgets = [];
    List<String> parts = text.split("\n");

    for (String part in parts) {
      if (part.trim().isEmpty) {
        formattedWidgets.add(const SizedBox(height: 8)); // Adds spacing
      } else if (part.startsWith("**") && part.endsWith("**")) {
        // Bold text (double asterisks) - Treat as a key
        formattedWidgets.add(Text(
          part.replaceAll("**", ""),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ));
      } else if (part.startsWith("*") && part.endsWith("*")) {
        // Bold text (single asterisks) - Treat as a key
        formattedWidgets.add(Text(
          part.replaceAll("*", ""),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ));
      } else if (part.startsWith("- ")) {
        // Bullet points
        formattedWidgets.add(_buildBulletPoint(part.replaceFirst("- ", "")));
      } else if (part.startsWith("# ")) {
        // Heading 1
        formattedWidgets.add(Text(
          part.replaceFirst("# ", ""),
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ));
      } else if (part.startsWith("## ")) {
        // Heading 2
        formattedWidgets.add(Text(
          part.replaceFirst("## ", ""),
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ));
      } else if (part.startsWith("### ")) {
        // Heading 3
        formattedWidgets.add(Text(
          part.replaceFirst("### ", ""),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ));
      } else if (part.startsWith(">")) {
        // Blockquote
        formattedWidgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              part.replaceFirst(">", "").trim(),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ));
      } else if (part.startsWith("`") && part.endsWith("`")) {
        // Inline code
        formattedWidgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            part.replaceAll("`", ""),
            style: const TextStyle(
                fontFamily: 'monospace', fontSize: 14, color: Colors.black87),
          ),
        ));
      } else {
        // Regular text (with inline bold formatting)
        formattedWidgets.add(_parseInlineBoldText(part));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: formattedWidgets,
    );
  }

  /// **Helper function to parse inline bold text (e.g., *bold* or **bold**)**
  Widget _parseInlineBoldText(String text) {
    List<InlineSpan> spans = [];
    List<String> parts = text.split(RegExp(r'(\*\*|\*)'));

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // Odd indices are bold text (treat as keys)
        spans.add(TextSpan(
          text: parts[i],
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ));
      } else {
        // Even indices are regular text (treat as values)
        spans.add(TextSpan(
          text: parts[i],
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// **Helper function for bullet points**
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child:
            _parseInlineBoldText(text), // Parse bold text in bullet points
          ),
        ],
      ),
    );
  }
}