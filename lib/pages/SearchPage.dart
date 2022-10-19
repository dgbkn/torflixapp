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
import 'package:seedr_app/pages/LoginScreen.dart';
import 'package:seedr_app/utils.dart';

var boxLogin = Hive.box("login_info");

class SearchPage extends StatefulWidget {
  final switchTheme;
  const SearchPage({this.switchTheme});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  TextEditingController nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  TabController? _tabController;
  @override
  void initState() {
    _tabController = new TabController(length: 2, vsync: this);
    super.initState();
  }

  bool showProg = false;
  var torrentCards337x = <Container>[];
  var torrentCardsall = <Container>[];

  Container renderTorrent(name, subtitle, onTap) {
    return Container(
        child: GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                name,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                subtitle,
              )
            ],
          ),
        ),
      ),
    ));
  }

  Future loadSearch(qry) async {
    torrentCards337x = <Container>[];
    torrentCardsall = <Container>[];
    var connected = await checkUserConnection();

    if (connected) {
      var uri_1337x =
          "https://1337x.to/sort-search/${Uri.encodeComponent(qry)}/time/desc/1/";

      var xData1337 = await get(Uri.parse(
          "https://scrap.torrentdev.workers.dev/?url=${Uri.encodeComponent(uri_1337x)}&selector=tr"));

      var details = {
        "query": qry,
        "type": "search",
      };
      var one337 = jsonDecode(xData1337.body);

      one337 = one337["result"];

      try {
        final responseSandr = await post(
          Uri.parse('http://45.61.136.80:8080/search'),
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          encoding: Encoding.getByName('utf-8'),
          body: details,
        );

        var sandrs = jsonDecode(responseSandr.body);
        sandrs = sandrs["torrents"];

        sandrs.forEach((s) {
          var GB = s['size'].contains('GB') ? true : false;

          var size;

          // print(s["title"] + " "  + size.toString());

          try {
            size = s['size'].substring(0, s['size'].length - 2);
            size = double.parse(size);
          } catch (ex) {
            print(ex);
            size = 0;
          }

          if (!GB || (GB && size <= 4.0)) {
            torrentCardsall.add(renderTorrent(s["title"],
                'Seeds:' + s['seeds'] + ' | ' + s['source'] + ' | ' + s['size'],
                () {
              changePageTo(context, AddMagnet(magnet: s['magnet']), false);
            }));
          }
        });
      } catch (ex) {
        torrentCardsall.add(Container(
          child: Text("Server Error"),
        ));
      }

      one337.forEach((element) {
        var snip = element["text"].split("\n");
        var html = element["innerHTML"];

        var post = parse(html);

        var name = snip[1];
        var href = '';
        try {
          href = post.getElementsByTagName('a')[1].attributes['href'] ?? "";
        } catch (ex) {
          href = "";
        }
        var seeds = snip[2];
        var ssiss = snip[5].substring(0, snip[5].indexOf('B') + 1);
        var size;

        try {
          size = ssiss.substring(0, ssiss.length - 2);

          size = double.parse(size);
        } catch (ex) {
          size = 0;
        }

        var GB = ssiss.contains('GB') ? true : false;

        var uploader = snip[6];
        var datae = snip[4];

        if ((!GB || (GB && size <= 4.0)) && size != 0) {
          torrentCards337x.add(renderTorrent(name,
              "Seeds - $seeds | Size - $ssiss | Uploaded by - $uploader | $datae",
              () async {
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

            print(href);
            var data = await get(Uri.parse(
                "https://scrap.torrentdev.workers.dev/?url=https://1337x.to$href&selector=body"));
            var gotData = jsonDecode(data.body);
            var doc = parse(gotData["result"][0]["innerHTML"]);

            var magnet =
                doc.querySelector('.clearfix ul li a')?.attributes['href'] ??
                    "";

            Navigator.pop(context);

            changePageTo(context, AddMagnet(magnet: magnet), false);
          }));
        }
      });

      //  print(sandrs);

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
          widget.switchTheme != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    widget.switchTheme,
                    IconButton(
                      onPressed: () {
                        boxLogin.delete("user");
                        boxLogin.delete("pass");
                        boxLogin.delete("token");
                        changePageTo(context,
                            LoginView(switchTheme: widget.switchTheme), true);
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
                )
              : SizedBox(),
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
                      } else if (value.length < 4) {
                        return 'at least enter 4 characters';
                      } else if (value.length > 26) {
                        return 'maximum character is 26';
                      }
                      return null;
                    },
                  ),

                  SizedBox(
                    height: size.height * 0.02,
                  ),

                  SizedBox(
                    height: size.height * 0.02,
                  ),

                  /// searchButton Button
                  searchButton(),

                  torrentCards337x.isNotEmpty
                      ? Padding(
                          padding: EdgeInsets.all(8),
                          child: DefaultTabController(
                              length: 2,
                              child: Column(children: [
                                TabBar(
                                  labelColor: Colors.red,
                                  tabs: <Widget>[
                                    Tab(
                                      icon: Icon(Icons.tornado_rounded),
                                      text: "1337x",
                                    ),
                                    Tab(
                                      icon:
                                          Icon(Icons.self_improvement_rounded),
                                      text: "All Servers",
                                    )
                                  ],
                                  controller: _tabController,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                ),
                                SizedBox(
                                  height: 300,
                                  child: TabBarView(
                                    children: <Widget>[
                                      SingleChildScrollView(
                                        child: Column(
                                          children: torrentCards337x,
                                        ),
                                      ),
                                      SingleChildScrollView(
                                        child: Column(
                                          children: torrentCardsall,
                                        ),
                                      ),
                                    ],
                                    controller: _tabController,
                                  ),
                                ),
                              ])),
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
