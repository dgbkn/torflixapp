import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:seedr_app/pages/tmdb/EpisodeTorrents.dart';
import 'package:seedr_app/utils.dart';

class SeasonEpisodes extends StatefulWidget {
  final id;
  final season;
  final imdb;
  const SeasonEpisodes({this.id, this.season, this.imdb});

  @override
  State<SeasonEpisodes> createState() => _SeasonEpisodesState();
}

class _SeasonEpisodesState extends State<SeasonEpisodes> {
  var episodes;

  Future<void> loadEpisodes() async {
    var tmdb_search =
        "https://api.themoviedb.org/3/tv/${widget.id}/season/${widget.season}?api_key=11df31d6a6ca0ba9a5a48329717c59bc&language=en-US";
    var response = await get(Uri.parse(tmdb_search));
    var data = jsonDecode(response.body);
    print(data);
    setState(() {
      episodes = data["episodes"] ?? [];
    });
  }

  @override
  initState() {
    super.initState();
    loadEpisodes();
  }

  Container renderTorrent(name, subtitle, onTap, image, category, responsive) {
    return Container(
        width: responsive,
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical:8.0),
              child: Row(
                children: [
                  Image.network(
                      "https://image.tmdb.org/t/p/w300" +
                          (image ?? "/nGf1tzFVu3FLVsraCExsAEOnaUL.jpg"),
                      width: responsive * 0.45),
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
    double c_width = MediaQuery.of(context).size.width;

    double responsive = c_width < 800
        ? c_width
        : c_width > 1200
            ? c_width * 0.8
            : c_width * 0.9;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: Wrap(
              children: [
                episodes == null
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        child: CircularProgressIndicator(),
                      ))
                    : Column(
                        children: [
                          for (var episode in episodes)
                            renderTorrent(episode["name"], episode["overview"],
                                () {
                              changePageTo(
                                  context,
                                  EpisodeTorrents(
                                    season: widget.season,
                                    episode: episode["episode_number"],
                                    imdb: widget.imdb,
                                  ),
                                  false);
                            }, episode["still_path"], "episode", responsive),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
