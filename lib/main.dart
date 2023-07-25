import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_meedu_videoplayer/init_meedu_player.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

// import 'package:physicswallah/components/ShowSheetsCourses.dart';
// import 'package:physicswallah/pages/MainHome.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:seedr_app/pages/HomePage.dart';
// import 'package:flutter_native_view/flutter_native_view.dart';
import 'package:seedr_app/pages/LoginScreen.dart';
// import 'package:seedr_app/pages/LoginScreenNew.dart';
import 'package:seedr_app/pages/SearchPage.dart';
import 'package:seedr_app/pages/SearchTMDB.dart';
import 'package:seedr_app/pages/vlc_intro_player/controller/video_player_controller.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  initMeeduPlayer();

  //dont even think to enable this.........
  // HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();

  const bool kIsWeb = identical(0, 0.0);

  if (Platform.isWindows) {
    // await FlutterNativeView.ensureInitialized();
    DartVLC.initialize();
  }

  if (!kIsWeb && Platform.isAndroid) {
    ByteData data = await PlatformAssetBundle().load('assets/ca/r3.pem');
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(data.buffer.asUint8List());
  }

// running stats in maincources.dart
  await Hive.initFlutter();
  await Hive.openBox('login_info'); //  name is totally up to you
  //  name is totally up to you

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VideoPlayerControlle(),
        ),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Torflix App',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark().copyWith(
          appBarTheme: AppBarTheme(color: const Color(0xFF253341)),
          scaffoldBackgroundColor: const Color(0xFF15202B),
        ),
        themeMode: isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
        home: !boxLogin.containsKey("pass")
            // ? LoginView(
            //     switchTheme: DayNightSwitcher(
            //       isDarkModeEnabled: isDarkModeEnabled,
            //       onStateChanged: onStateChanged,
            //     ),
            //   )
            ? HomePage()
            : SearchTMLDB(
                switchTheme: DayNightSwitcher(
                  isDarkModeEnabled: isDarkModeEnabled,
                  onStateChanged: onStateChanged,
                ),
              ),
      ),
    );
  }
}
