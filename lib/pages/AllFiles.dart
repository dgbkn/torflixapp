import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:seedr_app/constants.dart';
import 'package:seedr_app/pages/VideoPlayer.dart';
import 'package:seedr_app/utils.dart';

var boxLogin = Hive.box("login_info");

class AllFiles extends StatefulWidget {
  const AllFiles({super.key});

  @override
  State<AllFiles> createState() => _AllFilesState();
}

class _AllFilesState extends State<AllFiles> {
  var files = <Container>[];

  void loadFiles() async {
    var connected = await checkUserConnection();

    if (connected) {
      var allTorrentsAndFiles = await get(Uri.parse(
          "https://www.seedr.cc/api/folder?access_token=${boxLogin.get('token')}"));

      if (allTorrentsAndFiles.statusCode == 200) {
        var d = jsonDecode(allTorrentsAndFiles.body);

        for (final t in d["folders"]) {
          var allFiles = await get(Uri.parse(
              "https://www.seedr.cc/api/folder/${t['id']}?access_token=${boxLogin.get('token')}"));

          var f = jsonDecode(allFiles.body);
          print(f);

          f["files"].forEach((file) {
            bool isVideo = file["name"].contains(".mkv") ||
                file["name"].contains(".mp4") ||
                file["name"].contains(".avi");

            files.add(Container(
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(children: [
                        Icon(isVideo
                            ? Icons.video_file_rounded
                            : Icons.file_copy),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                              child: Text(file["name"],
                                  overflow: TextOverflow.ellipsis),
                              width: 300),
                        )
                      ]),
                      //IMPLEMET OPEN IN MX <> VLC
                      Row(children: [
                        isVideo
                            ? ElevatedButton(
                                onPressed: () async {
                                  showLoading(context);

                                  var details = {
                                    "func": "play_video",
                                    "folder_file_id":
                                        file["folder_file_id"].toString(),
                                    "access_token": boxLogin.get("token")
                                  };

                                  final response = await post(
                                    Uri.parse(
                                        'https://www.seedr.cc/oauth_test/resource.php'),
                                    headers: {
                                      "Content-Type":
                                          "application/x-www-form-urlencoded",
                                    },
                                    encoding: Encoding.getByName('utf-8'),
                                    body: details,
                                  );

                                  Navigator.pop(context);
                                  var st = response.body;

                                  var stt = jsonDecode(st);
                                  var uri = stt["url_hls"];
                                  var pre = stt["url_preroll"];

                                  changePageTo(
                                      context,
                                      VideoPlayer(
                                        img: pre,
                                        url: uri,
                                        name: file["name"],
                                      ),
                                      false);
                                },
                                child: Text("Play SD"))
                            : SizedBox(),
                        isVideo
                            ? ElevatedButton(
                                onPressed: () async {
                                  showLoading(context);

                                  var details = {
                                    "func": "fetch_file",
                                    "folder_file_id":
                                        file["folder_file_id"].toString(),
                                    "access_token": boxLogin.get("token")
                                  };

                                  final response = await post(
                                    Uri.parse(
                                        'https://www.seedr.cc/oauth_test/resource.php'),
                                    headers: {
                                      "Content-Type":
                                          "application/x-www-form-urlencoded",
                                    },
                                    encoding: Encoding.getByName('utf-8'),
                                    body: details,
                                  );

                                  Navigator.pop(context);
                                  var st = response.body;

                                  var stt = jsonDecode(st);
                                  var uri = stt["url"];
                                  var pre =
                                      "https://i.ibb.co/Y8JWphq/istockphoto-911590226-612x612.jpg";

                                  changePageTo(
                                      context,
                                      VideoPlayer(
                                        img: pre,
                                        url: uri,
                                        name: file["name"],
                                      ),
                                      false);
                                },
                                child: Text("Play HD"))
                            : SizedBox(),
                        ElevatedButton(
                            onPressed: () async {
                              showLoading(context);

                              var details = {
                                "func": "fetch_file",
                                "folder_file_id":
                                    file["folder_file_id"].toString(),
                                "access_token": boxLogin.get("token")
                              };

                              final response = await post(
                                Uri.parse(
                                    'https://www.seedr.cc/oauth_test/resource.php'),
                                headers: {
                                  "Content-Type":
                                      "application/x-www-form-urlencoded",
                                },
                                encoding: Encoding.getByName('utf-8'),
                                body: details,
                              );

                              Navigator.pop(context);
                              var st = response.body;

                              var stt = jsonDecode(st);
                              var uri = stt["url"];
                              launchUrlinChrome(uri);
                            },
                            child: Text("Download")),
                      ]),

                      isVideo && Platform.isAndroid
                          ? Row(
                              children: [
                                DropdownButton<String>(
                                  items: <String>[
                                    'VLC',
                                    'MX Player Pro',
                                    'MX Player',
                                    'NPlayer'
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  hint: Text("Launch HD Video in:"),
                                  onChanged: (_) async {
                                    print(_);
                                    showLoading(context);

                                    var details = {
                                      "func": "fetch_file",
                                      "folder_file_id":
                                          file["folder_file_id"].toString(),
                                      "access_token": boxLogin.get("token")
                                    };

                                    final response = await post(
                                      Uri.parse(
                                          'https://www.seedr.cc/oauth_test/resource.php'),
                                      headers: {
                                        "Content-Type":
                                            "application/x-www-form-urlencoded",
                                      },
                                      encoding: Encoding.getByName('utf-8'),
                                      body: details,
                                    );

                                    Navigator.pop(context);
                                    var st = response.body;

                                    var stt = jsonDecode(st);
                                    var uri = stt["url"];

                                    switch (_) {
                                      case "VLC":
                                        AndroidIntent intent = AndroidIntent(
                                          action: 'action_view',
                                          type:'video/*',
                                          data: Uri.encodeFull(uri).toString(),
                                          package: 'org.videolan.vlc',
                                          arguments: {'title': file["name"]},
                                              flags: <int>[
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
        ],
                                        );
                                        await intent.launch();
                                        break;
                                      case "MX Player Pro":
                                        AndroidIntent intent = AndroidIntent(
                                          action: 'action_view',
                                          data: Uri.encodeFull(uri),
                                          package: 'com.mxtech.videoplayer.pro',
                                        );
                                        await intent.launch();
                                        break;
                                      case "MX Player":
                                        AndroidIntent intent = AndroidIntent(
                                          action: 'action_view',
                                          data: Uri.encodeFull(uri),
                                          package: 'com.mxtech.videoplayer.ad',
                                        );
                                        await intent.launch();
                                        break;
                                      case "NPlayer":
                                        AndroidIntent intent = AndroidIntent(
                                          action: 'action_view',
                                          data: Uri.encodeFull(uri),
                                          package:
                                              'package:com.qinxiandiqi.nplayer',
                                        );
                                        await intent.launch();
                                        break;
                                    }
                                  },
                                ),
                              ],
                            )
                          : SizedBox()
                    ],
                  ),
                ),
              ),
            ));
          });

          setState(() {});
        }
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
          loadFiles();
        } else {
          Get.snackbar("Error:", "Login Expired",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
          boxLogin.delete("user");
          boxLogin.delete("pass");
          boxLogin.delete("token");
          SystemNavigator.pop();
        }
      }
    } else {}
  }

  @override
  void initState() {
    loadFiles();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(backgroundColor: Colors.grey),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "All Files",
                    style: kLoginTitleStyle(size),
                  ),
                ),
                files.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : Center(
                        child: Wrap(
                          children: files,
                        ),
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
