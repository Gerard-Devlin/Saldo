import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/transaction_db.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../models/transaction.dart' as model;
import 'package:intl/intl.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_page.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showScrollToBottom = false;

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final String _apiKey = "sk-2t6V95UUvZwvSfqEOM6twl0koCfuhtliNYdpoKULY3chPwNF";
  List<model.Transaction> _recentTransactions = [];

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '￥',
    decimalDigits: 0,
  );

  Widget _renderMixedMarkdownAndMath(String content) {
    final regex = RegExp(r'\\\[(.*?)\\\]', dotAll: true); // 匹配 \[...\]
    final matches = regex.allMatches(content);

    final safeTheme = ThemeData.dark().copyWith(
      textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 14)),
    );

    if (matches.isEmpty) {
      return MarkdownBody(
        data: content,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          code: const TextStyle(color: Colors.orangeAccent),
        ),
      );
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          WidgetSpan(
            child: MarkdownBody(
              data: content.substring(lastIndex, match.start),
              styleSheet: MarkdownStyleSheet.fromTheme(safeTheme),
            ),
          ),
        );
      }

      final texString = match.group(1)?.trim() ?? '';
      spans.add(
        WidgetSpan(
          child: Math.tex(
            texString,
            textStyle: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      spans.add(
        WidgetSpan(
          child: MarkdownBody(
            data: content.substring(lastIndex),
            styleSheet: MarkdownStyleSheet.fromTheme(safeTheme),
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

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

    // 在页面初始化时滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 监听焦点变化
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // 当页面获得焦点时，滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在页面重新获得焦点时滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
          decoded.map<Map<String, dynamic>>(
            (item) {
              final message = <String, dynamic>{
                'role': item['role'].toString(),
                'content': item['content'].toString(),
              };
              
              // 如果有交易信息，重新创建交易对象
              if (item.containsKey('transaction')) {
                final tx = item['transaction'] as Map<String, dynamic>;
                message['transaction'] = model.Transaction(
                  id: tx['id'] as int?,
                  title: tx['title'] as String,
                  amount: (tx['amount'] as num).toDouble(),
                  date: DateTime.parse(tx['date'] as String),
                  type: tx['type'] as String,
                  account: tx['account'] as String,
                );
              }
              
              return message;
            },
          ),
        );
        
        // 在加载完历史消息后直接跳转到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
        
        setState(() {});
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesToSave = _messages.map((msg) {
      final message = <String, dynamic>{
        'role': msg['role'],
        'content': msg['content'],
      };
      
      // 如果有交易信息，转换为可序列化的格式
      if (msg.containsKey('transaction')) {
        final tx = msg['transaction'] as model.Transaction;
        message['transaction'] = {
          'id': tx.id,
          'title': tx.title,
          'amount': tx.amount,
          'date': tx.date.toIso8601String(),
          'type': tx.type,
          'account': tx.account,
        };
      }
      
      return message;
    }).toList();
    
    await prefs.setString('ai_chat_history', json.encode(messagesToSave));
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_chat_history', json.encode([]));
    setState(() {
      _messages.clear();
    });
  }

  Future<String> _generateFinancialSummary() async {
    final transactions = await TransactionDB.instance.readAll();
    final summary = transactions
        .map(
          (t) =>
              "Date: ${t.date}, Title: ${t.title}, Amount: ${t.amount}, Account: ${t.account}",
        )
        .join("\n");
    return summary;
  }

  Widget _buildTransactionCard(model.Transaction t) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailPage(transaction: t),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width - 32,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey[800],
              child: Icon(
                t.amount > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: t.amount > 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${t.account} · ${DateFormat('yyyy-MM-dd').format(t.date)}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${t.amount > 0 ? '+' : ''}${currencyFormatter.format(t.amount)}',
              style: TextStyle(
                color: t.amount > 0 ? Colors.green : Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTransaction(String title, double amount, String account) async {
    final transaction = model.Transaction(
      title: title,
      amount: amount,
      date: DateTime.now(),
      type: amount >= 0 ? 'Income' : 'Expense',
      account: account,
    );

    await TransactionDB.instance.create(transaction);
    setState(() {
      _recentTransactions.insert(0, transaction);
    });
  }

  Future<void> _processAIResponse(String response) async {
    // 首先检查是否是JSON格式的响应
    if (response.trim().startsWith('{')) {
      try {
        final Map<String, dynamic> data = json.decode(response);
        if (data.containsKey('action') && data['action'] == 'add_transaction') {
          // 验证必要字段
          if (!data.containsKey('title') || !data.containsKey('amount') || !data.containsKey('account')) {
            throw Exception('缺少必要字段');
          }

          // 验证金额
          final amount = data['amount'];
          if (amount is! num) {
            throw Exception('金额格式不正确');
          }

          // 验证账户
          final account = data['account'].toString();
          if (account != 'Alipay' && account != 'WeChat') {
            throw Exception('账户必须是 Alipay 或 WeChat');
          }

          // 创建并添加交易
          final transaction = model.Transaction(
            title: data['title'].toString(),
            amount: amount.toDouble(),
            date: DateTime.now(),
            type: amount >= 0 ? 'Income' : 'Expense',
            account: account,
          );

          await TransactionDB.instance.create(transaction);

          // 添加一个包含交易卡片的AI消息
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': '已添加交易：',
              'transaction': transaction,
            });
          });
          return;
        }
      } catch (e) {
        debugPrint('AI响应解析错误: $e');
        debugPrint('原始响应: $response');
      }
    }

    // 如果不是JSON格式或解析失败，直接显示消息
    setState(() {
      _messages.add({'role': 'assistant', 'content': response});
    });
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

    // 准备发送给AI的消息，移除Transaction对象
    final messagesForApi = [
      {'role': 'system', 'content': '''你是一个专业的财务分析助手，主要职责是帮助用户分析他们的财务状况。你可以：

1. 分析用户的收支情况，提供详细的财务报告
2. 识别消费模式和趋势
3. 提供财务建议和优化方案
4. 回答用户的财务相关问题

当用户要求添加交易时，请以JSON格式回复，格式如下：
{
  "action": "add_transaction",
  "title": "交易标题",
  "amount": 金额（正数表示收入，负数表示支出）,
  "account": "Alipay或WeChat"
}

其他情况下，请直接以自然语言回复，提供专业的财务分析和建议。'''},
      {'role': 'user', 'content': '以下是我的全部交易数据：\n$summary'},
      ...(_messages.length > 10
          ? _messages.sublist(_messages.length - 10).map((msg) => {
                'role': msg['role'],
                'content': msg['content'],
              })
          : _messages.map((msg) => {
                'role': msg['role'],
                'content': msg['content'],
              })),
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

      await _processAIResponse(reply.trim());
      setState(() {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 10, top: 15),
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
            padding: const EdgeInsets.only(top: 15, right: 13),
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
                          "Hey, ready to dive in?",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
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
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
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
                                    child: _renderMixedMarkdownAndMath(
                                      msg['content'] ?? '',
                                    ),
                                  ),
                                  if (msg.containsKey('transaction') && msg['transaction'] != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: _buildTransactionCard(msg['transaction'] as model.Transaction),
                                    ),
                                ],
                              );
                            }
                          } else {
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
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(width: 6),
                                    LoadingDots(),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
              ),

              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _isLoading ? Icons.pause : Icons.arrow_upward,
                          color: Colors.black,
                          size: 24,
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

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
