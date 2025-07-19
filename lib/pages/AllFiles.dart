import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:seedr_app/constants.dart';
import 'package:seedr_app/utils.dart';
import 'package:shimmer/shimmer.dart';

class SeedrFile {
  final String name;
  final int folderFileId;
  final bool isVideo;
  final int size;

  SeedrFile({
    required this.name,
    required this.folderFileId,
    required this.isVideo,
    required this.size,
  });

  factory SeedrFile.fromJson(Map<String, dynamic> json) {
    String name = json["name"] ?? "Untitled";
    bool isVideo = name.endsWith(".mkv") ||
        name.endsWith(".mp4") ||
        name.endsWith(".avi") ||
        name.endsWith(".mov") ||
        name.endsWith(".wmv");
    return SeedrFile(
      name: name,
      folderFileId: json["folder_file_id"],
      isVideo: isVideo,
      size: int.tryParse(json["size"]?.toString() ?? '0') ?? 0,
    );
  }

  String get formattedSize {
    if (size <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (size.abs() == 0) ? 0 : (size.abs().toString().length - 1) ~/ 3;
    return '${(size / (1 << (i * 10))).toStringAsFixed(2)} ${suffixes[i]}';
  }
}

class AllFiles extends StatefulWidget {
  const AllFiles({super.key});

  @override
  State<AllFiles> createState() => _AllFilesState();
}

class _AllFilesState extends State<AllFiles> {
  late Future<List<SeedrFile>> _filesFuture;
  final _boxLogin = Hive.box("login_info");

  @override
  void initState() {
    super.initState();
    _filesFuture = _fetchFiles();
  }

  Future<void> _refreshTokenAndRetry() async {
    try {
      final details = {
        "grant_type": "password",
        "client_id": "seedr_chrome",
        "type": "login",
        "username": _boxLogin.get("user"),
        "password": _boxLogin.get("pass")
      };

      final response = await http.post(
        Uri.parse('https://www.seedr.cc/oauth_test/token.php'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: details,
      );

      if (response.statusCode == 200) {
        final d = jsonDecode(response.body);
        await _boxLogin.put("token", d["access_token"]);
        setState(() {
          _filesFuture = _fetchFiles();
        });
      } else {
        throw "Login Expired. Please log in again.";
      }
    } catch (e) {
      Get.snackbar("Error", "Login Expired. Please log in again.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      _boxLogin.clear();
      SystemNavigator.pop();
    }
  }

  Future<List<SeedrFile>> _fetchFiles() async {
    if (await checkUserConnection() == false) {
      throw "No internet connection.";
    }

    final token = _boxLogin.get('token');
    final folderResponse = await http
        .get(Uri.parse("https://www.seedr.cc/api/folder?access_token=$token"));

    if (folderResponse.statusCode == 401) {
      await _refreshTokenAndRetry();
      return [];
    }

    if (folderResponse.statusCode == 200) {
      final List<SeedrFile> allFiles = [];
      final folderData = jsonDecode(folderResponse.body);

      for (final folder in folderData["folders"]) {
        final filesResponse = await http.get(Uri.parse(
            "https://www.seedr.cc/api/folder/${folder['id']}?access_token=$token"));
        if (filesResponse.statusCode == 200) {
          final filesData = jsonDecode(filesResponse.body);
          for (final fileJson in filesData["files"]) {
            allFiles.add(SeedrFile.fromJson(fileJson));
          }
        }
      }
      allFiles.sort((a, b) => a.name.compareTo(b.name));
      return allFiles;
    } else {
      throw "Failed to load files. Please try again.";
    }
  }

  Future<String?> _getStreamUrl(int fileId, String qualityFunc) async {
    showLoading(context);
    try {
      final details = {
        "func": qualityFunc, // 'play_video' for SD, 'fetch_file' for HD
        "folder_file_id": fileId.toString(),
        "access_token": _boxLogin.get("token")
      };

      final response = await http.post(
        Uri.parse('https://www.seedr.cc/oauth_test/resource.php'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: details,
      );

      Navigator.pop(context); // Dismiss loading dialog

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return qualityFunc == 'play_video' ? data["url_hls"] : data["url"];
      }
    } catch (e) {
      Navigator.pop(context);
      Get.snackbar("Error", "Could not generate stream link.",
          backgroundColor: Colors.redAccent);
    }
    return null;
  }

  Future<void> _launchInPlayer(
      String url, String title, String playerPackage) async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull(url),
        type: 'video/*',
        package: playerPackage,
        arguments: {'title': title},
        flags: [
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_GRANT_READ_URI_PERMISSION
        ],
      );
      try {
        await intent.launch();
      } catch (e) {
        Get.snackbar(
          "Error",
          "Could not launch player. Is it installed?",
          backgroundColor: Colors.orangeAccent,
        );
      }
    }
  }

