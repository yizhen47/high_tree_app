import 'package:flutter/material.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:provider/provider.dart';

class CustomFlickPortraitControls extends StatefulWidget {
  const CustomFlickPortraitControls({
    super.key,
    this.iconSize = 20,
    this.fontSize = 12,
    this.progressBarSettings,
    this.onRotate,
  });

  final double iconSize;
  final double fontSize;
  final FlickProgressBarSettings? progressBarSettings;
  final VoidCallback? onRotate;

  @override
  State<CustomFlickPortraitControls> createState() => _CustomFlickPortraitControlsState();
}

class _CustomFlickPortraitControlsState extends State<CustomFlickPortraitControls> {
  double _currentSpeed = 1.0;
  
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  void _showSpeedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('播放速度'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _speedOptions.map((speed) {
              return ListTile(
                title: Text('${speed}x'),
                leading: Radio<double>(
                  value: speed,
                  groupValue: _currentSpeed,
                  onChanged: (value) {
                    if (value != null && mounted) {
                      _setPlaybackSpeed(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                onTap: () {
                  if (mounted) {
                    _setPlaybackSpeed(speed);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _setPlaybackSpeed(double speed) {
    if (!mounted) return;
    final flickManager = Provider.of<FlickManager>(context, listen: false);
    flickManager.flickVideoManager?.videoPlayerController?.setPlaybackSpeed(speed);
    if (mounted) {
      setState(() {
        _currentSpeed = speed;
      });
    }
  }

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
                  flickProgressBarSettings: widget.progressBarSettings,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    FlickPlayToggle(
                      size: widget.iconSize,
                    ),
                    FlickSoundToggle(
                      size: widget.iconSize,
                    ),
                    Row(
                      children: <Widget>[
                        FlickCurrentPosition(
                          fontSize: widget.fontSize,
                        ),
                        const Text(' / ', style: TextStyle(color: Colors.white)),
                        FlickTotalDuration(
                          fontSize: widget.fontSize,
                        ),
                      ],
                    ),
                    // 倍速按钮
                    GestureDetector(
                      onTap: _showSpeedDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.speed,
                              size: widget.iconSize,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentSpeed}x',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.fontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 旋转按钮
                    if (widget.onRotate != null)
                      GestureDetector(
                        onTap: widget.onRotate,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.rotate_90_degrees_ccw,
                            size: widget.iconSize,
                            color: Colors.white,
                          ),
                        ),
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