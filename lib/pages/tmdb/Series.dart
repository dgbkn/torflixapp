import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:seedr_app/pages/VideoPlayer.dart';
import 'package:seedr_app/pages/tmdb/SeasonEpisodes.dart';
import 'package:seedr_app/utils.dart';

class Series extends StatefulWidget {
  final id;
  const Series({this.id});

  @override
  State<Series> createState() => _SeriesState();
}

class _SeriesState extends State<Series> {
  var serie = {};
  var imdb = "";
  var torrents = [];
  var seasons;

  Future<void> loadserie() async {
    var tmdb_search =
        "https://api.themoviedb.org/3/tv/${widget.id}?api_key=11df31d6a6ca0ba9a5a48329717c59bc&language=en-US&append_to_response=videos,casts,recommendations,images,external_ids&include_image_language=en,null";
    var response = await get(Uri.parse(tmdb_search));
    var data = jsonDecode(response.body);
    data["poster_path"] =
        "https://image.tmdb.org/t/p/w500${data["poster_path"] ?? "/nGf1tzFVu3FLVsraCExsAEOnaUL.jpg"}";

    seasons = data["seasons"];
    imdb = data["external_ids"]["imdb_id"] == null
        ? ""
        : data["external_ids"]["imdb_id"];
    setState(() {
      serie = data;
    });
  }

  @override
  void initState() {
    super.initState();
    loadserie();
  }

  Widget getSeasonCards(responsive){
    List<Widget> cards = [];
    for (var season in seasons) {
      cards.add(renderTorrent(season["name"], season["overview"], () {
        changePageTo(context, SeasonEpisodes(id:widget.id,season: season["season_number"],imdb: imdb,), false);
      }, season["poster_path"], "season"  ,responsive));
    }
    return Column(
      children: cards,
    );
  }

    Container renderTorrent(name, subtitle, onTap, image, category,responsive) {

    return Container(
        width: responsive,
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Image.network( "https://image.tmdb.org/t/p/w300" +
                        (image ??
                            "/nGf1tzFVu3FLVsraCExsAEOnaUL.jpg"), height: responsive * 0.45),
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
                          name,
                          style: TextStyle(fontWeight: FontWeight.w600),
                          softWrap: true,
                        ),
                      ),
                      Container(
                        width: responsive * 0.5,
                        child: Text(
                          subtitle,
                        ),
                      ),
                      Container(
                        width: responsive * 0.5,
                        child: Text(
                          "type:" + category,
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

  
  @override
  Widget build(BuildContext context) {
    double c_width = MediaQuery.of(context).size.width * 0.9;
    double responsive = c_width < 800
        ? c_width
        : c_width > 1200
            ? c_width * 0.8
            : c_width * 0.6;

    double responsive_ = c_width < 800
        ? c_width
        : c_width > 1200
            ? c_width * 0.3
            : c_width * 0.4;
    return Scaffold(
        appBar: AppBar(),
        body: serie['name'] == null
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
                                  serie["poster_path"],
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
                                            vertical: 15.0),
                                        child: Text(
                                          serie['name'] ?? "No title",
                                          style: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15.0),
                                        child: Text(
                                          serie['overview'] ?? "",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            serie["videos"]["results"] == null ||
                                    serie["videos"]["results"].length == 0
                                ? SizedBox()
                                : ElevatedButton(
                                    onPressed: () {
                                      changePageTo(
                                          context,
                                          VideoPlayer(
                                              name: serie["name"],
                                              img: serie["poster_path"],
                                              url:
                                                  "https://www.youtube.com/watch?v=" +
                                                      serie["videos"]["results"]
                                                          [0]["key"]),
                                          false);
                                    },
                                    child: Text("Watch Trailer")),
                            seasons == null || seasons.length == 0
                                ? SizedBox()
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: responsive,
                                        child: Column(
                                      children: [
                                        Text(
                                          "Seasons:",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        getSeasonCards(responsive_),
                                      ],
                                    )),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ));
  }
}
