import 'package:app/components/text.dart'; // Assuming this path is correct for your custom text widgets
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart'; // Re-import UUID package
import 'package:shared_preferences/shared_preferences.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_Message> _messages = []; // Initialize empty, will load from storage
  final String _apiBaseUrl = 'http://192.168.18.9:8000'; // Your API base URL
  String? _uuid; // To store the unique app/user ID (UUID string)
  bool _isLoading = false; // To show loading indicator during API calls

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  // Initializes the chat by loading UUID and messages from shared preferences
  // and adding the initial bot message.
  Future<void> _initializeChat() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load UUID
    _uuid = prefs.getString('app_uuid'); // Use a distinct key for the app's UUID
    if (_uuid == null) {
      _uuid = const Uuid().v4(); // Generate new UUID if not found
      await prefs.setString('app_uuid', _uuid!);
      print('Generated new UUID: $_uuid');
    } else {
      print('Loaded existing UUID: $_uuid');
    }

    // Load messages
    final String? savedMessagesJson = prefs.getString('chat_messages');
    if (savedMessagesJson != null) {
      final List<dynamic> decodedMessages = json.decode(savedMessagesJson);
      setState(() {
        _messages.addAll(decodedMessages.map((msg) => _Message(
          text: msg['text'],
          isBot: msg['isBot'],
        )));
      });
      print('Loaded ${decodedMessages.length} messages from storage.');
    }

    // Add initial bot message if chat is new or empty
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(_Message(text: "How can I help you? I will try my best to be your companion today", isBot: true));
      });
      _saveMessages(); // Save the initial message
    }
  }

  // Saves the current list of messages to shared preferences
  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> messagesToEncode = _messages.map((msg) => {
      'text': msg.text,
      'isBot': msg.isBot,
    }).toList();
    await prefs.setString('chat_messages', json.encode(messagesToEncode));
    print('Messages saved to storage.');
  }

  // Handles sending a message, including API calls and UI updates
  void _sendMessage(String text) async {
    // Ensure UUID is not null and not already loading
    if (text.trim().isEmpty || _uuid == null || _isLoading) return;

    final userMessageText = text.trim();

    setState(() {
      _messages.add(_Message(text: userMessageText, isBot: false));
      _controller.clear();
      _isLoading = true; // Set loading to true
    });
    _saveMessages(); // Save user message immediately

    try {
      // Step 1: Call /classify endpoint
      print('Calling /classify with prompt: "$userMessageText" and ID: "$_uuid"');
      final classifyResponse = await http.post(
        Uri.parse('$_apiBaseUrl/classify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': userMessageText, 'id': _uuid}), // Use UUID string
      );

      if (classifyResponse.statusCode != 200) {
        throw Exception('Failed to classify message: ${classifyResponse.statusCode} ${classifyResponse.body}');
      }
      final classifyData = json.decode(classifyResponse.body);
      final String role = classifyData['ai_response'];
      print('Classification successful. Role: $role');

      // Step 2: Call /conversation endpoint with the determined role
      print('Calling /conversation?mode=$role with prompt: "$userMessageText" and ID: "$_uuid"');
      final conversationResponse = await http.post(
        Uri.parse('$_apiBaseUrl/conversation?mode=$role'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': userMessageText, 'id': _uuid}), // Use UUID string
      );

      if (conversationResponse.statusCode != 200) {
        throw Exception('Failed to get conversation response: ${conversationResponse.statusCode} ${conversationResponse.body}');
      }
      final conversationData = json.decode(conversationResponse.body);
      final String aiResponse = conversationData['ai_response'];
      print('Conversation response received: $aiResponse');

      setState(() {
        _messages.add(_Message(text: aiResponse, isBot: true));
      });
      _saveMessages(); // Save bot message
    } catch (e) {
      print('Error during API call: $e');
      setState(() {
        _messages.add(_Message(text: "Error: Could not get a response. Please try again.", isBot: true));
      });
      _saveMessages(); // Save error message
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  // Clears all messages from the chat and posts to /clear_memory, keeping the UUID
  void _clearChat() async { // Made async to await API call
    setState(() {
      _messages.clear();
      _messages.add(_Message(text: "How can I help you? I will try my best to be your companion today", isBot: true));
    });
    _saveMessages(); // Save the cleared chat

    // Call /clear_memory endpoint
    if (_uuid != null) {
      try {
        print('Calling /clear_memory with ID: "$_uuid"');
        final clearMemoryResponse = await http.post(
          Uri.parse('$_apiBaseUrl/clear_memory'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'id': _uuid}),
        );

        if (clearMemoryResponse.statusCode == 200) {
          print('Memory cleared on server for UUID: $_uuid');
        } else {
          print('Failed to clear memory on server: ${clearMemoryResponse.statusCode} ${clearMemoryResponse.body}');
        }
      } catch (e) {
        print('Error calling /clear_memory: $e');
      }
    }
    print('Chat cleared, UUID remains: $_uuid');
  }

  @override
  Widget build(BuildContext context) {
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
                              )
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
            const SizedBox(height:32),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return message.isBot
                      ? BotMessage(message: message.text)
                      : UserMessage(message: message.text);
                },
              ),
            ),
            // Show loading indicator if _isLoading is true
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
              onClearChat: _clearChat, // Pass the new clear chat function
              isLoading: _isLoading, // Pass loading state to disable input
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Align items to the bottom when text field expands
        children: [
          Expanded(
            child: Container(
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
                maxLines: null, // Allows the TextField to expand vertically
                keyboardType: TextInputType.multiline, // Ensures the keyboard provides a multiline input option
                style: const TextStyle( // Apply style directly to TextField for consistency
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
          ),
          const SizedBox(width: 8),
          // New Trash button
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Color(0xFF3F4D86)), // Using delete_forever for a clear trash icon
            onPressed: isLoading ? null : onClearChat, // Disable button when loading
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF3F4D86)),
            onPressed: isLoading ? null : () => onSubmitted(controller.text), // Disable button when loading
          ),
        ],
      ),
    );
  }
}
