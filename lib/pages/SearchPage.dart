import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:seedr_app/pages/AddMagnet.dart';
import 'package:seedr_app/pages/AllFiles.dart';
import 'package:seedr_app/pages/LoginScreen.dart';

class TorrentResult {
  final String title;
  final String source;
  final double sizeGB;
  final int seeders;
  final int leechers;
  final String? magnetUrl;
  final String? infoHash;
  final String? detailsUrl;
  final String? resolution;
  final DateTime? publishedDate;

  TorrentResult({
    required this.title,
    required this.source,
    required this.sizeGB,
    required this.seeders,
    required this.leechers,
    this.magnetUrl,
    this.infoHash,
    this.detailsUrl,
    this.resolution,
    this.publishedDate,
  });

  String get magnet {
    if (magnetUrl != null && magnetUrl!.startsWith("magnet:")) {
      return magnetUrl!;
    }
    if (infoHash != null) {
      return 'magnet:?xt=urn:btih:$infoHash&dn=${Uri.encodeComponent(title)}';
    }
    return "";
  }
}

class SearchPage extends StatefulWidget {
  final Widget? switchTheme;
  const SearchPage({Key? key, this.switchTheme}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

enum SortOption { seeders, size, date }

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<TorrentResult> _allResults = [];
  Map<String, List<TorrentResult>> _groupedTorrents = {};
  bool _isLoading = false;
  String _message = "Search for movies, series, and more...";
  SortOption _currentSort = SortOption.seeders;
  var boxLogin = Hive.box("login_info");

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    final user = boxLogin.get("user");
    if (user == null || user.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) =>
                LoginScreen(switchTheme: widget.switchTheme)));
      });
    }
  }

  Future<void> _handleLogout() async {
    await boxLogin.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) => LoginScreen(switchTheme: widget.switchTheme)),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _allResults.clear();
      _groupedTorrents.clear();
      _message = "Searching across sources...";
    });

    try {
      final List<TorrentResult> combinedResults = [];
      await Future.wait([
        _searchKnaben(query, combinedResults),
        _searchApiBay(query, combinedResults),
        _searchTorrentio(query, combinedResults),
      ]);

      _allResults =
          combinedResults.where((torrent) => torrent.sizeGB <= 5.0).toList();
      _processAndSortResults();

      setState(() {
        if (_allResults.isEmpty) {
          _message = "No results found for '$query'.";
        }
      });
    } catch (e) {
      setState(() {
        _message = "An error occurred. Please try again.";
      });
      Get.snackbar("Error", "Failed to fetch torrents: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processAndSortResults() {
    Map<String, List<TorrentResult>> grouped = {};
    for (var torrent in _allResults) {
      String sourceName = torrent.source.split(' | ')[0];
      if (grouped.containsKey(sourceName)) {
        grouped[sourceName]!.add(torrent);
      } else {
        grouped[sourceName] = [torrent];
      }
    }

    grouped.forEach((source, torrents) {
      torrents.sort((a, b) {
        switch (_currentSort) {
          case SortOption.size:
            return b.sizeGB.compareTo(a.sizeGB);
          case SortOption.date:
            if (a.publishedDate == null && b.publishedDate == null) return 0;
            if (a.publishedDate == null) return 1;
            if (b.publishedDate == null) return -1;
            return b.publishedDate!.compareTo(a.publishedDate!);
          case SortOption.seeders:
          default:
            return b.seeders.compareTo(a.seeders);
        }
      });
    });
    setState(() {
      _groupedTorrents = grouped;
    });
  }

  Future<void> _searchKnaben(String query, List<TorrentResult> results) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.knaben.org/v1'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"search_field": "title", "query": query}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['hits'] != null) {
          for (var hit in data['hits']) {
            double sizeGB = (hit['bytes'] ?? 0) / (1024 * 1024 * 1024);
            if (sizeGB > 0) {
              results.add(TorrentResult(
                title: hit['title'] ?? 'No Title',
                source: hit['tracker'] ?? 'Knaben',
                sizeGB: sizeGB,
                seeders: hit['seeders'] ?? 0,
                leechers: hit['peers'] ?? 0,
                magnetUrl: hit['magnetUrl'],
                detailsUrl: hit['details'],
                publishedDate: hit['time'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(hit['time'] * 1000)
                    : null,
              ));
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _searchApiBay(String query, List<TorrentResult> results) async {
    try {
      final response =
          await http.get(Uri.parse('https://apibay.org/q.php?q=$query&cat=0'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        for (var hit in data) {
          if (hit['id'] != '0') {
            double sizeGB =
                double.tryParse(hit['size'].toString())! / (1024 * 1024 * 1024);
            if (sizeGB > 0) {
              results.add(TorrentResult(
                title: hit['name'] ?? 'No Title',
                source: 'The Pirate Bay',
                sizeGB: sizeGB,
                seeders: int.tryParse(hit['seeders'].toString()) ?? 0,
                leechers: int.tryParse(hit['leechers'].toString()) ?? 0,
                infoHash: hit['info_hash'],
                publishedDate: hit['added'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        int.parse(hit['added']) * 1000)
                    : null,
              ));
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _searchTorrentio(
      String query, List<TorrentResult> results) async {
    try {
      String? imdbId;
      final cinemetaRes = await http.get(Uri.parse(
          'https://v3-cinemeta.strem.io/catalog/movie/top/search=$query.json'));
      if (cinemetaRes.statusCode == 200) {
        final cinemetaData = json.decode(cinemetaRes.body);
        if (cinemetaData['metas'] != null && cinemetaData['metas'].isNotEmpty) {
          imdbId = cinemetaData['metas'][0]['imdb_id'];
        }
      }
      if (imdbId != null) {
        final torrentioRes = await http.get(Uri.parse(
            'https://torrentio.strem.fun/sort=seeders/stream/movie/$imdbId.json'));
        if (torrentioRes.statusCode == 200) {
          final data = json.decode(torrentioRes.body);
          if (data['streams'] != null) {
            for (var stream in data['streams']) {
              Map<String, dynamic> details = _parseTorrentioStreamDetails(
                rawName: stream['name'] ?? '',
                rawTitle: stream['title'] ?? '',
                infoHash: stream['infoHash'],
              );
              results.add(TorrentResult(
                title: details['title'],
                source: 'Torrentio | ' + details['source'],
                sizeGB: details['sizeGB'],
                seeders: details['seeders'],
                leechers: 0,
                infoHash: stream['infoHash'],
                magnetUrl: details['magnetUrl'],
                resolution: details['resolution'],
                publishedDate: null,
              ));
            }
          }
        }
      }
    } catch (_) {}
  }

  Map<String, dynamic> _parseTorrentioStreamDetails({
    required String rawName,
    required String rawTitle,
    String? infoHash,
  }) {
    String title = rawTitle;
    String? resolution;
    int seeders = 0;
    double sizeGB = 0.0;
    String source = 'Unknown';
    String? magnetUrl;

    if (rawName.contains('\n')) {
      List<String> nameParts = rawName.split('\n');
      if (nameParts.length > 1) {
        resolution = nameParts[1].trim();
      }
    }
    RegExp detailsRegex =
        RegExp(r'👤 (\d+)\s*💾 ([\d.]+ GB|[\d.]+ MB)\s*⚙️ (.+)');
    Match? detailsMatch = detailsRegex.firstMatch(rawTitle);

    if (detailsMatch != null) {
      title = rawTitle.substring(0, detailsMatch.start).trim();
      seeders = int.tryParse(detailsMatch.group(1) ?? '0') ?? 0;
      String rawSize = detailsMatch.group(2) ?? '0 GB';
      source = detailsMatch.group(3)?.trim() ?? 'Unknown';

      if (rawSize.endsWith('GB')) {
        sizeGB = double.tryParse(rawSize.replaceAll(' GB', '')) ?? 0.0;
      } else if (rawSize.endsWith('MB')) {
        sizeGB =
            (double.tryParse(rawSize.replaceAll(' MB', '')) ?? 0.0) / 1024.0;
      }
    }

    if (infoHash != null && infoHash.isNotEmpty) {
      String encodedTitle = Uri.encodeComponent(title);
      magnetUrl = 'magnet:?xt=urn:btih:$infoHash&dn=$encodedTitle';
    }

    return {
      'title': title,
      'resolution': resolution,
      'seeders': seeders,
      'sizeGB': sizeGB,
      'source': source,
      'magnetUrl': magnetUrl,
    };
  }

  Future<void> _addTorrent(TorrentResult torrent) async {
    String magnet = torrent.magnet;
    if (magnet.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddMagnet(magnet: magnet)),
      );
    } else {
      Get.snackbar("Info", "Magnet link not found directly.",
          backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search Torrents'),
          actions: [
            IconButton(
              icon: const Icon(Icons.folder_copy_outlined),
              tooltip: "My Files",
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AllFiles()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBarAndFilter(),
            Expanded(child: _buildResultsBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search for anything...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              fillColor:
                  Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _search,
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSortChip(SortOption.seeders, "Seeders", Icons.people),
              _buildSortChip(SortOption.size, "Size", Icons.storage_rounded),
              _buildSortChip(SortOption.date, "Date", Icons.calendar_today),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSortChip(SortOption option, String label, IconData icon) {
    bool isSelected = _currentSort == option;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon,
          size: 16,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentSort = option;
          });
          _processAndSortResults();
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface),
    );
  }

  Widget _buildResultsBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_groupedTorrents.isEmpty) {
      return Center(
        child: Text(
          _message,
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    var sources = _groupedTorrents.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        String source = sources[index];
        List<TorrentResult> torrents = _groupedTorrents[source]!;

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            title: Text(source,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${torrents.length} results found"),
            initiallyExpanded: true,
            children:
                torrents.map((torrent) => _buildTorrentTile(torrent)).toList(),
            childrenPadding: const EdgeInsets.only(bottom: 8),
          ),
        );
      },
    );
  }

  Widget _buildTorrentTile(TorrentResult torrent) {
    return InkWell(
      onTap: () => _addTorrent(torrent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              torrent.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatChip(Icons.storage_rounded,
                    '${torrent.sizeGB.toStringAsFixed(2)} GB', Colors.blue),
                if (torrent.publishedDate != null)
                  _buildStatChip(
                      Icons.calendar_today,
                      DateFormat.yMMMd().format(torrent.publishedDate!),
                      Colors.purple),
                if (torrent.resolution != null)
                  _buildStatChip(Icons.hd, torrent.resolution!, Colors.orange),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _buildStatIcon(Icons.arrow_upward_rounded,
                    torrent.seeders.toString(), Colors.green.shade600),
                const SizedBox(width: 20),
                _buildStatIcon(Icons.arrow_downward_rounded,
                    torrent.leechers.toString(), Colors.red.shade600),
                const Spacer(),
                const Icon(Icons.add_circle_outline, color: Colors.blue),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
