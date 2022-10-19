import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock/wakelock.dart';
// import 'package:pod_player/pod_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dart_vlc/dart_vlc.dart' as supvid;
import 'package:hive/hive.dart';

import '../../utils.dart';
import 'dart:io' as io;

var box = Hive.box('stats');

class VideoPlayer extends StatefulWidget {
  final String url;
  final String name;
  final String img;
  const VideoPlayer({required this.url, required this.name, required this.img});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  BetterPlayerController? _betterPlayerController;

  supvid.Player? player;
  bool isVlcLoaded = false;

  void initYT(ursl) async {
    var srcs = await _extractVideoUrl(ursl);

    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
      autoPlay: true,
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      controlsConfiguration: BetterPlayerControlsConfiguration(
          playerTheme: BetterPlayerTheme.cupertino),
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);

    BetterPlayerDataSource betterPlayerDataSource = srcs;

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController?.setupDataSource(betterPlayerDataSource);
    setState(() {});
  }

  void initYTWindows(ursl) async {
    var srcs = await _extractVideoUrl(ursl);
    player = supvid.Player(id: 69420);
    player!.open(
      supvid.Media.network(srcs),
      autoStart: true, // default
    );

    isVlcLoaded = true;

    setState(() {});
  }

  Future<dynamic> _extractVideoUrl(url) async {
    final extractor = YoutubeExplode();
    final videoId = convertUrlToId(url);
    final streamManifest =
        await extractor.videos.streamsClient.getManifest(videoId);
    final streamInfo = streamManifest.muxed.withHighestBitrate();
    extractor.close();

    Map<String, String> res = {};

    streamManifest.muxed.forEach((element) {
      if (element.videoQuality.toString().contains("med") ||
          element.videoQuality.toString().contains("high")) {
        var q = {
          "${element.videoResolution} / ${element.bitrate}":
              element.url.toString()
        };
        res.addAll(q);
      }
    });

    var src = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      streamInfo.url.toString(),
      resolutions: res,
      notificationConfiguration: BetterPlayerNotificationConfiguration(
        showNotification: true,
        title: widget.name,
        author: "StudyTalkIitian",
        imageUrl: widget.img,
        activityName: "MainActivity",
      ),
    );

    return io.Platform.isAndroid ? src : streamInfo.url.toString();
  }

  @override
  void initState() {
    // FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    Wakelock.enable();

    if (io.Platform.isAndroid) {
      if (widget.url.contains("youtu")) {
        initYT(widget.url);
      } else {
        BetterPlayerConfiguration betterPlayerConfiguration =
            const BetterPlayerConfiguration(
          autoPlay: true,
          aspectRatio: 16 / 9,
          fit: BoxFit.contain,
          controlsConfiguration: BetterPlayerControlsConfiguration(
              playerTheme: BetterPlayerTheme.cupertino),
        );

        print(widget.url);

        BetterPlayerDataSource dataSource =
            widget.url.contains(new RegExp(r'.m3u8', caseSensitive: false))
                ? BetterPlayerDataSource(
                    BetterPlayerDataSourceType.network,
                    widget.url,
                    videoFormat: BetterPlayerVideoFormat.hls,
                    headers: widget.url.contains(
                            new RegExp(r'master.m3u8', caseSensitive: false)) || widget.url.contains(
                            new RegExp(r'index.m3u8', caseSensitive: false))
                        ? box.get('headers_pw') != null &&
                                box.get('headers_pw').isNotEmpty
                            ? Map<String, String>.from(
                                jsonDecode(box.get('headers_pw')))
                            : {}
                        : {},
                    notificationConfiguration:
                        BetterPlayerNotificationConfiguration(
                      showNotification: true,
                      title: widget.name,
                      author: "PhysicsWallah",
                      imageUrl: widget.img,
                      activityName: "MainActivity",
                    ),
                  )
                : BetterPlayerDataSource(
                    BetterPlayerDataSourceType.network,
                    widget.url,
                    notificationConfiguration:
                        BetterPlayerNotificationConfiguration(
                      showNotification: true,
                      title: widget.name,
                      author: "PhysicsWallah",
                      imageUrl: widget.img,
                      activityName: "MainActivity",
                    ),
                  );

        _betterPlayerController =
            BetterPlayerController(betterPlayerConfiguration);
        _betterPlayerController!.setupDataSource(dataSource);
      }
    }

    // if (widget.url.contains("bitgravity")) {
    //   launchTelegram(widget.url);
    //   Navigator.pop(context);
    // }

    if (io.Platform.isWindows &&
        !widget.url.contains(".mpd") &&
        !widget.url.contains("index.m3u8") &&
        !widget.url.contains("cloudfront") &&
        !widget.url.contains("bitgravity")) {
      if (widget.url.contains("youtu")) {
        initYTWindows(widget.url);
      } else {
        player = supvid.Player(id: 69420);

        player!.open(
          supvid.Media.network(widget.url),
          autoStart: true, // default
        );

        isVlcLoaded = true;

        setState(() {});
      }
    } else if (io.Platform.isWindows) {
      // launchTelegram(widget.url);
      mpvprocessRun(widget.url);
      // Navigator.pop(context);
    }

    // print(widget.url);

    super.initState();
  }

  void checkandDisposeWindows() {
    if (io.Platform.isWindows &&
        !widget.url.contains(".mpd") &&
        !widget.url.contains("index.m3u8") &&
        !widget.url.contains("cloudfront") &&
        !widget.url.contains("bitgravity")) {
      player!.dispose();
    }
  }

  void mpvprocessRun(videoUrl) {
    var useHead =
        widget.url.contains("index.m3u8") || widget.url.contains("master.m3u8")
            ? true
            : false;
    var headers = Map<String, String>.from(jsonDecode(box.get('headers_pw')));
    var heads = [];
    headers.forEach((key, value) {
      if(!(key== 'User-Agent')){
      heads.add( "$key: $value" );
      }
    });

    var final_headre = heads.join(",");

    String mainPath = io.Platform.resolvedExecutable;
    mainPath = mainPath.substring(0, mainPath.lastIndexOf("\\"));
    mainPath = useHead
        ? "$mainPath\\mpv_paste_in_build\\mpv.exe --http-header-fields=\"$final_headre\""
        : "$mainPath\\mpv_paste_in_build\\mpv.exe";


    print(mainPath);
    var result = io.Process.run(mainPath, [videoUrl]);
    try{
    result.then((value) {
      print(value.exitCode);
      Navigator.pop(context);
    });
    }catch(ex){
      print(ex);
    }

  }

  @override
  void dispose() {
    io.Platform.isAndroid
        ? _betterPlayerController?.dispose()
        : checkandDisposeWindows(); // :    _controller.dispose();

    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            io.Platform.isAndroid
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _betterPlayerController != null
                        ? BetterPlayer(controller: _betterPlayerController!)
                        : Center(child: CircularProgressIndicator())

                    // child: PodVideoPlayer(controller: controller),
                    )
                : isVlcLoaded
                    ? Center(
                        child: supvid.Video(
                          player: player,
                          height: queryData.size.width * 1 / 3,
                          width: queryData.size.width,
                          scale: 1.0, // default
                          showControls: true, // show lol
                          showFullscreenButton: true,
                        ),
                      )
                    : Center(child: CircularProgressIndicator()),
            const SizedBox(height: 20),
            io.Platform.isWindows &&
                    !widget.url.contains(".mpd") &&
                    !widget.url.contains("index.m3u8") &&
                    !widget.url.contains("cloudfront") &&
                    !widget.url.contains("bitgravity")
                ? isVlcLoaded
                    ? Column(
                        children: [
                          Text(
                              'Playback rate control : ${player!.general.rate.toString()}.'),
                          const Divider(
                            height: 8.0,
                            color: Colors.transparent,
                          ),
                          Slider(
                            min: 0.5,
                            max: 3.0,
                            value: player!.general.rate,
                            onChanged: (rate) {
                              player!.setRate(rate);
                              this.setState(() {});
                            },
                          ),
                        ],
                      )
                    : SizedBox()
                : !io.Platform.isAndroid
                    ? Column(
                        children: [
                          Center(
                            child: Text(
                              "PLEASE WAIT PLAYER WILL LOAD",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            height: 50,
                          ),
                          Center(
                            child: Text(
                              "Keyboard Controls: ",
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Speed Increase/Decrease:",
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "(Square Brackets)",
                                  style: TextStyle(fontSize: 30),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Play/Pause:",
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Spacebar",
                                  style: TextStyle(fontSize: 30),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "10 second forward/backward",
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "ARROW KEYS",
                                  style: TextStyle(fontSize: 30),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : SizedBox(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Dont Forget to show Love to Torflix ❤",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
