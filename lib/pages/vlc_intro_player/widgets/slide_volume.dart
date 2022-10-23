import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class SlideVolumeWidget extends StatefulWidget {
  VlcPlayerController controller;

  SlideVolumeWidget({
    required this.controller,
  });

  @override
  _SlideVolumeWidgetState createState() => _SlideVolumeWidgetState();
}

class _SlideVolumeWidgetState extends State<SlideVolumeWidget> {
  double sliderValue = 100.0;

  void _onSliderPositionChanged(double progress) {
    setState(() {
      sliderValue = progress.floor().toDouble();
    });
    //convert to Milliseconds since VLC requires MS to set time
    this.widget.controller.setVolume(sliderValue.toInt());
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(
        left: MediaQuery.of(context).orientation == Orientation.portrait
            ? width * 0.025
            : width * 0.015,
        right: MediaQuery.of(context).orientation == Orientation.portrait
            ? width * 0.025
            : width * 0.015,
        bottom: MediaQuery.of(context).orientation == Orientation.portrait
            ? height * 0.015
            : height * 0.0225,
      ),
      width: width * 0.2,
      height: height * 0.03,
      child: SizedBox(
        width: width * 0.2,
        height: height * 0.03,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.5,
            trackShape: CustomTrackShape(),
          ),
          child: Slider(
            activeColor: Colors.red,
            inactiveColor: Colors.white70,
            value: sliderValue,
            min: 0.0,
            max: 100,
            onChanged: _onSliderPositionChanged,
          ),
        ),
      ),
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double? trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight!);
    // final double trackTop = 0;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight!);
  }
}
