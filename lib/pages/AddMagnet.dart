import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart';
import 'package:seedr_app/constants.dart';
import 'package:seedr_app/pages/AllFiles.dart';
import 'package:seedr_app/utils.dart'; // Assuming your utility functions are here

// Ensure you have this line where you initialize Hive
var boxLogin = Hive.box("login_info");

// Enum to manage the state of each step
enum StepStatus { pending, inProgress, success, error }

// A model for a single step in the process
class ProcessStep {
  String title;
  StepStatus status;

  ProcessStep({required this.title, this.status = StepStatus.pending});
}

class AddMagnet extends StatefulWidget {
  final String magnet;
  const AddMagnet({super.key, required this.magnet});

  @override
  State<AddMagnet> createState() => _AddMagnetState();
}

class _AddMagnetState extends State<AddMagnet> {
  // UI State Management
  String _statusMessage = "Initializing...";
  String _errorMessage = "";
  double _downloadProgress = 0.0;
  String _torrentTitle = "Fetching title...";
  bool _isProcessActive = true;

  // List to hold all the steps for the UI
  final List<ProcessStep> _steps = [
    ProcessStep(title: "Connecting & Authenticating"),
    ProcessStep(title: "Clearing Previous Files"),
    ProcessStep(title: "Adding Magnet to Seedr"),
    ProcessStep(title: "Downloading in Cloud"),
  ];

  // Timeout for the polling mechanism to prevent infinite loops
  static const int _pollingTimeoutSeconds = 30;

  @override
  void initState() {
    super.initState();
    // Automatically start the Seedr process when the widget is initialized
    _startSeedrProcess();
  }

  // Updates the UI for a specific step
  void _updateStep(int index, StepStatus status, {String? message}) {
    if (!mounted) return;
    setState(() {
      _steps[index].status = status;
      if (message != null) {
        _statusMessage = message;
      }
      // If any step fails, stop the whole process
      if (status == StepStatus.error) {
        _isProcessActive = false;
        _errorMessage = message ?? "An unknown error occurred.";
      }
    });
  }

