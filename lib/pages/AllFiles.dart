import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:seedr_app/utils.dart';
// import 'package:seedr_app/constants.dart'; // Assuming you have this
// import 'package:seedr_app/utils.dart'; // Assuming you have this
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to your pubspec.yaml

// Ensure you have this line where you initialize Hive, or a similar setup
var boxLogin = Hive.box("login_info");

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
    // More robust video format checking by checking a list of extensions
    const videoExtensions = [
      '.mkv',
      '.mp4',
      '.avi',
      '.mov',
      '.wmv',
      '.flv',
      '.webm'
    ];
    bool isVideo =
        videoExtensions.any((ext) => name.toLowerCase().endsWith(ext));

    return SeedrFile(
      name: name,
      folderFileId:
          int.tryParse(json["folder_file_id"]?.toString() ?? '0') ?? 0,
      isVideo: isVideo,
      size: int.tryParse(json["size"]?.toString() ?? '0') ?? 0,
    );
  }

  String get formattedSize {
    if (size <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB"];
    var i = (log(size) / log(1024)).floor();
    return '${(size / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
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
        // Important: Refresh the UI after getting the new token
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

// In class _AllFilesState

  void _handleCopyLinkAction(SeedrFile file, String qualityFunc) async {
    // For non-video files, qualityFunc will be 'fetch_file'
    final url = await _getStreamUrl(file.folderFileId, qualityFunc);
    if (url != null) {
      await Clipboard.setData(ClipboardData(text: url));
      Get.snackbar(
          "Link Copied", "The file link has been copied to your clipboard.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<List<SeedrFile>> _fetchFiles() async {
    if (await checkUserConnection() == false) {
      throw "No internet connection.";
    }

    final token = _boxLogin.get('token');
    final folderResponse = await http
        .get(Uri.parse("https://www.seedr.cc/api/folder?access_token=$token"));

    // If token is expired or invalid
    if (folderResponse.statusCode == 401) {
      await _refreshTokenAndRetry();
      return []; // Return empty list, the retry will trigger a new fetch
    }

    if (folderResponse.statusCode == 200) {
      final List<SeedrFile> allFiles = [];
      final folderData = jsonDecode(folderResponse.body);

      // Fetch files from each sub-folder
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
      // Sort files alphabetically for consistent display
      allFiles.sort((a, b) => a.name.compareTo(b.name));
      return allFiles;
    } else {
      throw "Failed to load files (Code: ${folderResponse.statusCode}). Please try again.";
    }
  }

  Future<String?> _getStreamUrl(int fileId, String qualityFunc) async {
    showLoading(context);
    try {
      final details = {
        "func":
            qualityFunc, // 'play_video' for SD, 'fetch_file' for HD/Download
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
      } else {
        throw "Failed to get link (Code: ${response.statusCode})";
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      Get.snackbar("Error", "Could not generate link: ${e.toString()}",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
    return null;
  }

// 1. REPLACE THIS FUNCTION
  Future<void> _launchInPlayer(String url, String title, String playerPackage,
      String componentName) async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'action_view',
        data: url,
        type: 'video/*',
        // By providing the package AND the explicit componentName, we prevent the app chooser.
        package: playerPackage,
        componentName: componentName,
        arguments: {'title': title},
        flags: [
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_GRANT_READ_URI_PERMISSION,
        ],
      );
      try {
        await intent.launch();
      } catch (e) {
        Get.snackbar("Player Not Found",
            "Could not launch $playerPackage. Please ensure it is installed.",
            backgroundColor: Colors.orangeAccent,
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

// 2. REPLACE THIS FUNCTION
  void _showPlayerSelection(String url, String title) {
    // We now store the package name and the specific activity (component) name.
    final Map<String, Map<String, String>> players = {
      'VLC': {
        'package': 'org.videolan.vlc',
        'activity': 'org.videolan.vlc.gui.video.VideoPlayerActivity',
      },
      'MX Player': {
        'package': 'com.mxtech.videoplayer.ad',
        'activity': 'com.mxtech.videoplayer.ad.ActivityScreen',
      },
      'MX Player Pro': {
        'package': 'com.mxtech.videoplayer.pro',
        'activity': 'com.mxtech.videoplayer.pro.ActivityScreen',
      },
      'nPlayer': {
        'package': 'com.qinxiandiqi.nplayer',
        'activity': 'com.synaptics.rc.player.PlayerActivity',
      }
    };

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("Open with...",
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              ...players.entries.map((entry) {
                final String playerName = entry.key;
                final String playerPackage = entry.value['package']!;
                final String playerActivity = entry.value['activity']!;

                return ListTile(
                  title: Text(playerName),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    // Pass all required details to the launch function.
                    _launchInPlayer(url, title, playerPackage, playerActivity);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> launchUrlinExternalBrowser(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      Get.snackbar("Error", "Could not launch URL. Please try again.");
    }
  }

  void _handleDownloadAction(SeedrFile file) async {
    // Always use 'fetch_file' for downloading to get the direct file link
    final url = await _getStreamUrl(file.folderFileId, 'fetch_file');
    if (url != null) {
      launchUrlinExternalBrowser(url);
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
              if (mounted) {
                setState(() {
                  _filesFuture = _fetchFiles();
                });
              }
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
          return RefreshIndicator(
            onRefresh: () async {
              if (mounted) {
                setState(() {
                  _filesFuture = _fetchFiles();
                });
              }
            },
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return _FileCard(
                  file: file,
                  onPlayRequest: (String qualityFunc) async {
                    final url =
                        await _getStreamUrl(file.folderFileId, qualityFunc);
                    if (url != null) {
                      _showPlayerSelection(url, file.name);
                    }
                  },
                  onDownloadRequest: () => _handleDownloadAction(file),
                  onCopyLinkRequest: (String qualityFunc) =>
                      _handleCopyLinkAction(file, qualityFunc),
                );
              },
            ),
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
              Container(
                  width: 48.0,
                  height: 48.0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(right: 16)),
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
  final Function(String qualityFunc) onPlayRequest;
  final VoidCallback onDownloadRequest;
  final Function(String qualityFunc) onCopyLinkRequest;

  const _FileCard({
    Key? key,
    required this.file,
    required this.onPlayRequest,
    required this.onDownloadRequest,
    required this.onCopyLinkRequest,
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
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'play_sd':
                onPlayRequest('play_video');
                break;
              case 'play_hd':
                onPlayRequest('fetch_file');
                break;
              case 'download':
                onDownloadRequest();
                break;
              case 'copy_sd':
                onCopyLinkRequest('play_video');
                break;
              case 'copy_hd':
                onCopyLinkRequest('fetch_file');
                break;
              case 'copy_link': // For non-video files
                onCopyLinkRequest('fetch_file');
                break;
            }
          },
          icon: const Icon(Icons.more_vert),
          itemBuilder: (BuildContext context) {
            if (file.isVideo) {
              // Menu for VIDEO files
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'play_sd',
                  child: ListTile(
                    leading: Icon(Icons.sd_card_outlined),
                    title: Text('Play SD'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'play_hd',
                  child: ListTile(
                    leading: Icon(Icons.hd_outlined),
                    title: Text('Play HD'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'copy_sd',
                  child: ListTile(
                    leading: Icon(Icons.link),
                    title: Text('Copy SD Link'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'copy_hd',
                  child: ListTile(
                    leading: Icon(Icons.link),
                    title: Text('Copy HD Link'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'download',
                  child: ListTile(
                    leading: Icon(Icons.download_for_offline_outlined),
                    title: Text('Download'),
                  ),
                ),
              ];
            } else {
              // Menu for NON-VIDEO files
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'download',
                  child: ListTile(
                    leading: Icon(Icons.download_for_offline_outlined),
                    title: Text('Download'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'copy_link',
                  child: ListTile(
                    leading: Icon(Icons.link),
                    title: Text('Copy Link'),
                  ),
                ),
              ];
            }
          },
        ),
        // A direct tap still triggers a download for non-video files for convenience
        onTap: file.isVideo ? null : onDownloadRequest,
      ),
    );
  }
}
