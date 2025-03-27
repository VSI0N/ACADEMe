import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class WhatsAppAudioPlayer extends StatefulWidget {
  final String audioUrl;

  const WhatsAppAudioPlayer({
    super.key,
    required this.audioUrl,
  });

  @override
  WhatsAppAudioPlayerState createState() => WhatsAppAudioPlayerState();
}

class WhatsAppAudioPlayerState extends State<WhatsAppAudioPlayer> {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        currentPosition = p;
      });
    });

    audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        totalDuration = d;
      });
    });

    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        currentPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.blueAccent,
              size: 36,
            ),
            onPressed: () async {
              if (isPlaying) {
                await audioPlayer.pause();
                setState(() {
                  isPlaying = false;
                });
              } else {
                await audioPlayer.play(UrlSource(widget.audioUrl));
                setState(() {
                  isPlaying = true;
                });
              }
            },
          ),
          // Progress Bar and Duration
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: currentPosition.inSeconds.toDouble(),
                  min: 0,
                  max: totalDuration.inSeconds > 0
                      ? totalDuration.inSeconds.toDouble()
                      : 1,
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await audioPlayer.seek(position);
                  },
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.grey[400],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(currentPosition),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDuration(totalDuration),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}