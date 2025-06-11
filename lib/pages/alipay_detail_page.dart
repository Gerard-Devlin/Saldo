import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;
import '../database/transaction_db.dart';
import 'transaction_detail_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AlipayDetailPage extends StatefulWidget {
  const AlipayDetailPage({super.key});

  @override
  State<AlipayDetailPage> createState() => _AlipayDetailPageState();
}

class _AlipayDetailPageState extends State<AlipayDetailPage> {
  List<model.Transaction> _transactions = [];
  double _balance = 0.0;
  String _sortOption = 'Time Desc';

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '￥',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txs = await TransactionDB.instance.readAll();
    final alipayTxs = txs.where((t) => t.account == 'Alipay').toList();
    
    setState(() {
      _transactions = alipayTxs;
      _balance = alipayTxs.fold(0.0, (sum, tx) => sum + tx.amount);
    });
  }

  List<model.Transaction> _getSortedTransactions() {
    List<model.Transaction> sorted = [..._transactions];
    switch (_sortOption) {
      case 'Amount Asc':
        sorted.sort((a, b) => a.amount.abs().compareTo(b.amount.abs()));
        break;
      case 'Amount Desc':
        sorted.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
        break;
      case 'Time Desc':
      default:
        sorted.sort((a, b) => b.date.compareTo(a.date));
    }
    return sorted;
  }

  double get totalIncome => _transactions
      .where((t) => t.amount > 0)
      .fold(0.0, (a, b) => a + b.amount);

  double get totalExpense => _transactions
      .where((t) => t.amount < 0)
      .fold(0.0, (a, b) => a + b.amount.abs());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        scrolledUnderElevation: 0,
        title: const Text(
          'Alipay Account',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildAlipayCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                DropdownButton<String>(
                  dropdownColor: Colors.grey[850],
                  value: _sortOption,
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'Time Desc',
                      child: Text('   📅 Time'),
                    ),
                    DropdownMenuItem(
                      value: 'Amount Asc',
                      child: Text('   ⬆️ Amount'),
                    ),
                    DropdownMenuItem(
                      value: 'Amount Desc',
                      child: Text('   ⬇️ Amount'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _sortOption = value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildTransactionList(_getSortedTransactions()),
          ),
        ],
      ),
    );
  }

  Widget _buildAlipayCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1677FF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                FontAwesomeIcons.alipay,
                size: 200,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Alipay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.payment, color: Colors.white, size: 24),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'CURRENT BALANCE',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '¥${_balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            '¥${amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<model.Transaction> txs) {
    if (txs.isEmpty) {
      return const Center(
        child: Text(
          'No transactions yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: txs.length,
      itemBuilder: (context, index) {
        final t = txs[index];
        return Dismissible(
          key: Key(t.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirm'),
                content: const Text(
                  'Are you sure you want to delete this transaction?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) async {
            await TransactionDB.instance.delete(t.id!);
            setState(() {
              _transactions.removeWhere((tx) => tx.id == t.id);
            });
          },
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailPage(transaction: t),
                ),
              ).then((_) => _loadTransactions());
            },
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
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
                          DateFormat('yyyy-MM-dd').format(t.date),
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
          ),
        );
      },
    );
  }
} 