import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/courses/overview/quiz.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class FlashCard extends StatefulWidget {
  final List<Map<String, String>> materials;

  const FlashCard({super.key, required this.materials});

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

  @override
  void initState() {
    super.initState();
    _setupVideoController();
  }

  void _setupVideoController() {
    if (_currentMaterial()["type"] == "video") {
      _videoController?.dispose();
      _chewieController?.dispose();

      _videoController = VideoPlayerController.network(_currentMaterial()["content"]!)
        ..initialize().then((_) {
          setState(() {});

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
                _videoController!.value.position >= _videoController!.value.duration) {
              _hasNavigated = true;
              _nextMaterialOrQuiz();
            }
          });
        });
    }
  }

  Map<String, String> _currentMaterial() {
    return widget.materials[_currentPage];
  }

  void _nextMaterialOrQuiz() {
    if (_currentPage < widget.materials.length - 1) {
      setState(() => _currentPage++);
      _setupVideoController();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LessonQuestionPage()),
      );
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
          'Lesson Materials',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: Swiper(
              loop: false,
              itemCount: widget.materials.length,
              onIndexChanged: (index) {
                setState(() => _currentPage = index);
                _setupVideoController();
              },
              itemBuilder: (context, index) {
                return _buildMaterial(widget.materials[index]);
              },
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
          children: List.generate(widget.materials.length, (index) {
            return Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.yellow[700] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMaterial(Map<String, String> material) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtopicTitle(material["title"] ?? "Subtopic"), // Adding the title dynamically
        Expanded(
          child: _getMaterialWidget(material),
        ),
      ],
    );
  }

  Widget _getMaterialWidget(Map<String, String> material) {
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
      default:
        return const Center(child: Text("Unsupported content type"));
    }
  }

  Widget _buildTextContent(String content) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)],
        ),
        child: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
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
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)],
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

  Widget _buildVideoContent(String videoUrl) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Chewie(controller: _chewieController!);
  }

  Widget _buildImageContent(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildAudioContent(String audioUrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.audiotrack, size: 100, color: Colors.blue),
        ElevatedButton(
          onPressed: () async {
            await _audioPlayer.play(UrlSource(audioUrl));
          },
          child: const Text("Play Audio"),
        ),
      ],
    );
  }

  Widget _buildDocumentContent(String docUrl) {
    return Center(
      child: ElevatedButton(
        onPressed: () => launchUrl(Uri.parse(docUrl)),
        child: const Text("Open Document"),
      ),
    );
  }
}
