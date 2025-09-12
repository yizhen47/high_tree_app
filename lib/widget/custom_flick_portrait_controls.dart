import 'package:flutter/material.dart';
import 'package:flick_video_player/flick_video_player.dart';

class CustomFlickPortraitControls extends StatelessWidget {
  const CustomFlickPortraitControls({
    super.key,
    this.iconSize = 20,
    this.fontSize = 12,
    this.progressBarSettings,
  });

  final double iconSize;
  final double fontSize;
  final FlickProgressBarSettings? progressBarSettings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: FlickShowControlsAction(
            child: FlickSeekVideoAction(
              child: Center(
                child: FlickVideoBuffer(
                  child: FlickAutoHideChild(
                    child: FlickPlayToggle(
                      size: 30,
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: FlickAutoHideChild(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlickVideoProgressBar(
                  flickProgressBarSettings: progressBarSettings,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    FlickPlayToggle(
                      size: iconSize,
                    ),
                    FlickSoundToggle(
                      size: iconSize,
                    ),
                    Row(
                      children: <Widget>[
                        FlickCurrentPosition(
                          fontSize: fontSize,
                        ),
                        const Text(' / ', style: TextStyle(color: Colors.white)),
                        FlickTotalDuration(
                          fontSize: fontSize,
                        ),
                      ],
                    ),
                    FlickFullScreenToggle(
                      size: iconSize,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 