import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
