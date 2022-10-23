import 'package:flutter/material.dart';

class VideoPlayerControlle extends ChangeNotifier {
  bool _firstClick = false;
  bool _showTopControls = false;
  bool _showBottomControls = false;

  bool _pause = false;
  bool _voltar10s = false;
  bool _avancar10s = false;
  bool _volume = false;
  double _speed = 1.0;
  bool _fullScreen = false;

  String _position = "00:00";
  String _duration = "00:00";

  set position(String position) {
    this._position = position;
    notifyListeners();
  }

  String get position {
    return this._position;
  }

  set duration(String duration) {
    this._duration = duration;
    notifyListeners();
  }

 String  get duration {
    return this._duration;
  }

  set firstClick(bool firstClick) {
    this._firstClick = firstClick;
    notifyListeners();
  }

  bool get firstClick {
    return this._firstClick;
  }

  set pause(bool pause) {
    this._pause = pause;
    notifyListeners();
  }

 bool get pause {
    return this._pause;
  }

  set voltar10s(bool voltar10s) {
    this._voltar10s = voltar10s;
    notifyListeners();
  }

  bool get voltar10s {
    return this._voltar10s;
  }

  set avancar10s(bool avancar10s) {
    this._avancar10s = avancar10s;
    notifyListeners();
  }

 bool get avancar10s {
    return this._avancar10s;
  }

  set speed(double speed) {
    this._speed = speed;
    notifyListeners();
  }

  double get speed {
    return this._speed;
  }

  set volume(bool volume) {
    this._volume = volume;
    notifyListeners();
  }

 bool get volume {
    return this._volume;
  }

  set fullScreen(bool fullScreen) {
    this._fullScreen = fullScreen;
    notifyListeners();
  }

  bool get fullScreen {
    return this._fullScreen;
  }

  set showTopControls(bool showTopControls) {
    this._showTopControls = showTopControls;
    notifyListeners();
  }

 bool get showTopControls {
    return this._showTopControls;
  }

  set showBottomControls(bool showBottomControls) {
    this._showBottomControls = showBottomControls;
    notifyListeners();
  }

 bool get showBottomControls {
    return this._showBottomControls;
  }

  void resetData() {
    this._firstClick = false;
    this._showBottomControls = false;
    this._showTopControls = false;
    this._pause = false;
    this._voltar10s = false;
    this._avancar10s = false;
    this._volume = false;
    this._speed = 1.0;
    this._fullScreen = false;
    this._position = "00:00";
    this._duration = "00:00";
    notifyListeners();
  }
}
