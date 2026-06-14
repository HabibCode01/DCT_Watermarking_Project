import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this import

class AiChatSheet extends StatefulWidget {
  final String initialPrompt;
  final String titleName;
  final Color themeColor;

  const AiChatSheet({super.key, required this.initialPrompt, required this.titleName, required this.themeColor});

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final String apiKey = ''; // ⚠️ PASTE API KEY HERE
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  
    // Safely pull the key from the .env file!
    final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; 
  
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    _chat = _model.startChat();
    _startInitialAnalysis();
  }

  Future<void> _startInitialAnalysis() async {
    try {
      final response = await _chat.sendMessage(Content.text(widget.initialPrompt));
      setState(() {
        _messages.add({'isUser': false, 'text': response.text ?? "Analysis failed."});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'isUser': false, 'text': "Connection error. Details: $e"});
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;
    
    final userMessage = _textController.text.trim();
    _textController.clear();
    
    setState(() {
      _messages.add({'isUser': true, 'text': userMessage});
      _isLoading = true;
    });
    
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      setState(() {
        _messages.add({'isUser': false, 'text': response.text ?? ""});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'isUser': false, 'text': "Error: Could not reach the server."});
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75, 
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: widget.themeColor),
                    const SizedBox(width: 8),
                    Text(widget.titleName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.themeColor)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'];
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? widget.themeColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                          bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                        ),
                      ),
                      child: Text(msg['text'], style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading) 
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.themeColor)),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(hintText: "Ask Gemini a question...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.send, color: widget.themeColor), onPressed: _sendMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}