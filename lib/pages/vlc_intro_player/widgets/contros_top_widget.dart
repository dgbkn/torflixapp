import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../controller/video_player_controller.dart';
import 'package:provider/provider.dart';

class ControlsTopWidget extends StatelessWidget {
  VlcPlayerController controller;

  ControlsTopWidget({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Container(
          width: width,
          child: GestureDetector(
            onTap: () {
              Provider.of<VideoPlayerControlle>(context, listen: false)
                      .firstClick =
                  !Provider.of<VideoPlayerControlle>(context, listen: false)
                      .firstClick;
            },
          ),
        ),
        Provider.of<VideoPlayerControlle>(context).firstClick
            ? Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).orientation == Orientation.portrait ? height * 0.1 : height * 0.17,
                      width: MediaQuery.of(context).orientation == Orientation.portrait ?  height * 0.1 : height * 0.17,
                      child: GestureDetector(
                        onTap: () {
                          Provider.of<VideoPlayerControlle>(context,
                                  listen: false)
                              .voltar10s = !Provider.of<VideoPlayerControlle>(
                                  context,
                                  listen: false)
                              .voltar10s;
                          controller.seekTo(Duration(
                              seconds:
                                  controller.value.position.inSeconds - 10));
                        },
                        child: SvgPicture.asset(
                          "assets/icons/icon-voltar-10s.svg",
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width * 0.03,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).orientation == Orientation.portrait ? height * 0.15 : height * 0.25,
                      width: MediaQuery.of(context).orientation == Orientation.portrait ? height * 0.15 : height * 0.25,
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
                            Future.delayed(Duration(seconds: 2), (){
                              Provider.of<VideoPlayerControlle>(context,listen: false).firstClick = false;
                            });
                          }
                        },
                        child: Provider.of<VideoPlayerControlle>(context).pause
                            ? SvgPicture.asset(
                                "assets/icons/icon-play.svg",
                                color: Colors.white,
                              )
                            : SvgPicture.asset(
                                "assets/icons/icon-pause-small.svg",
                              ),
                      ),
                    ),
                    SizedBox(
                      width: width * 0.03,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).orientation == Orientation.portrait ?  height * 0.1 : height * 0.17,
                      width: MediaQuery.of(context).orientation == Orientation.portrait ?  height * 0.1 : height * 0.17,
                      child: GestureDetector(
                        onTap: () {
                          Provider.of<VideoPlayerControlle>(context,
                                  listen: false)
                              .avancar10s = !Provider.of<VideoPlayerControlle>(
                                  context,
                                  listen: false)
                              .avancar10s;
                          controller.seekTo(Duration(
                              seconds:
                                  controller.value.position.inSeconds + 10));
                        },
                        child: SvgPicture.asset(
                          "assets/icons/icon-avancar-10s.svg",
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(),
      ],
    );
  }
}
