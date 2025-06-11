import 'package:flutter/material.dart';
import '../database/transaction_db.dart';
import '../models/transaction.dart' as model;
import 'add_transaction_page.dart';
import 'transaction_detail_page.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<model.Transaction> _transactions = [];
  String _sortOption = 'Time Desc';
  bool _isMultiSelectMode = false;
  Set<int> _selectedIds = {};

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
    setState(() => _transactions = txs);
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

  double get balance => totalIncome - totalExpense;

  void _navigateToAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    _loadTransactions();
  }

  void _confirmDeleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text('Delete ${_selectedIds.length} selected transactions?'),
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

    if (confirm == true) {
      for (var id in _selectedIds) {
        await TransactionDB.instance.delete(id);
      }
      setState(() {
        _transactions.removeWhere((t) => _selectedIds.contains(t.id));
        _selectedIds.clear();
        _isMultiSelectMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        scrolledUnderElevation: 0,
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
        actions: _isMultiSelectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedIds.clear();
                      _isMultiSelectMode = false;
                    });
                  },
                ),
              ]
            : null,
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
                _statCard(
                  'TOTAL INCOME',
                  '+${currencyFormatter.format(totalIncome)}',
                  Colors.green,
                  Icons.arrow_upward,
                ),
                const SizedBox(width: 12),
                _statCard(
                  'TOTAL EXPENSE',
                  '-${currencyFormatter.format(totalExpense)}',
                  Colors.red,
                  Icons.arrow_downward,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
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
            const SizedBox(height: 12),
            Expanded(child: _buildTransactionList(_getSortedTransactions())),
          ],
        ),
      ),
      floatingActionButton: _isMultiSelectMode
          ? FloatingActionButton.extended(
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete),
              label: Text('Delete (${_selectedIds.length})'),
              onPressed: _confirmDeleteSelected,
            )
          : FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTransactionPage()),
                );
                _loadTransactions();
              },
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
            onLongPress: () {
              setState(() {
                _isMultiSelectMode = true;
                _selectedIds.add(t.id!);
              });
            },
            onTap: () {
              if (_isMultiSelectMode) {
                setState(() {
                  if (_selectedIds.contains(t.id)) {
                    _selectedIds.remove(t.id);
                    if (_selectedIds.isEmpty) _isMultiSelectMode = false;
                  } else {
                    _selectedIds.add(t.id!);
                  }
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailPage(transaction: t),
                  ),
                ).then((_) => _loadTransactions());
              }
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
                  _isMultiSelectMode
                      ? Checkbox(
                          value: _selectedIds.contains(t.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedIds.add(t.id!);
                              } else {
                                _selectedIds.remove(t.id);
                                if (_selectedIds.isEmpty)
                                  _isMultiSelectMode = false;
                              }
                            });
                          },
                        )
                      : CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[800],
                          child: Icon(
                            t.amount > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.account,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${t.amount > 0 ? '+' : '-'}￥${t.amount.abs()}',
                        style: TextStyle(
                          fontSize: 16,
                          color: t.amount > 0 ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            currencyFormatter.format(balance),
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

  Widget _statCard(String label, String value, Color color, IconData icon) {
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 2,
                  ),
                ),
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
