import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class FullScreenVideo extends StatefulWidget {
  final String videoPath;

  const FullScreenVideo({
    required this.videoPath,
    super.key, // Using super parameter syntax
  });

  @override
  State<FullScreenVideo> createState() => FullScreenVideoState();
}

class FullScreenVideoState extends State<FullScreenVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
