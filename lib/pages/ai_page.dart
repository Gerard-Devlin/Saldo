import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/transaction_db.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/transaction.dart' as model;

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final String _apiKey = "sk-2t6V95UUvZwvSfqEOM6twl0koCfuhtliNYdpoKULY3chPwNF";

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(() {
      final atBottom =
          _scrollController.offset >=
          _scrollController.position.maxScrollExtent - 50;
      if (_showScrollToBottom != !atBottom) {
        setState(() {
          _showScrollToBottom = !atBottom;
        });
      }
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('ai_chat_history');
    if (saved != null) {
      final decoded = json.decode(saved);
      if (decoded is List) {
        _messages.addAll(
          decoded.map<Map<String, String>>(
            (item) => {
              'role': item['role'].toString(),
              'content': item['content'].toString(),
            },
          ),
        );
        setState(() {});
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_chat_history', json.encode(_messages));
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_chat_history');
    setState(() {
      _messages.clear();
    });
  }

  Future<String> _generateFinancialSummary() async {
    final transactions = await TransactionDB.instance.readAll();
    final summary = transactions
        .map(
          (t) =>
              "Date: ${t.date}, Title: ${t.title}, Amount: ${t.amount}, Tag: ${t.account}",
        )
        .join("\n");
    return summary;
  }

  Future<void> _sendMessage(String userMessage) async {
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    final summary = await _generateFinancialSummary();

    final messagesForApi = [
      {'role': 'system', 'content': '你是一个精通收支分析的财务助理，你的任务是帮用户分析他们的交易记录。'},
      {'role': 'user', 'content': '以下是我的全部交易数据：\n$summary'},
      ...(_messages.length > 10
          ? _messages.sublist(_messages.length - 10)
          : _messages),
    ];

    final url = Uri.parse('https://api.moonshot.cn/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"model": "moonshot-v1-8k", "messages": messagesForApi}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final reply = decoded['choices'][0]['message']['content'];

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply.trim()});
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      await _saveHistory();
    } else {
      setState(() => _isLoading = false);
      debugPrint("Kimi API Error: ${response.statusCode} ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Kimi API Error ${response.statusCode}: ${response.reasonPhrase}",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 10, top: 13),
          child: Text(
            "🤖",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontFamily: 'cursive',
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 13, right: 13),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_forever),
                color: Colors.red,
                onPressed: _clearHistory,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Text(
                          "Anything I can help?",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 30,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length) {
                            final msg = _messages[index];
                            final isUser = msg['role'] == 'user';

                            if (isUser) {
                              return Container(
                                alignment: Alignment.centerRight,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18),
                                      bottomLeft: Radius.circular(18),
                                    ),
                                  ),
                                  child: MarkdownBody(
                                    data: msg['content'] ?? '',
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      code: const TextStyle(
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                color: Colors.black,
                                child: MarkdownBody(
                                  data: msg['content'] ?? '',
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                    code: const TextStyle(
                                      color: Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                              );
                            }
                          }

                          // Loading animation
                          return Container(
                            alignment: Alignment.centerLeft,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Typing🙇‍♂️',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  SizedBox(width: 6),
                                  LoadingDots(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // 输入框区域
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration.collapsed(
                          hintText: "Ask anything ...",
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                        onSubmitted: (value) {
                          final text = value.trim();
                          if (text.isNotEmpty && !_isLoading) {
                            _sendMessage(text);
                            _controller.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic, color: Colors.white),
                      onPressed: () {},
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              final text = _controller.text.trim();
                              if (text.isNotEmpty) {
                                _sendMessage(text);
                                _controller.clear();
                              }
                            },
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_showScrollToBottom)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    _dotCount = StepTween(begin: 1, end: 3).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (_, __) => Text(
        '.' * _dotCount.value,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
