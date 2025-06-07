import 'package:flutter/material.dart';
import '../database/transaction_db.dart';
import '../models/transaction.dart' as model;
import 'add_transaction_page.dart';
import 'transaction_detail_page.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<model.Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txs = await TransactionDB.instance.readAll();
    setState(() => _transactions = txs);
  }

  double get totalIncome =>
      _transactions.where((t) => t.amount > 0).fold(0.0, (a, b) => a + b.amount);

  double get totalExpense =>
      _transactions.where((t) => t.amount < 0).fold(0.0, (a, b) => a + b.amount.abs());

  double get balance => totalIncome - totalExpense;

  void _navigateToAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    _loadTransactions(); // 添加交易后刷新
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Saldo',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: 'cursive',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                _statCard('TOTAL INCOME', '+\￥${totalIncome.toStringAsFixed(0)}',
                    Colors.green, Icons.arrow_downward),
                const SizedBox(width: 12),
                _statCard('TOTAL EXPENSE', '-\￥${totalExpense.toStringAsFixed(0)}',
                    Colors.red, Icons.arrow_upward),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Recent Transaction',
                style: TextStyle(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 12),
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(
                  child: Text('No transactions yet.',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final t = _transactions[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                TransactionDetailPage(transaction: t)),
                      );
                    },
                    child: Container(
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
                              t.amount > 0
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: t.amount > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(t.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(t.tag,
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${t.amount > 0 ? '+' : '-'}\￥${t.amount.abs()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: t.amount > 0
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        onPressed: _navigateToAddTransaction,
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'TOTAL BALANCE',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\￥${balance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, size: 16, color: color),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey, height: 2)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
