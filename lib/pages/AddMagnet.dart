import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart';
import 'package:process_run/process_run.dart';
import 'package:seedr_app/constants.dart';
import 'package:seedr_app/pages/AllFiles.dart';
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

  Future deleteSingle(id, type) async {
    var data = {
      "func": "delete",
      "delete_arr": jsonEncode([
        {
          "type": type,
          "id": id.toString(),
        }
      ]),
      "access_token": boxLogin.get("token")
    };

    print(data);

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
          "https://www.seedr.cc/api/folder?access_token=${boxLogin.get('token')}"));

      if (allTorrentsAndFiles.statusCode == 200) {
        var d = jsonDecode(allTorrentsAndFiles.body);

        for (final t in d["torrents"]) {
          await deleteSingle(t["id"], "torrent");
        }

        for (final t in d["folders"]) {
          await deleteSingle(t["id"], "folder");
        }

        var details = {
          "func": "add_torrent",
          "torrent_magnet": magnet,
          "access_token": boxLogin.get("token")
        };

        final response = await post(
          Uri.parse('https://www.seedr.cc/oauth_test/resource.php'),
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          encoding: Encoding.getByName('utf-8'),
          body: details,
        );

        if (response.statusCode == 200) {
          var d = jsonDecode(response.body);
          print(d);

          if (d["result"] != true) {
            Get.snackbar("Error:", d["result"],
                backgroundColor: Colors.redAccent, colorText: Colors.white);
            Navigator.pop(context);
            return;
          }
          // if (d["result"] == "not_enough_space_wishlist_full") {
          //   Get.snackbar("Error:", "Not Enough Space",
          //       backgroundColor: Colors.redAccent, colorText: Colors.white);
          //   Navigator.pop(context);
          //   return;
          // }

          initialData = d;
          setState(() {});
          Timer(Duration(seconds: 3), loadProgurl);
        } else {
          print(response.body);
          Get.snackbar("Error:", "Error Occuced in adding Magnet ",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
          Navigator.pop(context);
        }
      } else {
        print(allTorrentsAndFiles.body);

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
    } else {}
  }

  void loadProgress(progurl) async {
    var response = await get(Uri.parse(progurl));
    var progDataUnformated = response.body;

    var progdata = progDataUnformated.substring(1);
    progdata = progdata.substring(1);
    progdata = progdata.substring(0, progdata.length - 1);

    print(progdata);

    Map finalProg = jsonDecode(progdata);

    if ((finalProg.containsKey("warnings") && finalProg["warnings"] != '[]') ||
        finalProg["download_rate"] == 0) {
      setState(() {
        status = "Slow Torrent Detected...";
      });

      Get.snackbar(
          "Error:", "Slow Torrent Detected select other with high seeds..",
          backgroundColor: Colors.redAccent, colorText: Colors.white);

      Timer(Duration(seconds: 3), () => Navigator.pop(context));
    } else {
      print(finalProg);
      var prog = finalProg.containsKey("progress") ? finalProg["progress"] : 0;

      setState(() {
        double proge = double.tryParse(prog.toString()) ?? 0;
        proge = proge.ceilToDouble();
        status = "Progress : $proge%";
      });

      if (prog >= 100) {
        changePageTo(context, AllFiles(), true);
        // changePageTo(context, toGo, replace)
      } else {
        Timer(Duration(seconds: 1), () {
          loadProgress(progurl);
        });
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

      loadProgress(progurl);
    }
  }

  bool peerflixUi = false;

  @override
  void initState() {
    // addMagnet(widget.magnet);
    super.initState();
  }

  bool showProg = false;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    void mpcprocessRun(videoUrl) {
      String mainPath = Platform.resolvedExecutable;
      mainPath = mainPath.substring(0, mainPath.lastIndexOf("\\"));
      mainPath = "$mainPath\\mpc_paste_in_build\\mpc-hc.exe";

      print(mainPath);
      var result = Process.run(mainPath, [videoUrl]);
      try {
        result.then((value) {
          try {
            Shell().run('taskkill /f /im node.exe');
          } catch (ex) {
            print(ex);
          }
          print(value.exitCode);
          Navigator.pop(context);
        });
      } catch (ex) {
        print(ex);
      }
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Center(
            child: !peerflixUi
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 50),
                      Text(
                        'Adding Magnet.',
                        style: kLoginTitleStyle(size),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text(
                          initialData.isEmpty ? '....' : initialData["title"],
                          style: kLoginSubtitleStyle(size),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      status.isEmpty
                          ? CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Text(
                                status,
                                style: TextStyle(
                                    fontSize: 25, fontWeight: FontWeight.w500),
                              ),
                            ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            bool gotUrl = false;
                            final _stdoutCtlr = StreamController<List<int>>();
                            final _stderrCtlr = StreamController<List<int>>();
                            var shell = Shell(
                                stdout: _stdoutCtlr.sink,
                                stderr: _stderrCtlr.sink,
                                throwOnError: false);

                            _stdoutCtlr.stream.listen((event) {
                              if (gotUrl) {
                                return;
                              }
                              var log = utf8.decode(event);
                              var first = log.split("\n")[0];
                              first =
                                  first.replaceAll("open vlc and enter ", "");
                              first = first.replaceAll(
                                  " as the network address", "");
                              print(["LOG IS;", first]);
                              if (first.contains("http://")) {
                                RegExp exp = new RegExp(
                                    r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
                                Iterable<RegExpMatch> matches =
                                    exp.allMatches(first);
                                matches.forEach((match) {
                                  var link =
                                      first.substring(match.start, match.end);
                                  mpcprocessRun(link + ":8888");
                                  gotUrl = true;
                                });
                              }
                            });

                            _stderrCtlr.stream.listen((event) {
                              print(utf8.decode(event));
                            });

                            try {
                              // var run = shell.runExecutableArguments(
                              //   "peerflix",
                              //   [
                              //     widget.magnet,
                              //     "--remove",
                              //     "--quiet"
                              //   ],
                              // );
                              var d = shell.run(
                                  "peerflix ${widget.magnet} --remove --quiet");
                            } catch (ex) {
                              print(ex);
                            }
                          },
                          child: Text("Open in Peerflix")),
                      SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              peerflixUi = false;
                            });
                            addMagnet(widget.magnet);
                          },
                          child: Text("Continue Normally"))
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
