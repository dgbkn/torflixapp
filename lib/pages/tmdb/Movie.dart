import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:seedr_app/pages/AddMagnet.dart';
import 'package:seedr_app/pages/VideoPlayer.dart';
import 'package:seedr_app/utils.dart';

class Movie extends StatefulWidget {
  final id;
  Movie({this.id});

  @override
  State<Movie> createState() => _MovieState();
}

class _MovieState extends State<Movie> {
  var movie = {};
  var imdb = '';
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
                  Text(torrent["behaviorHints"]["bingeGroup"] ?? ""),
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

  Future<void> loadMovie() async {
    var tmdb_search =
        "https://api.themoviedb.org/3/movie/${widget.id}?api_key=11df31d6a6ca0ba9a5a48329717c59bc&language=en-US&append_to_response=videos,casts,recommendations,images&include_image_language=en,null";
    var response = await get(Uri.parse(tmdb_search));
    var data = jsonDecode(response.body);
    data["poster_path"] =
        "https://image.tmdb.org/t/p/w500${data["poster_path"] ?? "/nGf1tzFVu3FLVsraCExsAEOnaUL.jpg"}";
    print(data["imdb_id"]);
    imdb = data["imdb_id"] == null ? "" : data["imdb_id"];
    setState(() {
      movie = data;
    });
    loadTorrents();
  }

  Future<void> loadTorrents() async {
    if (imdb == '') return;
    var torrentio =
        "https://torrentio.strem.fun/sort=seeders%7Clanguage=hindi/stream/movie/${imdb}.json";
    var response = await get(Uri.parse(torrentio));
    var data = jsonDecode(response.body);

    var streams = data["streams"] == null ? [] : data["streams"];
    setState(() {
      torrents = streams;
    });
  }

  initState() {
    super.initState();
    loadMovie();
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
        body: movie['title'] == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  movie["poster_path"],
                                  height: responsive * 0.4,
                                ),
                                SizedBox(
                                  width: responsive * 0.1,
                                ),
                                Container(
                                  width: responsive * 0.5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14.0),
                                        child: Text(
                                          movie['title'] ?? "No title",
                                          style: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15.0),
                                        child: Text(
                                          movie['overview'] ?? "",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            movie["videos"]["results"] == null ||
                                    movie["videos"]["results"].length == 0
                                ? SizedBox()
                                : ElevatedButton(
                                    onPressed: () {
                                      changePageTo(
                                          context,
                                          VideoPlayer(
                                              name: movie["title"],
                                              img: movie["poster_path"],
                                              url:
                                                  "https://www.youtube.com/watch?v=" +
                                                      movie["videos"]["results"]
                                                          [0]["key"]),
                                          false);
                                    },
                                    child: Text("Watch Trailer")),
                          ],
                        ),
                        torrents == null
                            ? Container(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : torrents.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18.0),
                                    child: Center(
                                      child: Text(
                                        "No TORRENTS FOUND",
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  )
                                : torrentCards(responsive),
                      ],
                    ),
                  ),
                ),
              ));
  }
}
