import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import 'vlc_player_with_controls.dart';

class VlcMediaPlayer extends StatefulWidget {
  final url;
  final name;
  const VlcMediaPlayer({super.key, required this.url, required this.name});

  @override
  _VlcMediaPlayerState createState() => _VlcMediaPlayerState();
}

class _VlcMediaPlayerState extends State<VlcMediaPlayer> {
  late VlcPlayerController controller;
  bool showPlayerControls = true;

  @override
  void initState() {
    super.initState();

    controller = VlcPlayerController.network(
      widget.url,
      hwAcc: HwAcc.full,
      autoPlay: false,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Container(
        height: showPlayerControls ? 400 : 300,
        child: VlcPlayerWithControls(
          controller: controller,
          showControls: showPlayerControls,
          onStopRecording: (String) {},
        ),
      ),
    );
  }

  @override
  void dispose() async {
    super.dispose();
    await controller.stopRendererScanning();
    await controller.dispose();
  }
}
