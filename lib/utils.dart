import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Widget renderButton(icon, text, Color textcolor, Color btnColor, onTap) {
  return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: Card(
          color: btnColor,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                icon,
                SizedBox(
                  width: 5,
                ),
                Text(
                  text,
                  style:
                      TextStyle(color: textcolor, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ));
}

void changePageTo(BuildContext context, Widget toGo, bool replace) {
  if (replace) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => toGo,
        ));
  } else {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => toGo,
        ));
  }
}

Future checkUserConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } on SocketException catch (_) {
    return false;
  }
}

Future<void> launchUrlinChrome(tg_link) async {
  var url = Uri.parse(tg_link);
  if (!await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  )) {
    throw 'Could not launch $url';
  }
}

String? convertUrlToId(String url, {bool trimWhitespaces = true}) {
  assert(url.isNotEmpty, 'Url cannot be empty');
  String _url;
  if (!url.contains('http') && (url.length == 11)) return url;
  if (trimWhitespaces) {
    _url = url.trim();
  } else {
    _url = url;
  }

  for (final exp in [
    RegExp(
        r'^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$'),
    RegExp(
        r'^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$'),
    RegExp(r'^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$')
  ]) {
    final Match match = exp.firstMatch(_url) as Match;
    if (match != null && match.groupCount >= 1) return match.group(1);
  }

  return null;
}

void showLoading(context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Loading"),
              ),
            ],
          ),
        ),
      );
    },
  );
}
