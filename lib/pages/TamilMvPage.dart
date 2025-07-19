import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:seedr_app/pages/AddMagnet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// This code assumes `AddMagnet` is defined elsewhere in your project.
// import 'path/to/add_magnet_page.dart';

class TamilMvPage extends StatefulWidget {
  const TamilMvPage({Key? key}) : super(key: key);

  @override
  _TamilMvPageState createState() => _TamilMvPageState();
}

class _TamilMvPageState extends State<TamilMvPage> {
  late final WebViewController _controller;
  late Future<String> _domainFuture;
  String _currentDomain = '';
  double _progress = 0;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _domainFuture = _fetchDomain();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted)
              setState(() {
                _progress = progress / 100;
              });
          },
          onPageFinished: (String url) {
            if (mounted)
              setState(() {
                _progress = 1.0;
              });
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) {
              print('Page resource error: ${error.description}');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('magnet:')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddMagnet(magnet: request.url)),
              );
              return NavigationDecision.prevent;
            }

            final uri = Uri.parse(request.url);
            if (!uri.scheme.startsWith('http')) {
              _launchUrl(uri);
              return NavigationDecision.prevent;
            }

            // If the URL is for an external domain, open it in the strict SecureWebViewPage.
            if (_currentDomain.isNotEmpty &&
                !request.url.startsWith(_currentDomain)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SecureWebViewPage(
                    initialUrl: request.url,
                    allowedBaseDomain:
                        _currentDomain, // Pass the base domain for reference
                  ),
                ),
              );
              return NavigationDecision.prevent;
            }

            // Allow navigation if it's within the current domain.
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<String> _fetchDomain() async {
    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/dgbkn/torflixapp/refs/heads/main/public.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentDomain = data['tamilmv'] as String;
        if (!_currentDomain.endsWith('/')) {
          _currentDomain += '/';
        }
        return _currentDomain;
      } else {
        throw Exception('Failed to fetch domain config');
      }
    } catch (e) {
      throw Exception('Connection failed');
    }
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TamilMV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: () async {
              if (await _controller.canGoForward()) {
                _controller.goForward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _domainFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }
          if (snapshot.hasData) {
            if (_isInitialLoad) {
              _controller.loadRequest(Uri.parse(snapshot.data!));
              _isInitialLoad = false;
            }
            return SafeArea(
              child: Column(
                children: [
                  if (_progress < 1.0)
                    LinearProgressIndicator(value: _progress),
                  Expanded(
                    child: WebViewWidget(controller: _controller),
                  ),
                ],
              ),
            );
          }
          return _buildErrorWidget("An unknown error occurred.");
        },
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
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 60),
            const SizedBox(height: 20),
            Text(
              'Connection Error',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error.replaceAll("Exception: ", ""),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _domainFuture = _fetchDomain();
                  _isInitialLoad = true;
                });
              },
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }
}

/// A secure WebView page that loads one initial URL and then
/// strictly blocks any further navigation or redirection, unless
/// it's back to the main app's allowed domain.
class SecureWebViewPage extends StatefulWidget {
  final String initialUrl;
  final String allowedBaseDomain;

  const SecureWebViewPage({
    Key? key,
    required this.initialUrl,
    required this.allowedBaseDomain,
  }) : super(key: key);

  @override
  State<SecureWebViewPage> createState() => _SecureWebViewPageState();
}

class _SecureWebViewPageState extends State<SecureWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Rule 1: Allow the very first URL that the widget was told to load.
            if (request.url == widget.initialUrl) {
              return NavigationDecision.navigate;
            }

            // Rule 2: Allow navigation if it's going back to the main allowed domain.
            if (request.url.startsWith(widget.allowedBaseDomain)) {
              return NavigationDecision.navigate;
            }

            // Rule 3: Block everything else.
            if (kDebugMode) {
              print(
                  'Blocked subsequent redirection in SecureWebViewPage to: ${request.url}');
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Uri.parse(widget.initialUrl).host),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final uri = Uri.parse(widget.initialUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          )
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
