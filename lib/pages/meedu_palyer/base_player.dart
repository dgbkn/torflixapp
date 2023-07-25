import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

class MeeduPlayer extends StatefulWidget {
  final url;
  final name;
  MeeduPlayer({this.name, this.url});

  @override
  State<MeeduPlayer> createState() => _MeeduPlayerState();
}

class _MeeduPlayerState extends State<MeeduPlayer> {
  final _meeduPlayerController = MeeduPlayerController();

  @override
  void initState() {
    super.initState();

    _meeduPlayerController.setDataSource(
      DataSource(
        type: DataSourceType.network,
        source: widget.url,
      ),
      autoplay: true,
    );
  
  }

  @override
  void dispose() {
    _meeduPlayerController.dispose();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(  
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: MeeduVideoPlayer(
              controller: _meeduPlayerController,
            ),
          ),
        ),
      ),
    );
  }
}
