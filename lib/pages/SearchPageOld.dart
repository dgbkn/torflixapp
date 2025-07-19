import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:seedr_app/pages/AddMagnet.dart';
import 'package:seedr_app/pages/AllFiles.dart';
import 'package:seedr_app/pages/LoginScreen.dart'; // For path joining

// --- Helper class for unified torrent data ---

class TorrentResult {
  final String title;
  final String source;
  final double sizeGB;
  final int seeders;
  final int leechers;
  final String? magnetUrl;
  final String? infoHash;
  final String? detailsUrl; // For sources that need a second lookup
  final String? resolution; // Optional, for sources that provide it

  TorrentResult(
      {required this.title,
      required this.source,
      required this.sizeGB,
      required this.seeders,
      required this.leechers,
      this.magnetUrl,
      this.infoHash,
      this.detailsUrl,
      this.resolution});

  // A computed property to get a usable magnet link
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

// --- Main Search Page Implementation ---

class SearchPage extends StatefulWidget {
  final Widget? switchTheme;
  const SearchPage({Key? key, this.switchTheme}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<TorrentResult> _torrents = [];
  bool _isLoading = false;
  String _message = "Search for movies, series, and more...";
  var boxLogin = Hive.box("login_info");

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    // This is a good place to check if the user is logged in
    // and redirect if necessary.
    final user = boxLogin.get("user");
    if (user == null || user.isEmpty) {
      // Use WidgetsBinding to ensure navigation happens after the build cycle
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
      _torrents.clear();
      _message = "Searching...";
    });

    try {
      final List<TorrentResult> combinedResults = [];

      // --- API Calls ---
      // Use Future.wait to run all searches in parallel for better performance
      await Future.wait([
        _searchKnaben(query, combinedResults),
        _searchApiBay(query, combinedResults),
        _searchTorrentio(query, combinedResults),
      ]);

      // Sort results by seeders (descending)
      combinedResults.sort((a, b) => b.seeders.compareTo(a.seeders));

      // Filter results by size
      _torrents
          .addAll(combinedResults.where((torrent) => torrent.sizeGB <= 5.0));

      setState(() {
        if (_torrents.isEmpty) {
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

  // --- Individual API Search Functions ---

  Future<void> _searchKnaben(String query, List<TorrentResult> results) async {
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
            ));
          }
        }
      }
    }
  }

  Future<void> _searchApiBay(String query, List<TorrentResult> results) async {
    final response =
        await http.get(Uri.parse('https://apibay.org/q.php?q=$query&cat=0'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      for (var hit in data) {
        // Apibay might return a "0" id for no results
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
            ));
          }
        }
      }
    }
  }

  Future<void> _searchTorrentio(
      String query, List<TorrentResult> results) async {
    String? imdbId;
    // First, get IMDb ID from Cinemeta
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
              rawName: stream['name'] ?? '', // Pass the 'name' field
              rawTitle: stream['title'] ?? '', // Pass the 'title' field
              infoHash: stream['infoHash'], // Pass the 'infoHash' field
            );

            results.add(TorrentResult(
              title: details['title'], // Use extracted title
              source:
                  'Torrentio | ' + details['source'], // Use extracted source
              sizeGB: details['sizeGB'], // Use extracted size
              seeders: details['seeders'], // Use extracted seeders
              leechers: 0, // Still not provided
              infoHash: stream['infoHash'], // Original infoHash from the stream
              magnetUrl: details['magnetUrl'], // Generated magnet URL
              detailsUrl: null, // Not in your data, set to null
              resolution: details['resolution'], // Extracted resolution
            ));
          }
        }
      }
    }
  }

  Map<String, dynamic> _parseTorrentioStreamDetails({
    required String rawName,
    required String rawTitle,
    String? infoHash, // Pass infoHash to potentially generate magnetUrl
  }) {
    String title = rawTitle;
    String? resolution;
    int seeders = 0;
    double sizeGB = 0.0;
    String source = 'Unknown';
    String? magnetUrl;

    // 1. Extract resolution from rawName (e.g., "Torrentio\n1080p")
    if (rawName.contains('\n')) {
      List<String> nameParts = rawName.split('\n');
      if (nameParts.length > 1) {
        resolution = nameParts[1].trim();
      }
    } else {
      // If resolution isn't in name, sometimes it's implied or part of the title
      // For now, if not in name, we assume it's part of the title that gets stripped.
      // You might need more complex logic here if resolution is inconsistent.
    }

    // 2. Extract seeders, size, and source from rawTitle using regex
    RegExp detailsRegex =
        RegExp(r'👤 (\d+)\s*💾 ([\d.]+ GB|[\d.]+ MB)\s*⚙️ (.+)');
    Match? detailsMatch = detailsRegex.firstMatch(rawTitle);

    if (detailsMatch != null) {
      // The actual movie title is the part of rawTitle *before* the 👤 icon
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

    // 3. Generate magnet URL if infoHash is available
    if (infoHash != null && infoHash.isNotEmpty) {
      String encodedTitle = Uri.encodeComponent(title);
      magnetUrl = 'magnet:?xt=urn:btih:$infoHash&dn=$encodedTitle';
      // Add trackers if you have a list of common ones:
      // magnetUrl += '&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce';
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
      // Handle cases like 1337x where a second call is needed
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
          title: const Text('Search'),
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
            _buildSearchBar(),
            Expanded(child: _buildResultsBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
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
          contentPadding: EdgeInsets.zero,
          fillColor: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: _search,
          ),
        ),
        onSubmitted: (_) => _search(),
      ),
    );
  }

  Widget _buildResultsBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_torrents.isEmpty) {
      return Center(
        child: Text(
          _message,
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: _torrents.length,
      itemBuilder: (context, index) {
        return _buildTorrentCard(_torrents[index]);
      },
    );
  }

  Widget _buildTorrentCard(TorrentResult torrent) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _addTorrent(torrent),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                torrent.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(Icons.storage_rounded, size: 16),
                    label: Text('${torrent.sizeGB.toStringAsFixed(2)} GB'),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                  Chip(
                    avatar: const Icon(Icons.public, size: 16),
                    label: Text(torrent.source),
                    backgroundColor: Colors.purple.withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatIcon(Icons.arrow_upward_rounded,
                      torrent.seeders.toString(), Colors.green),
                  const SizedBox(width: 16),
                  _buildStatIcon(Icons.arrow_downward_rounded,
                      torrent.leechers.toString(), Colors.red),
                  const Spacer(),
                  const Icon(Icons.add_circle_outline, color: Colors.blue),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
