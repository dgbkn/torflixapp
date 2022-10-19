import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:seedr_app/constants.dart';
import 'package:seedr_app/pages/SearchPage.dart';
import 'package:seedr_app/utils.dart';

var boxLogin = Hive.box("login_info");

class AddMagnet extends StatefulWidget {
  final magnet;
  const AddMagnet({super.key, required this.magnet});

  @override
  State<AddMagnet> createState() => _AddMagnetState();
}

class _AddMagnetState extends State<AddMagnet> {
  var initialData = {};
  var status = '';

  void deleteSingle(id, type) async {
    var data = {
      "func": "delete",
      "delete_arr": [
        {"type": type, "id": id, "access_token": boxLogin.get("token")}
      ]
    };

    final response = await post(
      Uri.parse('https://www.seedr.cc/oauth_test/resource.php'),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      encoding: Encoding.getByName('utf-8'),
      body: data,
    );

    print(response.body);
  }

  void addMagnet(magnet) async {
    var connected = await checkUserConnection();

    if (connected) {
      var allTorrentsAndFiles = await get(Uri.parse(
          "https://www.seedr.cc/api/folder?access_token=${boxLogin.get("token")}"));

      if (allTorrentsAndFiles.statusCode == 200) {
        var d = jsonDecode(allTorrentsAndFiles.body);

        d["torrents"].forEach((t) => deleteSingle(t["id"], "torrent"));
        d["folders"].forEach((t) => deleteSingle(t["id"], "folder"));

      } else {
        var details = {
          "grant_type": "password",
          "client_id": "seedr_chrome",
          "type": "login",
          "username": boxLogin.get("user"),
          "password": boxLogin.get("pass")
        };

        final response = await post(
          Uri.parse('https://www.seedr.cc/oauth_test/token.php'),
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          encoding: Encoding.getByName('utf-8'),
          body: details,
        );

        if (response.statusCode == 200) {
          // If the server did return a 200 OK response,
          // then parse the JSON.
          var d = jsonDecode(response.body);
          Get.snackbar("Login Success", "",
              backgroundColor: Colors.greenAccent, colorText: Colors.white);
          var token = d["access_token"];
          boxLogin.put("token", token);
          addMagnet(widget.magnet);
        } else {
          Get.snackbar("Error:", "Login Expired",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
          boxLogin.delete("user");
          boxLogin.delete("pass");
          boxLogin.delete("token");
          SystemNavigator.pop();
        }
      }

      var details = {"func": "add_torrent", "torrent_magnet": magnet};

      final response = await post(
        Uri.parse('https://www.seedr.cc/oauth_test/token.php'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        encoding: Encoding.getByName('utf-8'),
        body: details,
      );

      if (response.statusCode == 200) {
        var d = jsonDecode(response.body);
        initialData = d;
        setState(() {});
        Timer(Duration(seconds: 3), loadProgurl);
      } else {
        Get.snackbar("Error:", "Error Occuced in adding Magnet ",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        Navigator.pop(context);
      }
    } else {}
  }

  void loadProgress(Timer timer, progurl) async {
    var response = await get(progurl);
    var progDataUnformated = response.body;
    print(progDataUnformated);

    var progdata = progDataUnformated.substring(1);
    progdata = progdata.substring(1);
    progdata = progdata.substring(0, 2);

    Map finalProg = jsonDecode(progdata);

    if ((finalProg.containsKey("warnings") && finalProg["warnings"] != '[]') ||
        finalProg["download_rate"] == 0) {
      timer.cancel();
      setState(() {
        status = "Slow Torrent Detected...";
      });

      Timer(Duration(seconds: 3),
          () => changePageTo(context, SearchPage(), true));
    } else {
      var prog = finalProg["progress"];
      setState(() {
        status = "Progress : $prog";
      });

      if(int.parse(prog) > 98){
        // changePageTo(context, toGo, replace)
      }
    }
  }

  void loadProgurl() async {
    var allTorrentsAndFiles = await get(Uri.parse(
        "https://www.seedr.cc/api/folder?access_token=${boxLogin.get("token")}"));

    if (allTorrentsAndFiles.statusCode == 200) {
      var d = jsonDecode(allTorrentsAndFiles.body);

      var progurl = d["torrents"][0]["progress_url"];
      print(progurl);

      Timer.periodic(
          Duration(seconds: 1), (timer) => loadProgress(timer, progurl));
    }
  }

  @override
  void initState() {
    super.initState();
  }

  bool showProg = false;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.0, top: 20),
                child: Text(
                  'Adding Magnet.',
                  style: kLoginTitleStyle(size),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text(
                  initialData.isEmpty ? '....' : initialData["title"],
                  style: kLoginSubtitleStyle(size),
                ),
              ),
              status.isEmpty
                  ? CircularProgressIndicator()
                  : Text(
                      status,
                      style: kLoginTermsAndPrivacyStyle(size),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
