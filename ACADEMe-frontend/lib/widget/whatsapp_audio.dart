import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class WhatsAppAudioPlayer extends StatefulWidget {
  final String audioUrl;

  const WhatsAppAudioPlayer({
    Key? key,
    required this.audioUrl,
  }) : super(key: key);

  @override
  _WhatsAppAudioPlayerState createState() => _WhatsAppAudioPlayerState();
}

class _WhatsAppAudioPlayerState extends State<WhatsAppAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        currentPosition = p;
      });
    });

    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        totalDuration = d;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        currentPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
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
                await _audioPlayer.pause();
                setState(() {
                  isPlaying = false;
                });
              } else {
                await _audioPlayer.play(UrlSource(widget.audioUrl));
                setState(() {
                  isPlaying = true;
                });
              }
            },
          ),
          const SizedBox(width: 8),

          // Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: currentPosition.inSeconds.toDouble(),
                  min: 0,
                  max: totalDuration.inSeconds > 0
                      ? totalDuration.inSeconds.toDouble()
                      : 1,
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(position);
                  },
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.grey[400],
                ),
                // Duration display (optional, WhatsApp doesn't show but can be added)
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