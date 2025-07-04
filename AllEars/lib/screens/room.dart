// room.dart
import 'package:app/components/text.dart';
import 'package:app/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/components/scanner.dart'; // Import the new QR scanner page

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();
  final List<_Message> _messages = [];

  String? _apiBaseUrl;
  String? _uuid;
  bool _isLoading = false;
  bool _isApiUrlSetup = false;
  String? _apiErrorText;

  @override
  void initState() {
    super.initState();
    print('DEBUG: initState called.');
    _initializeChat();
  }

  @override
  void dispose() {
    print('DEBUG: dispose called.');
    _controller.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    print('DEBUG: _initializeChat started.');
    final prefs = await SharedPreferences.getInstance();

    _apiBaseUrl = prefs.getString('api_base_url')?.trim();

    print(
        'DEBUG: [_initializeChat] Loaded API Base URL from prefs: "$_apiBaseUrl" (Length: ${_apiBaseUrl?.length ?? 0})');

    if (_apiBaseUrl == null || _apiBaseUrl!.isEmpty || !_apiBaseUrl!.startsWith('http')) {
      print(
          'DEBUG: [_initializeChat] No valid API Base URL found in storage or format incorrect. Showing URL input screen.');
      setState(() {
        _isApiUrlSetup = false;
        _apiUrlController.text = _apiBaseUrl ?? '';
      });
    } else {
      print('DEBUG: [_initializeChat] Validating existing API URL: "$_apiBaseUrl"');
      print('DEBUG: [_initializeChat] Calling _testApiUrl with: "$_apiBaseUrl"');
      if (await _testApiUrl(_apiBaseUrl!)) {
        print(
            'DEBUG: [_initializeChat] Existing API URL is valid and reachable. Proceeding to load UUID and messages.');
        setState(() {
          _isApiUrlSetup = true;
        });
        await _loadUuidAndMessages();
      } else {
        print(
            'DEBUG: [_initializeChat] Existing API URL is unreachable or invalid. Showing URL input screen.');
        setState(() {
          _isApiUrlSetup = false;
          _apiErrorText = 'Previous API URL is invalid or unreachable. Please enter a valid one.';
          _apiUrlController.text = _apiBaseUrl!;
        });
      }
    }
    print('DEBUG: _initializeChat finished. _isApiUrlSetup: $_isApiUrlSetup');
  }

  Future<bool> _testApiUrl(String url) async {
    final testUrl = url.trim();
    print('DEBUG: [_testApiUrl] Attempting GET request to: "$testUrl/" (Length: ${testUrl.length})');
    try {
      final response = await http.get(
        Uri.parse('$testUrl/'), // Changed to GET on '/' endpoint
      ).timeout(const Duration(seconds: 5));

      print('DEBUG: [_testApiUrl] Response status code: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('DEBUG: [_testApiUrl] API URL "$testUrl" is reachable and responded successfully.');
        return true;
      } else {
        print('DEBUG: [_testApiUrl] API URL "$testUrl" returned non-2xx status code.');
        return false;
      }
    } on http.ClientException catch (e) {
      print('ERROR: [_testApiUrl] HTTP Client Exception (likely network/connection issue): $e');
      return false;
    } catch (e) {
      print('ERROR: [_testApiUrl] Generic Error connecting to API URL "$testUrl": $e');
      return false;
    }
  }

  Future<void> _loadUuidAndMessages() async {
    print('DEBUG: _loadUuidAndMessages started.');
    final prefs = await SharedPreferences.getInstance();

    _uuid = prefs.getString('app_uuid');
    if (_uuid == null) {
      _uuid = const Uuid().v4();
      await prefs.setString('app_uuid', _uuid!);
      print('DEBUG: Generated new UUID: $_uuid');
    } else {
      print('DEBUG: Loaded existing UUID: $_uuid');
    }

    final String? savedMessagesJson = prefs.getString('chat_messages');
    print('DEBUG: Saved messages JSON loaded: ${savedMessagesJson != null ? 'YES' : 'NO'}');
    if (savedMessagesJson != null) {
      try {
        final List<dynamic> decodedMessages = json.decode(savedMessagesJson);
        setState(() {
          _messages.addAll(decodedMessages.map((msg) => _Message(
                text: msg['text'],
                isBot: msg['isBot'],
              )));
        });
        print('DEBUG: Loaded ${decodedMessages.length} messages from storage.');
      } catch (e) {
        print('ERROR: Failed to decode saved messages: $e');
        _messages.clear();
      }
    }
    print('DEBUG: _loadUuidAndMessages finished.');
  }

  Future<void> _saveApiUrlAndProceed() async {
    final String enteredUrl = _apiUrlController.text.trim();
    print('DEBUG: [_saveApiUrlAndProceed] User entered (trimmed) URL: "$enteredUrl" (Length: ${enteredUrl.length})');

    if (enteredUrl.isEmpty) {
      setState(() {
        _apiErrorText = 'API URL cannot be empty.';
      });
      return;
    }
    if (!enteredUrl.startsWith('http://') && !enteredUrl.startsWith('https://')) {
      setState(() {
        _apiErrorText = 'URL must start with http:// or https://';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _apiErrorText = null;
    });

    print('DEBUG: [_saveApiUrlAndProceed] Calling _testApiUrl with: "$enteredUrl"');
    final isValid = await _testApiUrl(enteredUrl);

    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_base_url', enteredUrl);
      print('DEBUG: [_saveApiUrlAndProceed] Saved API URL to prefs: "$enteredUrl"');
      setState(() {
        _apiBaseUrl = enteredUrl;
        _isApiUrlSetup = true;
        _isLoading = false;
      });
      print(
          'DEBUG: [_saveApiUrlAndProceed] Successfully saved and validated API URL: "$_apiBaseUrl". Calling _loadUuidAndMessages.');
      await _loadUuidAndMessages();
    } else {
      setState(() {
        _apiErrorText = 'Invalid or unreachable API URL. Please check and try again.';
        _isLoading = false;
      });
      print('DEBUG: [_saveApiUrlAndProceed] Failed to validate URL: "$enteredUrl"');
    }
  }

  // New method to handle URL from QR scanner
  void _handleScannedUrl(String scannedUrl) async {
    print('DEBUG: _handleScannedUrl received: $scannedUrl');
    setState(() {
      _apiUrlController.text = scannedUrl;
      _apiErrorText = null;
    });
    await _saveApiUrlAndProceed();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> messagesToEncode = _messages.map((msg) => {
          'text': msg.text,
          'isBot': msg.isBot,
        }).toList();
    await prefs.setString('chat_messages', json.encode(messagesToEncode));
    print('DEBUG: Messages saved to storage.');
  }

  void _sendMessage(String text) async {
    print('DEBUG: _sendMessage called with text: "$text"');
    if (text.trim().isEmpty || _uuid == null || _isLoading || _apiBaseUrl == null) {
      print(
          'DEBUG: _sendMessage early exit - text empty, uuid null, isLoading true, or _apiBaseUrl null. Current _apiBaseUrl: "$_apiBaseUrl"');
      return;
    }

    final userMessageText = text.trim();

    setState(() {
      _messages.add(_Message(text: userMessageText, isBot: false));
      _controller.clear();
      _isLoading = true;
    });
    _saveMessages();

    try {
      final String currentApiBaseUrl = _apiBaseUrl!.trim();
      print(
          'DEBUG: [_sendMessage] Using API Base URL for requests: "$currentApiBaseUrl" (Length: ${currentApiBaseUrl.length})');

      print('DEBUG: Calling /classify with prompt: "$userMessageText" to "$currentApiBaseUrl/classify"');
      final classifyResponse = await http.post(
        Uri.parse('$currentApiBaseUrl/classify'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Dart/Flutter (compatible)',
        },
        body: json.encode({'prompt': userMessageText, 'id': _uuid}),
      );

      if (classifyResponse.statusCode != 200) {
        print('ERROR: Classify failed. Status: ${classifyResponse.statusCode}, Body: ${classifyResponse.body}');
        throw Exception('Failed to classify message: ${classifyResponse.statusCode} ${classifyResponse.body}');
      }
      final classifyData = json.decode(classifyResponse.body);
      final String role = classifyData['ai_response'];
      print('DEBUG: Classification successful. Role: $role');

      print('DEBUG: Calling /conversation?mode=$role with prompt: "$userMessageText" to "$currentApiBaseUrl/conversation?mode=$role"');
      final conversationResponse = await http.post(
        Uri.parse('$currentApiBaseUrl/conversation?mode=$role'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': userMessageText, 'id': _uuid}),
      );

      if (conversationResponse.statusCode != 200) {
        print('ERROR: Conversation failed. Status: ${conversationResponse.statusCode}, Body: ${conversationResponse.body}');
        throw Exception('Failed to get conversation response: ${conversationResponse.statusCode} ${conversationResponse.body}');
      }
      final conversationData = json.decode(conversationResponse.body);
      final String aiResponse = conversationData['ai_response'];
      print('DEBUG: Conversation response received: $aiResponse');

      setState(() {
        _messages.add(_Message(text: aiResponse, isBot: true));
      });
      _saveMessages();
    } on http.ClientException catch (e) {
      print('CRITICAL ERROR: [_sendMessage] HTTP Client Exception (network/connection issue during API call): $e');
      setState(() {
        _messages.add(_Message(text: "Error: Network connection problem. Please verify the API URL and your internet connection.", isBot: true));
        _isApiUrlSetup = false;
        _apiErrorText = 'Connection error. Please verify the API URL.';
        _apiUrlController.text = _apiBaseUrl ?? '';
      });
      _saveMessages();
    } catch (e) {
      print('CRITICAL ERROR: [_sendMessage] Generic Error during API call: $e');
      setState(() {
        _messages.add(_Message(text: "Error: Could not get a response. Please try again. The API URL might be invalid.", isBot: true));
        _isApiUrlSetup = false;
        _apiErrorText = 'An unexpected error occurred. Please verify the API URL.';
        _apiUrlController.text = _apiBaseUrl ?? '';
      });
      _saveMessages();
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('DEBUG: _sendMessage finished. _isLoading set to false.');
    }
  }

  void _clearChat() async {
    print('DEBUG: _clearChat called.');
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _messages.clear();
    });
    // No need to persist _isInitialMessageAdded as it's no longer used for the initial message
    await prefs.remove('chat_messages'); // Clear saved messages from storage

    if (_uuid != null && _apiBaseUrl != null) {
      try {
        final String currentApiBaseUrl = _apiBaseUrl!.trim();
        print('DEBUG: Calling /clear_memory with ID: "$_uuid" to "$currentApiBaseUrl/clear_memory"');
        final clearMemoryResponse = await http.post(
          Uri.parse('$currentApiBaseUrl/clear_memory'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'id': _uuid}),
        );

        if (clearMemoryResponse.statusCode == 200) {
          print('DEBUG: Memory cleared on server for UUID: $_uuid');
        } else {
          print(
              'ERROR: Failed to clear memory on server: ${clearMemoryResponse.statusCode} ${clearMemoryResponse.body}');
        }
      } on http.ClientException catch (e) {
        print('ERROR: [_clearChat] HTTP Client Exception: $e');
      } catch (e) {
        print('ERROR: [_clearChat] Generic Error calling /clear_memory: $e');
      }
    }
    print('DEBUG: Chat cleared, UUID remains: $_uuid');
  }

  // New method to reset API URL and show input screen
  void _resetApiUrl() async {
    print('DEBUG: _resetApiUrl called.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_base_url'); // Clear the saved API URL
    // Also clear chat messages when resetting API URL
    await prefs.remove('chat_messages');
    setState(() {
      _apiBaseUrl = null;
      _isApiUrlSetup = false;
      _apiErrorText = null;
      _apiUrlController.clear(); // Clear the text field
      _messages.clear(); // Clear messages if we're resetting the URL
    });
    // No need to call _loadUuidAndMessages here, as it will be called upon successful API setup
    print('DEBUG: API URL reset and input screen displayed.');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isApiUrlSetup) {
      print('DEBUG: Building API URL input screen.');
      return Scaffold(
        backgroundColor: const Color(0xFFFFEBD7),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/img/pet/head.gif',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 20),
                const Head1(
                  'Welcome!',
                  color: Color(0xFF3F4D86),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Head2(
                  'Please enter your AI API URL to start chatting.',
                  color: Color(0xFF3F4D86),
                  textAlign: TextAlign.center,
                  weight: 400,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _apiUrlController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'API Base URL (e.g., http://192.168.1.100:5000)',
                    hintText: 'Enter API URL',
                    errorText: _apiErrorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF979C9E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF979C9E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3F4D86), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F3F4),
                    labelStyle: const TextStyle(color: Color(0xFF3F4D86)),
                    hintStyle: const TextStyle(color: Color(0xFF72777A)),
                  ),
                  keyboardType: TextInputType.url,
                  style: const TextStyle(
                    color: Color(0xFF3F4D86),
                    fontSize: 16,
                    fontFamily: 'Nunito Sans',
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F4D86)),
                      )
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _saveApiUrlAndProceed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F4D86),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Connect to API',
                              style: TextStyle(
                                color: Color(0xFFFFEBD7),
                                fontSize: 18,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => QRScannerPage(
                                    onUrlScanned: _handleScannedUrl,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF3F4D86)),
                            label: const Text(
                              'Scan QR Code',
                              style: TextStyle(
                                color: Color(0xFF3F4D86),
                                fontSize: 18,
                                fontFamily: 'Nunito Sans',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF2F3F4),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFF3F4D86), width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      );
    }

    print('DEBUG: Building chat room screen.');
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBD7),
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                SvgPicture.asset(
                  'assets/img/homepage/bghead.svg',
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.contain,
                  semanticsLabel: 'Bghead',
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Head1("AI Listener", lineHeight: 1.8),
                              const SizedBox(width: 12),
                              Image.asset(
                                'assets/img/pet/head.gif',
                                height: 64,
                                width: 64,
                              ),
                              // Moved the settings button here
                              IconButton(
                                icon: const Icon(Icons.settings, color: AppColors.karry),
                                onPressed: _resetApiUrl,
                                splashRadius: 24.0, // Adjust splash radius as needed
                              ),
                            ],
                          ),
                          Head2(
                            'Talk to your pet!',
                            textAlign: TextAlign.center,
                            weight: 400,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _messages.length + 1, // Add 1 for the static greeting
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // This is the static greeting message
                    return BotMessage(message: "How can I help you? I will try my best to be your companion today");
                  }
                  // Adjust index for actual messages list
                  final message = _messages[index - 1];
                  return message.isBot
                      ? BotMessage(message: message.text)
                      : UserMessage(message: message.text);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F4D86)),
                ),
              ),
            const SizedBox(height: 12),
            ChatInput(
              controller: _controller,
              onSubmitted: _sendMessage,
              onClearChat: _clearChat,
              isLoading: _isLoading,
            ),
            // Removed the SizedBox(height: 16) here to resolve the overflow
          ],
        ),
      ),
      // Removed the FloatingActionButton here
    );
  }
}