  void _showPlayerSelection(String url, String title) {
    final players = {
      'VLC': 'org.videolan.vlc',
      'MX Player': 'com.mxtech.videoplayer.ad',
      'nPlayer': 'com.qinxiandiqi.nplayer',
      'MX Player Pro': 'com.mxtech.videoplayer.pro',
    };

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Open with...",
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ...players.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                onTap: () {
                  Navigator.pop(context);
                  _launchInPlayer(url, title, entry.value);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _handlePlayAction(SeedrFile file) async {
    String? selectedQuality = await Get.dialog<String>(
      AlertDialog(
        title: const Text("Select Quality"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Standard Definition (SD)"),
              subtitle: const Text("Faster start, lower data usage"),
              onTap: () => Navigator.pop(context, 'play_video'),
            ),
            ListTile(
              title: const Text("High Definition (HD)"),
              subtitle: const Text("Best quality, higher data usage"),
              onTap: () => Navigator.pop(context, 'fetch_file'),
            ),
          ],
        ),
      ),
    );

    if (selectedQuality != null) {
      final url = await _getStreamUrl(file.folderFileId, selectedQuality);
      if (url != null) {
        _showPlayerSelection(url, file.name);
      }
    }
  }

  void _handleDownloadAction(SeedrFile file) async {
    final url = await _getStreamUrl(file.folderFileId, 'fetch_file');
    if (url != null) {
      launchUrlinChrome(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Files"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: () {
              setState(() {
                _filesFuture = _fetchFiles();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<SeedrFile>>(
        future: _filesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          }
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final files = snapshot.data!;
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return _FileCard(
                file: files[index],
                onPlay: () => _handlePlayAction(files[index]),
                onDownload: () => _handleDownloadAction(files[index]),
                onOpenWith: (quality) async {
                  final url =
                      await _getStreamUrl(files[index].folderFileId, quality);
                  if (url != null) {
                    _showPlayerSelection(url, files[index].name);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 48.0, height: 48.0, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: double.infinity,
                        height: 16.0,
                        color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 100.0, height: 12.0, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text("An Error Occurred",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              onPressed: () {
                setState(() {
                  _filesFuture = _fetchFiles();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text("No files found",
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text("Add some torrents to get started!",
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final SeedrFile file;
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final Function(String quality) onOpenWith;

  const _FileCard({
    Key? key,
    required this.file,
    required this.onPlay,
    required this.onDownload,
    required this.onOpenWith,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(
          file.isVideo
              ? Icons.movie_creation_rounded
              : Icons.description_rounded,
          color: iconColor,
          size: 40,
        ),
        title: Text(
          file.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "Size: ${file.formattedSize}",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        trailing: file.isVideo
            ? IconButton(
                icon: const Icon(Icons.play_circle_outline_rounded),
                onPressed: onPlay,
                tooltip: "Play",
                color: iconColor,
                iconSize: 28,
              )
            : IconButton(
                icon: const Icon(Icons.download_for_offline_outlined),
                onPressed: onDownload,
                tooltip: "Download",
                color: iconColor,
                iconSize: 28,
              ),
        onTap: file.isVideo ? onPlay : onDownload,
      ),
    );
  }
}
