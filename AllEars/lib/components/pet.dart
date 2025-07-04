import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:path_provider/path_provider.dart';

class PetGameView extends StatefulWidget {
  const PetGameView({super.key});

  @override
  State<PetGameView> createState() => _PetGameViewState();
}

class _PetGameViewState extends State<PetGameView> {
  late final WebViewController _controller;
  int score = 0;

  @override
  void initState() {
    super.initState();
    initWebView();
    loadOrCreateScore();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _scoreFile async {
    final path = await _localPath;
    return File('$path/score.json');
  }

  Future<void> loadOrCreateScore() async {
    try {
      final file = await _scoreFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final jsonData = jsonDecode(contents);
        setState(() {
          score = jsonData['score'] ?? 0;
        });
      } else {
        await file.writeAsString(jsonEncode({'score': 0}));
        setState(() {
          score = 0;
        });
      }

      // Notify the webview after score is loaded
      sendScoreToWebView();
    } catch (e) {
      debugPrint('Error loading score: $e');
    }
  }

  Future<void> saveScore() async {
    final file = await _scoreFile;
    await file.writeAsString(jsonEncode({'score': score}));
  }

  void sendScoreToWebView() {
    _controller.runJavaScript('window.setScore && window.setScore($score);');
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          sendScoreToWebView(); // Now it's safe!
        },
      ),
    );
  }

  void initWebView() {
    final params = const PlatformWebViewControllerCreationParams();
    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          handleWebMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse("https://allearspet.vercel.app/"));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  void handleWebMessage(String message) {
    try {
      final data = jsonDecode(message);
      final String action = data['action'];
      final int amount = data['amount'];

      if (action == 'increase') {
        setState(() => score += amount);
      } else if (action == 'decrease') {
        setState(() => score = (score - amount).clamp(0, double.infinity).toInt());
      }

      saveScore();
      sendScoreToWebView(); // update web app with new score
    } catch (e) {
      debugPrint("Invalid message from WebView: $message");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // Center the column content vertically
      children: [
        Center(
          child: SizedBox(
            width: 350,
            height: 500,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: WebViewWidget(
                controller: _controller,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer(),
                  ),
                  Factory<HorizontalDragGestureRecognizer>(
                    () => HorizontalDragGestureRecognizer(),
                  ),
                  Factory<ScaleGestureRecognizer>(
                    () => ScaleGestureRecognizer(),
                  ),
                },
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 20.0), // 20 pixels below the webview box
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20.0), // 20 pixels away from the webview box
          child: IconButton(
            icon: const Icon(Icons.refresh, size: 30),
            onPressed: () {
              _controller.reload(); // Reload the webview
            },
          ),
        ),
      ],
    );
  }
}