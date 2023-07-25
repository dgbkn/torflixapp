import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:seedr_app/pages/AddMagnet.dart';
import 'package:seedr_app/utils.dart';

class EpisodeTorrents extends StatefulWidget {
  final imdb, season, episode;

  const EpisodeTorrents({this.imdb, this.season, this.episode});

  @override
  State<EpisodeTorrents> createState() => _EpisodeTorrentsState();
}

class _EpisodeTorrentsState extends State<EpisodeTorrents> {
  // https://torrentio.strem.fun/sort=seeders/stream/movie/tt13157618:1:3.json

  var torrents;

  Widget torrentCards(reswidth) {
    List<Container> cards = [];
    for (var torrent in torrents) {
      cards.add(Container(
        width: reswidth,
        child: GestureDetector(
          onTap: () {
            print(toMagnetURI(torrent["infoHash"]));
            changePageTo(context,
                AddMagnet(magnet: toMagnetURI(torrent["infoHash"])), false);
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    torrent["title"],
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(torrent["behaviorHints"]["bingeGroup"]),
                ],
              ),
            ),
          ),
        ),
      ));
    }

    return Column(
      children: cards,
    );
  }

  Future<void> loadTorrents() async {
    if (widget.imdb == '') return;
    var torrentio =
        "https://torrentio.strem.fun/sort=seeders%7Clanguage=hindi/stream/movie/${widget.imdb}:${widget.season}:${widget.episode}.json";
    var response = await get(Uri.parse(torrentio));
    var data = jsonDecode(response.body);

    print([torrentio]);
    var streams = data["streams"] == null ? [] : data["streams"];
    setState(() {
      torrents = streams;
    });
  }

  initState() {
    super.initState();
    loadTorrents();
  }

  @override
  Widget build(BuildContext context) {
    double c_width = MediaQuery.of(context).size.width * 0.9;
    double responsive = c_width < 800
        ? c_width
        : c_width > 1200
            ? c_width * 0.8
            : c_width * 0.6;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Wrap(alignment: WrapAlignment.center, children: [
            torrents == null
                ? Container(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : torrents.isEmpty ? Padding(
                  padding: const EdgeInsets.symmetric(vertical:18.0),
                  child: Center(child: Text("No TORRENTS FOUND",style: TextStyle(fontSize: 20),),),
                ) : torrentCards(responsive),
          ]),
        ),
      ),
    );
  }
}
