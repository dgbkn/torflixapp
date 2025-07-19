import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:seedr_app/components/DayNightSwitcher.dart';

import 'package:seedr_app/pages/HomePage.dart';
import 'package:seedr_app/pages/LoginScreen.dart';
import 'package:seedr_app/pages/SearchPage.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  //dont even think to enable this.........
  // HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  const bool kIsWeb = identical(0, 0.0);

  if (!kIsWeb && Platform.isAndroid) {
    ByteData data = await PlatformAssetBundle().load('assets/ca/r3.pem');
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(data.buffer.asUint8List());
  }

  await Hive.initFlutter();

  await Hive.openBox('login_info');

  runApp(const SeedrApp());
}

class SeedrApp extends StatefulWidget {
  const SeedrApp({Key? key}) : super(key: key);

  @override
  State<SeedrApp> createState() => _SeedrAppState();
}

class _SeedrAppState extends State<SeedrApp> {
  bool isDarkModeEnabled = false;

  /// Called when the state (day / night) has changed.
  void onStateChanged(bool isDarkModeEnabled) {
    setState(() {
      this.isDarkModeEnabled = isDarkModeEnabled;
    });
  }

  var boxLogin = Hive.box("login_info");

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Torflix App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(color: const Color(0xFF253341)),
        scaffoldBackgroundColor: const Color(0xFF15202B),
      ),
      themeMode: isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: !boxLogin.containsKey("pass")
          ? LoginScreen(
              switchTheme: DayNightSwitcher(
                isDarkModeEnabled: isDarkModeEnabled,
                onStateChanged: onStateChanged,
              ),
            )
          : SearchPage(
              switchTheme: DayNightSwitcher(
                isDarkModeEnabled: isDarkModeEnabled,
                onStateChanged: onStateChanged,
              ),
            ),
    );
  }
}