  // Main function to orchestrate the entire download process
  Future<void> _startSeedrProcess() async {
    try {
      // Step 0: Authentication
      _updateStep(0, StepStatus.inProgress, message: "Authenticating...");
      var folderContent = await _getFolderContentWithLoginRetry();
      _updateStep(0, StepStatus.success, message: "Authentication Successful!");

      // Step 1: Clear previous files
      _updateStep(1, StepStatus.inProgress,
          message: "Clearing existing files...");
      for (final t in folderContent["torrents"]) {
        await deleteSingle(t["id"], "torrent");
      }
      for (final f in folderContent["folders"]) {
        await deleteSingle(f["id"], "folder");
      }
      _updateStep(1, StepStatus.success, message: "Previous files cleared.");

      // Step 2: Add the new magnet link
      _updateStep(2, StepStatus.inProgress,
          message: "Sending magnet link to Seedr...");
      final response = await post(
        Uri.parse('https://www.seedr.cc/oauth_test/resource.php'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "func": "add_torrent",
          "torrent_magnet": widget.magnet,
          "access_token": boxLogin.get("token")
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Server error while adding magnet.");
      }

      var addResult = jsonDecode(response.body);
      if (addResult["result"] != true) {
        String error =
            addResult["result"]?.toString() ?? "Failed to add torrent.";
        if (error == "not_enough_space_wishlist_full") {
          error = "Not enough space in your Seedr account.";
        }
        throw Exception(error);
      }

      final int userTorrentId = addResult["user_torrent_id"];
      setState(() {
        _torrentTitle = addResult["title"] ?? "Untitled Torrent";
      });
      _updateStep(2, StepStatus.success, message: "Magnet added successfully!");

      // Step 3: Start the intelligent polling for completion
      _updateStep(3, StepStatus.inProgress,
          message: "Locating torrent on server...");
      await _pollForCompletion(userTorrentId, DateTime.now());
    } catch (e) {
      // Find the first step that isn't completed and mark it as an error
      int errorIndex = _steps.indexWhere((s) => s.status != StepStatus.success);
      if (errorIndex != -1) {
        _updateStep(errorIndex, StepStatus.error,
            message: e.toString().replaceAll("Exception: ", ""));
        _handleFatalError(e.toString().replaceAll("Exception: ", ""));
      }
    }
  }

// In class _AddMagnetState

// REPLACED: This now uses a loop instead of recursion to be safer and clearer.
  Future<void> _beginPollingLoop(int userTorrentId) async {
    final startTime = DateTime.now();

    while (mounted && _isProcessActive) {
      // 1. Check for timeout at the beginning of each loop iteration.
      // This will now be caught by the main try...catch block.
      if (DateTime.now().difference(startTime).inSeconds >
          _pollingTimeoutSeconds) {
        _handleFatalError(
            "Process timed out. The torrent could not be found or started.");
      }

      var folderContent = await _getFolderContentWithLoginRetry();

      // 2. Check if the torrent is actively downloading.
      var downloadingTorrent = folderContent["torrents"].firstWhere(
          (t) => t["user_torrent_id"] == userTorrentId,
          orElse: () => null);

      if (downloadingTorrent != null) {
        _loadProgress(downloadingTorrent["progress_url"]);
        return; // Exit the loop, progress tracker will take over.
      }

      // 3. Check if the torrent has already finished (a folder was created).
      var completedFolder = folderContent["folders"]
          .firstWhere((f) => f["name"] == _torrentTitle, orElse: () => null);

      if (completedFolder != null) {
        setState(() {
          _downloadProgress = 1.0;
        });
        _updateStep(3, StepStatus.success, message: "Download Complete!");
        Timer(const Duration(seconds: 2), () {
          if (mounted) changePageTo(context, AllFiles(), true);
        });
        return; // Exit the loop, success!
      }

      // 4. If not found, wait before the next iteration of the loop.
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  // Intelligent poller to handle both fast and slow downloads.
  Future<void> _pollForCompletion(int userTorrentId, DateTime startTime) async {
    if (!mounted || !_isProcessActive) return;

    if (DateTime.now().difference(startTime).inSeconds >
        _pollingTimeoutSeconds) {
      throw Exception(
          "Process timed out. The torrent could not be found or started.");
    }

    var folderContent = await _getFolderContentWithLoginRetry();

    // Check 1: Is the torrent actively downloading?
    var downloadingTorrent = folderContent["torrents"].firstWhere(
        (t) => t["user_torrent_id"] == userTorrentId,
        orElse: () => null);

    if (downloadingTorrent != null) {
      _loadProgress(downloadingTorrent["progress_url"]);
      return; // Progress tracker takes over from here.
    }

    // Check 2: Is the torrent already finished (i.e., a folder exists)?
    var completedFolder = folderContent["folders"]
        .firstWhere((f) => f["name"] == _torrentTitle, orElse: () => null);

    if (completedFolder != null) {
      setState(() {
        _downloadProgress = 1.0;
      });
      _updateStep(3, StepStatus.success, message: "Download Complete!");
      Timer(const Duration(seconds: 2), () {
        if (mounted) changePageTo(context, AllFiles(), true);
      });
      return; // Success!
    }

    // If not found, wait and poll again.
    await Future.delayed(const Duration(seconds: 1));
    // _pollForCompletion(userTorrentId, startTime);
    _beginPollingLoop(userTorrentId);
  }

  void _handleFatalError(String errorMessage) {
    if (!mounted) return;
    // First, update the UI to show the error
    _updateStep(3, StepStatus.error, message: errorMessage);
    // Then, show a snackbar for immediate feedback
    Get.snackbar("Process Failed", errorMessage,
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    // Finally, pop the current page after a short delay to let the user see the message
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // Tracks progress once a download has been confirmed to be active.
  void _loadProgress(String progUrl) async {
    if (!mounted || !_isProcessActive) return;

    var response = await get(Uri.parse(progUrl));
    if (response.statusCode != 200) {
      _handleFatalError("Lost connection to progress stream.");
      return;
    }

    var progData = response.body.substring(2, response.body.length - 1);
    Map finalProg = jsonDecode(progData);

    print(finalProg);

    // **MODIFIED:** This block now instantly triggers the fatal error handler.
    if ((finalProg.containsKey("warnings") && finalProg["warnings"] != '[]') ||
        (finalProg.containsKey("download_rate") &&
            finalProg["download_rate"] == 0)) {
      _handleFatalError(
          "Torrent is stalled or invalid. Please try another one.");
      return;
    }

    var prog = finalProg.containsKey("progress") ? finalProg["progress"] : 0;
    double progressValue = (double.tryParse(prog.toString()) ?? 0) / 100.0;

    setState(() {
      _downloadProgress = progressValue;
      _statusMessage = "Downloading in cloud: ${(progressValue * 100).ceil()}%";
    });

    if (progressValue >= 1) {
      _updateStep(3, StepStatus.success, message: "Download Complete!");
      Timer(const Duration(seconds: 2), () {
        if (mounted) changePageTo(context, AllFiles(), true);
      });
    } else {
      Timer(const Duration(seconds: 1), () => _loadProgress(progUrl));
    }
  }

  // Gets folder content and handles re-login if token is expired.
  Future<Map<String, dynamic>> _getFolderContentWithLoginRetry() async {
    var response = await get(Uri.parse(
        "https://www.seedr.cc/api/folder?access_token=${boxLogin.get('token')}"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Unauthorized
      await _loginAndRetry();
      response = await get(Uri.parse(
          "https://www.seedr.cc/api/folder?access_token=${boxLogin.get('token')}"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Authentication failed. Please restart the app and log in again.");
      }
    } else {
      throw Exception(
          "Could not connect to Seedr. Status code: ${response.statusCode}");
    }
  }

  // Refreshes the access token using stored username and password.
  Future<void> _loginAndRetry() async {
    final response = await post(
      Uri.parse('https://www.seedr.cc/oauth_test/token.php'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "grant_type": "password",
        "client_id": "seedr_chrome",
        "type": "login",
        "username": boxLogin.get("user"),
        "password": boxLogin.get("pass")
      },
    );

    if (response.statusCode == 200) {
      var d = jsonDecode(response.body);
      boxLogin.put("token", d["access_token"]);
      Get.snackbar("Session Refreshed",
          "Your login session was automatically refreshed.",
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      boxLogin.deleteAll(['user', 'pass', 'token']);
      if (mounted) {
        Get.snackbar("Login Expired", "Please log in again.",
            backgroundColor: Colors.red, colorText: Colors.white);
        _handleFatalError("Login expired. Please log in again.");
      }
      throw Exception("Login expired.");
    }
  }

  // Deletes a single item (folder or torrent) from Seedr.
  Future<void> deleteSingle(id, type) async {
    await post(
      Uri.parse('https://www.seedr.cc/oauth_test/resource.php'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "func": "delete",
        "delete_arr": jsonEncode([
          {"type": type, "id": id.toString()}
        ]),
        "access_token": boxLogin.get("token")
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adding Magnet"),
        automaticallyImplyLeading:
            !_isProcessActive, // Show back button only when process is done/failed
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _torrentTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              widget.magnet,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),

            // The list of process steps
            ..._steps.map((step) => ProcessStepTile(step: step)).toList(),

            const Spacer(),

            // Progress bar and status message at the bottom
            if (_isProcessActive && _steps[3].status == StepStatus.inProgress)
              LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                borderRadius: BorderRadius.circular(5),
              ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _errorMessage.isNotEmpty
                    ? "Error: $_errorMessage"
                    : _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _errorMessage.isNotEmpty
                      ? Colors.redAccent
                      : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// A dedicated widget to display a single step with icon and color feedback.
class ProcessStepTile extends StatelessWidget {
  final ProcessStep step;
  const ProcessStepTile({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            _getIconForStatus(step.status),
            color: _getColorForStatus(step.status),
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: 18,
                color: step.status == StepStatus.pending
                    ? Colors.grey
                    : Colors.black,
                fontWeight: step.status == StepStatus.inProgress
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForStatus(StepStatus status) {
    switch (status) {
      case StepStatus.pending:
        return Icons.hourglass_empty_rounded;
      case StepStatus.inProgress:
        return Icons.sync_rounded;
      case StepStatus.success:
        return Icons.check_circle_rounded;
      case StepStatus.error:
        return Icons.error_rounded;
    }
  }

  Color _getColorForStatus(StepStatus status) {
    switch (status) {
      case StepStatus.pending:
        return Colors.grey;
      case StepStatus.inProgress:
        return Colors.blue;
      case StepStatus.success:
        return Colors.green;
      case StepStatus.error:
        return Colors.redAccent;
    }
  }
}