// ... (Your _Message, BotMessage, UserMessage, ChatInput classes remain the same)

class _Message {
  final String text;
  final bool isBot;

  _Message({required this.text, required this.isBot});
}

class BotMessage extends StatelessWidget {
  final String message;

  const BotMessage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF3F4D86),
            fontSize: 16,
            fontFamily: 'Nunito Sans',
          ),
        ),
      ),
    );
  }
}

class UserMessage extends StatelessWidget {
  final String message;

  const UserMessage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF3F4D86),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(45),
            bottomLeft: Radius.circular(24),
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFFFEBD7),
            fontSize: 16,
            fontFamily: 'Nunito Sans',
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmitted;
  final VoidCallback? onClearChat; // New callback for clearing chat
  final bool isLoading; // New parameter to disable input

  const ChatInput({
    required this.controller,
    required this.onSubmitted,
    this.onClearChat, // Make it optional
    this.isLoading = false, // Default to false
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFEBD7),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column( // Changed from Row to Column to stack elements
        crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure children stretch horizontally
        children: [
          Row( // Row for the buttons
            mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
            children: [
              // Trash button
              IconButton(
                icon: const Icon(Icons.delete_forever,
                    color: Color(0xFF3F4D86)), // Using delete_forever for a clear trash icon
                onPressed: isLoading ? null : onClearChat, // Disable button when loading
              ),
              // Send button
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF3F4D86)),
                onPressed: isLoading ? null : () => onSubmitted(controller.text), // Disable button when loading
              ),
            ],
          ),
          const SizedBox(height: 8), // Space between buttons and text input
          Container( // Container for the TextField
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF979C9E),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(48),
              color: const Color(0xFFFFEBD7),
            ),
            child: TextField(
              controller: controller,
              onSubmitted: isLoading ? null : onSubmitted, // Disable submission when loading
              enabled: !isLoading, // Disable TextField when loading
              minLines: 1, // Set minimum lines to 1
              maxLines: 5, // Allows the TextField to expand vertically up to 5 lines, then scrolls
              keyboardType:
                  TextInputType.multiline, // Ensures the keyboard provides a multiline input option
              style: const TextStyle(
                // Apply style directly to TextField for consistency
                color: Color(0xFF3F4D86),
                fontSize: 16,
                fontFamily: 'Nunito Sans',
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(
                  color: Color(0xFF72777A),
                  fontSize: 16,
                  fontFamily: 'Alegreya Sans',
                ),
                isCollapsed: true, // Makes the hint text behave like InputDecoration.collapsed
                border: InputBorder.none, // Removes the default border of TextField
                contentPadding: EdgeInsets.zero, // Remove default content padding
              ),
            ),
          ),
        ],
      ),
    );
  }
}
