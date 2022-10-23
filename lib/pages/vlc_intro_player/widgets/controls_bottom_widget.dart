import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../controller/video_player_controller.dart';
import '../widgets/slide_volume.dart';
import 'package:provider/provider.dart';

class ControlsBottomWidget extends StatelessWidget {
  VlcPlayerController controller;

  ControlsBottomWidget({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    Widget getStatusBarButton(onTap, IconData icon) {
      return Row(
        children: [
          Container(
            height: MediaQuery.of(context).orientation == Orientation.portrait
                ? height * 0.03
                : height * 0.05,
            width: MediaQuery.of(context).orientation == Orientation.portrait
                ? height * 0.03
                : height * 0.05,
            child: GestureDetector(
              onTap: onTap,
              child: Stack(
                children: [
                  Icon(icon,
                      color: Colors.white,
                      size: MediaQuery.of(context).orientation ==
                              Orientation.portrait
                          ? height * 0.025
                          : height * 0.045),
                  Container(
                    margin: EdgeInsets.only(
                      left: MediaQuery.of(context).orientation ==
                              Orientation.portrait
                          ? height * (0.03 - 0.017)
                          : height * (0.05 - 0.025),
                      top: MediaQuery.of(context).orientation ==
                              Orientation.portrait
                          ? height * (0.03 - 0.017)
                          : height * (0.05 - 0.025),
                    ),
                    height: MediaQuery.of(context).orientation ==
                            Orientation.portrait
                        ? height * 0.017
                        : height * 0.025,
                    width: MediaQuery.of(context).orientation ==
                            Orientation.portrait
                        ? height * 0.017
                        : height * 0.025,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(90),
                    ),
                    child: Center(
                      child: Text(
                        Provider.of<VideoPlayerControlle>(context)
                            .speed
                            .toString(),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).orientation ==
                                    Orientation.portrait
                                ? height * 0.008
                                : height * 0.012),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: width * 0.015,
          ),
        ],
      );
    }

      void _getAudioTracks(VlcPlayerController _controller) async {
    if (!_controller.value.isPlaying) return;

    var audioTracks = await _controller.getAudioTracks();
    //
    if (audioTracks != null && audioTracks.isNotEmpty) {
      var selectedAudioTrackId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Audio'),
            content: Container(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: audioTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < audioTracks.keys.length
                          ? audioTracks.values.elementAt(index).toString()
                          : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < audioTracks.keys.length
                            ? audioTracks.keys.elementAt(index)
                            : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedAudioTrackId != null) {
        await _controller.setAudioTrack(selectedAudioTrackId);
      }
    }
  }

    void _getSubtitleTracks(VlcPlayerController _controller) async {
    if (!_controller.value.isPlaying) return;

    var subtitleTracks = await _controller.getSpuTracks();
    //
    if (subtitleTracks != null && subtitleTracks.isNotEmpty) {
      var selectedSubId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Subtitle'),
            content: Container(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: subtitleTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < subtitleTracks.keys.length
                          ? subtitleTracks.values.elementAt(index).toString()
                          : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < subtitleTracks.keys.length
                            ? subtitleTracks.keys.elementAt(index)
                            : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedSubId != null) await _controller.setSpuTrack(selectedSubId);
    }
  }

    return Provider.of<VideoPlayerControlle>(context).firstClick
        ? Container(
            margin: EdgeInsets.symmetric(horizontal: width * 0.01),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Row(
                    children: [
                      Container(
                        height: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.03
                            : height * 0.05,
                        width: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.03
                            : height * 0.05,
                        child: GestureDetector(
                          onTap: () {
                            Provider.of<VideoPlayerControlle>(context,
                                    listen: false)
                                .pause = !Provider.of<VideoPlayerControlle>(
                                    context,
                                    listen: false)
                                .pause;
                            if (Provider.of<VideoPlayerControlle>(context,
                                    listen: false)
                                .pause) {
                              controller.pause();
                            } else {
                              controller.play();
                              Future.delayed(Duration(seconds: 2), () {
                                Provider.of<VideoPlayerControlle>(context,
                                        listen: false)
                                    .firstClick = false;
                              });
                            }
                          },
                          child: Provider.of<VideoPlayerControlle>(context,
                                      listen: false)
                                  .pause
                              ? SvgPicture.asset(
                                  "assets/icons/icon-play.svg",
                                  color: Colors.white,
                                )
                              : SvgPicture.asset(
                                  "assets/icons/icon-pause-small.svg",
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      SizedBox(
                        width: width * 0.01,
                      ),
                      Container(
                        height: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.03
                            : height * 0.05,
                        width: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.03
                            : height * 0.05,
                        child: GestureDetector(
                          onTap: () {
                            Provider.of<VideoPlayerControlle>(context,
                                    listen: false)
                                .voltar10s = !Provider.of<VideoPlayerControlle>(
                                    context,
                                    listen: false)
                                .voltar10s;
                            if (Provider.of<VideoPlayerControlle>(context,
                                    listen: false)
                                .voltar10s) {
                              controller.seekTo(
                                Duration(
                                  seconds:
                                      controller.value.position.inSeconds - 10,
                                ),
                              );
                            }
                          },
                          child: SvgPicture.asset(
                            "assets/icons/icon-voltar-10s.svg",
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width * 0.01,
                      ),
                      Container(
                        height: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.03
                            : height * 0.05,
                        width: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.03
                            : height * 0.05,
                        child: GestureDetector(
                          onTap: () {
                            Provider.of<VideoPlayerControlle>(context,
                                        listen: false)
                                    .avancar10s =
                                !Provider.of<VideoPlayerControlle>(context,
                                        listen: false)
                                    .avancar10s;

                            if (Provider.of<VideoPlayerControlle>(context,
                                    listen: false)
                                .avancar10s) {
                              controller.seekTo(
                                Duration(
                                  seconds:
                                      controller.value.position.inSeconds + 10,
                                ),
                              );
                            }
                          },
                          child: SvgPicture.asset(
                            "assets/icons/icon-avancar-10s.svg",
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width * 0.01,
                      ),
                      Container(
                        height: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.03
                            : height * 0.05,
                        width: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.037
                            : height * 0.057,
                        child: GestureDetector(
                          onTap: () {
                            Provider.of<VideoPlayerControlle>(context,
                                    listen: false)
                                .volume = !Provider.of<VideoPlayerControlle>(
                                    context,
                                    listen: false)
                                .volume;
                          },
                          child: controller.value.volume == 0
                              ? SvgPicture.asset(
                                  "assets/icons/icon-som-off.svg",
                                  color: Colors.white,
                                )
                              : SvgPicture.asset(
                                  "assets/icons/icon-volume-up.svg",
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      Provider.of<VideoPlayerControlle>(context).volume
                          ? SlideVolumeWidget(controller: controller)
                          : Container(),
                      SizedBox(
                        width: width * 0.01,
                      ),
                      Container(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).orientation ==
                                    Orientation.portrait
                                ? height * 0.002
                                : height * 0.0022),
                        child: Center(
                          child: Text(
                            "${Provider.of<VideoPlayerControlle>(context).position}/${Provider.of<VideoPlayerControlle>(context).duration}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).orientation ==
                                      Orientation.portrait
                                  ? height * 0.017
                                  : height * 0.025,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                      getStatusBarButton((){_getAudioTracks(controller);}, Icons.audiotrack),
                      getStatusBarButton((){_getSubtitleTracks(controller);}, Icons.closed_caption),
                      //dev controls
                      Container(
                        height: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.03
                            : height * 0.05,
                        width: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.03
                            : height * 0.05,
                        child: GestureDetector(
                          onTap: () {
                            Provider.of<VideoPlayerControlle>(context,
                                    listen: false)
                                .speed = Provider.of<VideoPlayerControlle>(
                                        context,
                                        listen: false)
                                    .speed +
                                0.5;

                            if (Provider.of<VideoPlayerControlle>(context,
                                        listen: false)
                                    .speed ==
                                2.5) {
                              Provider.of<VideoPlayerControlle>(context,
                                      listen: false)
                                  .speed = 0.5;
                            }

                            controller.setPlaybackSpeed(
                                Provider.of<VideoPlayerControlle>(context,
                                        listen: false)
                                    .speed);
                          },
                          child: Stack(
                            children: [
                              Icon(Icons.timer,
                                  color: Colors.white,
                                  size: MediaQuery.of(context).orientation ==
                                          Orientation.portrait
                                      ? height * 0.025
                                      : height * 0.045),
                              Container(
                                margin: EdgeInsets.only(
                                  left: MediaQuery.of(context).orientation ==
                                          Orientation.portrait
                                      ? height * (0.03 - 0.017)
                                      : height * (0.05 - 0.025),
                                  top: MediaQuery.of(context).orientation ==
                                          Orientation.portrait
                                      ? height * (0.03 - 0.017)
                                      : height * (0.05 - 0.025),
                                ),
                                height: MediaQuery.of(context).orientation ==
                                        Orientation.portrait
                                    ? height * 0.017
                                    : height * 0.025,
                                width: MediaQuery.of(context).orientation ==
                                        Orientation.portrait
                                    ? height * 0.017
                                    : height * 0.025,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(90),
                                ),
                                child: Center(
                                  child: Text(
                                    Provider.of<VideoPlayerControlle>(context)
                                        .speed
                                        .toString(),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: MediaQuery.of(context)
                                                    .orientation ==
                                                Orientation.portrait
                                            ? height * 0.008
                                            : height * 0.012),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width * 0.015,
                      ),
                      Container(
                        height: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.025
                            : height * 0.04,
                        width: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? height * 0.025
                            : height * 0.04,
                        child: GestureDetector(
                          onTap: () {
                            Provider.of<VideoPlayerControlle>(context,
                                        listen: false)
                                    .fullScreen =
                                !Provider.of<VideoPlayerControlle>(context,
                                        listen: false)
                                    .fullScreen;
                            if (Provider.of<VideoPlayerControlle>(context,
                                    listen: false)
                                .fullScreen) {
                              SystemChrome.setEnabledSystemUIOverlays([]);
                              SystemChrome.setPreferredOrientations(
                                  [DeviceOrientation.landscapeLeft]);
                              Provider.of<VideoPlayerControlle>(context,
                                      listen: false)
                                  .pause = false;
                              // if (Platform.isAndroid) {
                              //   SystemChrome.setEnabledSystemUIOverlays([]);
                              // }
                              // if (Platform.isIOS) {
                              //   SystemChrome.setEnabledSystemUIOverlays(
                              //       [SystemUiOverlay.bottom]);
                              // }
                            } else {
                              SystemChrome.setEnabledSystemUIOverlays([
                                SystemUiOverlay.bottom,
                                SystemUiOverlay.top
                              ]);
                              SystemChrome.setPreferredOrientations(
                                  [DeviceOrientation.portraitUp]);
                              Provider.of<VideoPlayerControlle>(context,
                                      listen: false)
                                  .pause = false;
                            }
                          },
                          child: SvgPicture.asset(
                            "assets/icons/icon-expandir.svg",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Container();
  }
}
