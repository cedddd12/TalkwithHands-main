import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LessonVideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final double playbackSpeed;
  final List<double> speeds;
  final ValueChanged<double> onSpeedChanged;
  final bool showPlayPause;
  final bool compact;
  final VoidCallback? onFullscreen;
  final bool isFullscreen;

  const LessonVideoControls({
    super.key,
    required this.controller,
    required this.playbackSpeed,
    required this.speeds,
    required this.onSpeedChanged,
    this.showPlayPause = false,
    this.compact = false,
    this.onFullscreen,
    this.isFullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(10, 7, 10, 9)
          : const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF082D58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFA21A), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: EdgeInsets.zero,
            colors: const VideoProgressColors(
              playedColor: Color(0xFFFFA21A),
              bufferedColor: Colors.white54,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (showPlayPause)
                Expanded(
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: controller,
                    builder: (context, value, _) => IconButton(
                      color: Colors.white,
                      tooltip: value.isPlaying ? 'Pause' : 'Play',
                      onPressed: () => value.isPlaying
                          ? controller.pause()
                          : controller.play(),
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: showPlayPause ? 2 : 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 1, 152, 178),
                        Color(0xFF168BD7),
                        Color(0xFF0753A6),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                    onPressed: () => controller
                      ..seekTo(Duration.zero)
                      ..play(),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text(
                      'Replay',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              if (onFullscreen != null)
                IconButton(
                  color: Colors.white,
                  tooltip: isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
                  onPressed: onFullscreen,
                  icon: Icon(
                    isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: speeds
                .map(
                  (speed) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: EdgeInsets.zero,
                          foregroundColor: playbackSpeed == speed
                              ? Colors.black
                              : Colors.white,
                          backgroundColor: playbackSpeed == speed
                              ? const Color(0xFFFFA21A)
                              : Colors.transparent,
                          side: const BorderSide(color: Color(0xFFB9D7F3)),
                        ),
                        onPressed: () => onSpeedChanged(speed),
                        child: FittedBox(
                          child: Text(
                            '${speed.toStringAsFixed(speed == 1 ? 1 : 2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}x',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
