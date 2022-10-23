import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class VideoScreen extends StatefulWidget {
final url;
  final name;
  const VideoScreen({super.key, required this.url, required this.name});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen>
    with TickerProviderStateMixin {
  late VlcPlayerController vlcController;

  late AnimationController _scaleVideoAnimationController;
  Animation<double> _scaleVideoAnimation =
      const AlwaysStoppedAnimation<double>(1.0);
  double? _targetVideoScale;

  // Cache value for later usage at the end of a scale-gesture
  double _lastZoomGestureScale = 1.0;

  @override
  void initState() {
    super.initState();
    _forceLandscape();

    _scaleVideoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 125),
      vsync: this,
    );

    vlcController = VlcPlayerController.network(widget.url, autoPlay: true);

    // Uncomment  if you want autoplay to stop
    // vlcController.addOnInitListener(_stopAutoplay);
  }

  void setTargetNativeScale(double newValue) {
    if (!newValue.isFinite) {
      return;
    }
    _scaleVideoAnimation =
        Tween<double>(begin: 1.0, end: newValue).animate(CurvedAnimation(
      parent: _scaleVideoAnimationController,
      curve: Curves.easeInOut,
    ));

    if (_targetVideoScale == null) {
      _scaleVideoAnimationController.forward();
    }
    _targetVideoScale = newValue;
  }

  // Workaround the following bugs:
  // https://github.com/solid-software/flutter_vlc_player/issues/335
  // https://github.com/solid-software/flutter_vlc_player/issues/336
  Future<void> _stopAutoplay() async {
    await vlcController.pause();
    await vlcController.play();

    await vlcController.setVolume(0);

    await Future.delayed(const Duration(milliseconds: 150), () async {
      await vlcController.pause();
      await vlcController.setTime(0);
      await vlcController.setVolume(100);
    });
  }

  Future<void> _forceLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _forcePortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values); // to re-show bars
  }

  @override
  void dispose() {
    _forcePortrait();

    vlcController.removeOnInitListener(_stopAutoplay);
    vlcController.stopRendererScanning();
    vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final videoSize = vlcController.value.size;
    if (videoSize.width > 0) {
      final newTargetScale = screenSize.width /
          (videoSize.width * screenSize.height / videoSize.height);
      setTargetNativeScale(newTargetScale);
    }

    final vlcPlayer = VlcPlayer(
        controller: vlcController,
        aspectRatio: screenSize.width / screenSize.height,
        placeholder: const Center(child: CircularProgressIndicator()));

    return Scaffold(
        body: Material(
      color: Colors.transparent,
      child: GestureDetector(
        onScaleUpdate: (details) {
          _lastZoomGestureScale = details.scale;
        },
        onScaleEnd: (details) {
          if (_lastZoomGestureScale > 1.0) {
            setState(() {
              // Zoom in
              _scaleVideoAnimationController.forward();
            });
          } else if (_lastZoomGestureScale < 1.0) {
            setState(() {
              // Zoom out
              _scaleVideoAnimationController.reverse();
            });
          }
          _lastZoomGestureScale = 1.0;
        },
        child: Stack(
          children: [
            Container(
              // Background behind the video
              color: Colors.black,
            ),
            Center(
                child: ScaleTransition(
                    scale: _scaleVideoAnimation,
                    child: AspectRatio(aspectRatio: 16 / 9, child: vlcPlayer))),
          ],
        ),
      ),
    ));
  }
}
