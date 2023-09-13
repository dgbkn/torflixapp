import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:lottie/lottie.dart';
import 'package:seedr_app/pages/SearchPage.dart';
import 'package:seedr_app/utils.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hive/hive.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSeedrLoaded = false;
  int _prog = 0;

  IO.Socket socket = IO.io('http://4.194.48.214/', <String, dynamic>{
    'autoConnect': false,
    'transports': ['websocket'],
  });

  Future loginToSeedr(user, pass) async {
    var connected = await checkUserConnection();

    if (connected) {
      var details = {
        "grant_type": "password",
        "client_id": "seedr_chrome",
        "type": "login",
        "username": user,
        "password": pass
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
        print(response.body);
        var boxLogin = Hive.box("login_info");

        boxLogin.put("user", user);
        boxLogin.put("pass", pass);
        boxLogin.put("token", token);
        changePageTo(context, SearchPage(), true);
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        var d = jsonDecode(response.body);
        Get.snackbar(d["error_description"], "Please Check The Form",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        print(response.body + user + pass);
      }

      setState(() {
        isSeedrLoaded = false;
      });
    }
  }

  bool isNumeric(String string) {
    final numericRegex = RegExp(r'^-?(([0-9]*)|(([0-9]*)\.([0-9]*)))$');

    return numericRegex.hasMatch(string);
  }

  void getAcc() {
    try {
      var email = '';
      socket.connect();

      socket.onConnect((_) {
        print('connect');
        socket.emit('startRegister', 'test');
      });
      socket.on('email', (data) {
        if (data is int) {
          setState(() {
            _prog = data;
          });
          if (_prog  > 99) {
            print("$email");
            loginToSeedr(email, '@Blassddfd34@%^');
          }
        } else {
          email = data;
        }
      });
      socket.onDisconnect((_) => print('disconnect'));
      socket.onConnectError((data) => print("ERROR" + data));
      // socket.on('fromServer', (_) => print(_));
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    getAcc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        SizedBox(
          height: 50,
        ),
        Center(
            child: Lottie.network(
                "https://assets6.lottiefiles.com/private_files/lf30_ployuqvp.json",
                width: 400)),
        Center(
          child: Text(
            "Progress : $_prog%",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
        )
      ]),
    );
  }
}
