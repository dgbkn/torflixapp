import 'package:adaptive_components/adaptive_components.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:seedr_app/constants.dart';
import 'package:seedr_app/pages/AddMagnet.dart';
import 'package:seedr_app/pages/AllFiles.dart';
import 'package:seedr_app/pages/HomePage.dart';
import 'package:seedr_app/pages/LoginScreen.dart';
import 'package:seedr_app/pages/SearchPage.dart';
import 'package:seedr_app/pages/tmdb/Movie.dart';
import 'package:seedr_app/pages/tmdb/Series.dart';
import 'package:seedr_app/utils.dart';

var boxLogin = Hive.box("login_info");

class SearchTMLDB extends StatefulWidget {
  final switchTheme;
  const SearchTMLDB({this.switchTheme});

  @override
  State<SearchTMLDB> createState() => _SearchTMLDBState();
}

class _SearchTMLDBState extends State<SearchTMLDB>
    with SingleTickerProviderStateMixin {
  TextEditingController nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  bool showProg = false;
  var queryCards = <Container>[];

  Container renderTorrent(name, subtitle, onTap, image, category) {
    double c_width = MediaQuery.of(context).size.width * 0.9;
    double responsive = c_width < 800
        ? c_width
        : c_width > 1200
            ? c_width * 0.20
            : c_width * 0.4;

    return Container(
        width: responsive,
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Image.network(image, height: responsive * 0.45),
                  SizedBox(
                    width: 10,
                  ),
                  Column(
                    // mainAxisAlignment: MainAxisAlignment.start,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: responsive * 0.5,
                        child: Text(
                          name ?? "",
                          style: TextStyle(fontWeight: FontWeight.w600),
                          softWrap: true,
                        ),
                      ),
                      Container(
                        width: responsive * 0.5,
                        child: Text(
                          subtitle ?? "",
                        ),
                      ),
                      Container(
                        width: responsive * 0.5,
                        child: Text(
                          "type:" + category ?? "",
                          style: TextStyle(fontWeight: FontWeight.w600),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Future loadSearch(qry) async {
    queryCards = <Container>[];
    var connected = await checkUserConnection();

    if (connected) {
      var tmdb_search =
          "https://api.themoviedb.org/3/search/multi?api_key=11df31d6a6ca0ba9a5a48329717c59bc&language=en-US&query=${Uri.encodeComponent(qry)}&include_adult=true";

      var tmdbData = await get(Uri.parse(tmdb_search));

      var data = jsonDecode(tmdbData.body);

      data = data["results"];

      data.forEach((element) {
        switch (element["media_type"]) {
          case "movie":
            queryCards.add(
                renderTorrent(element["title"], element["release_date"], () {
              changePageTo(context, Movie(id: element["id"]), false);
            },
                    "https://image.tmdb.org/t/p/w300" +
                        (element["poster_path"] ??
                            "/nGf1tzFVu3FLVsraCExsAEOnaUL.jpg"),
                    element["media_type"]));
            break;
          case "tv":
            queryCards.add(renderTorrent(
                element["name"], element["first_air_date"], () {
               changePageTo(context, Series(id: element["id"]), false);

            },
                "https://image.tmdb.org/t/p/w300" +
                    (element["poster_path"] ??
                        "/nGf1tzFVu3FLVsraCExsAEOnaUL.jpg"),
                element["media_type"]));
            break;
          case "person":
            queryCards.add(renderTorrent(
                element["name"], element["known_for_department"], () async {
              var connected = await checkUserConnection();

              if (connected) {
                var tmdb_search =
                    "https://api.themoviedb.org/3/person/${element["id"]}?api_key=11df31d6a6ca0ba9a5a48329717c59bc&language=en-US";
              }
            },
                "https://image.tmdb.org/t/p/w300" +
                    (element["poster_path"] ??
                        "/nGf1tzFVu3FLVsraCExsAEOnaUL.jpg"),
                element["media_type"]));
            break;
        }
      });

      setState(() {
        showProg = false;
      });
    } else {
      Get.snackbar("No Internet", "Please Check Network Connection",
          icon: Icon(Icons.offline_bolt_rounded),
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: LayoutBuilder(
            builder: (context, constraints) {
              return _buildMainBody(size);
            },
          ),
        ),
      ),
    );
  }

  /// Main Body
  Widget _buildMainBody(
    Size size,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Center(
          //   child: Image.asset(
          //     'assets/img/logo/splash_logo.png',
          //     height: 200,
          //   ),
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              widget.switchTheme != null ? widget.switchTheme : SizedBox(),
              IconButton(
                onPressed: () {
                  boxLogin.delete("user");
                  boxLogin.delete("pass");
                  boxLogin.delete("token");
                  // changePageTo(context,
                  //     LoginView(switchTheme: widget.switchTheme), true);
                  changePageTo(context, HomePage(), true);
                },
                icon: Icon(Icons.logout),
                tooltip: "Logout",
              ),
              IconButton(
                onPressed: () {
                  changePageTo(context, AllFiles(), false);
                },
                icon: Icon(Icons.folder),
                tooltip: "All Files",
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 20.0, top: 20),
            child: Text(
              'Seach.',
              style: kLoginTitleStyle(size),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              'For Movies/Series 🍿',
              style: kLoginSubtitleStyle(size),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.deepPurpleAccent,
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                changePageTo(context, SearchPage(), true);
              },
              child: Text(
                'Click here for Direct Search',
              ),
            ),
          ),
          SizedBox(
            height: size.height * 0.03,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// username or Gmail
                  TextFormField(
                    // style: kTextFormFieldStyle(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Enter Your Query',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                    ),
                    controller: nameController,
                    // The validator receives the text that the user has entered.
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter search';
                      } else if (value.length < 2) {
                        return 'at least enter 2 characters';
                      } else if (value.length > 26) {
                        return 'maximum character is 26';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          queryCards = <Container>[];
                          showProg = true;
                        });

                        loadSearch(value);
                      }
                    },
                    onFieldSubmitted: (value) {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          queryCards = <Container>[];
                          showProg = true;
                        });

                        loadSearch(value);
                      }
                    },
                  ),

                  SizedBox(
                    height: size.height * 0.02,
                  ),

                  SizedBox(
                    height: size.height * 0.02,
                  ),

                  /// searchButton Button
                  // searchButton(),

                  showProg
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : SizedBox(),

                  queryCards.isNotEmpty
                      ? SingleChildScrollView(
                          child: Wrap(
                            children: queryCards,
                          ),
                        )
                      : SizedBox(),

                  SizedBox(
                    height: size.height * 0.03,
                  ),

                  /// Navigate To Login Screen
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // searchButton Button
  Widget searchButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.deepPurpleAccent),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        onPressed: () {
          // Validate returns true if the form is valid, or false otherwise.
          if (_formKey.currentState!.validate()) {
            setState(() {
              showProg = true;
            });
            // ... Login To your Home Page
            loadSearch(nameController.value.text);
          }
        },
        child: Row(
          children: [
            showProg
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                : SizedBox(),
            const Text('Search'),
          ],
        ),
      ),
    );
  }
}
