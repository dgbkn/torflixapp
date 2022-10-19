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



  void addMagnet(magnet) async {
    var connected = await checkUserConnection();

    if (connected) {
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

  void loadProgurl() async {
    var allTorrentsAndFiles = await get(Uri.parse(
        "https://www.seedr.cc/api/folder?access_token=${boxLogin.get("token")}"));
    if (allTorrentsAndFiles.statusCode == 200) {
      var d = jsonDecode(allTorrentsAndFiles.body);
    } else {
      Get.snackbar("Error:", "Login Expired",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      boxLogin.delete("user");
      boxLogin.delete("pass");
      boxLogin.delete("token");
      SystemNavigator.pop();
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
