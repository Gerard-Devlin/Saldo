import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/transaction.dart' as model;
import '../database/transaction_db.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  List<model.Transaction> _transactions = [];
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txs = await TransactionDB.instance.readAll();
    setState(() => _transactions = txs);
  }

  double get totalIncome => _transactions
      .where((t) => _inSelectedMonth(t.date) && t.amount > 0)
      .fold(0.0, (a, b) => a + b.amount);

  double get totalExpense => _transactions
      .where((t) => _inSelectedMonth(t.date) && t.amount < 0)
      .fold(0.0, (a, b) => a + b.amount.abs());

  double get balance => totalIncome - totalExpense;

  bool _inSelectedMonth(DateTime date) {
    return date.year == _selectedYear && date.month == _selectedMonth;
  }

  Map<int, double> get dailyExpenses {
    final map = <int, double>{};
    for (final t in _transactions) {
      if (_inSelectedMonth(t.date) && t.amount < 0) {
        final day = t.date.day;
        map[day] = (map[day] ?? 0) + t.amount.abs();
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    final maxExpense = dailyExpenses.values.isEmpty
        ? 1
        : dailyExpenses.values.reduce(max);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Detail',
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
        child: ListView(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: _selectedMonth,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      underline: const SizedBox(),
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (month) => DropdownMenuItem(
                              value: month,
                              child: Text(
                                DateFormat.MMMM().format(DateTime(0, month)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(
                        () => _selectedMonth = val ?? _selectedMonth,
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _selectedYear,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      underline: const SizedBox(),
                      items: List.generate(5, (i) => DateTime.now().year - i)
                          .map(
                            (year) => DropdownMenuItem(
                              value: year,
                              child: Text('$year'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedYear = val ?? _selectedYear),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMonthlyReportCard(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const Text(
                  // 'Expense Calendar View',
                  // style: TextStyle(color: Colors.white, fontSize: 16),
                  // ),
                  const SizedBox(height: 0),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: daysInMonth + (firstWeekday - 1),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                    itemBuilder: (context, index) {
                      if (index < firstWeekday - 1) return const SizedBox();
                      final day = index - (firstWeekday - 2);
                      final amount = dailyExpenses[day] ?? 0;
                      final ratio = sqrt(amount / maxExpense).clamp(0.0, 1.0);
                      final color = amount == 0
                          ? Colors.grey[850]
                          : Color.lerp(
                              Colors.green[300],
                              Colors.red[800],
                              ratio,
                            );
                      return Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            color: amount > 0 ? Colors.white : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Mon', style: TextStyle(color: Colors.grey)),
                      Text('Tue', style: TextStyle(color: Colors.grey)),
                      Text('Wed', style: TextStyle(color: Colors.grey)),
                      Text('Thu', style: TextStyle(color: Colors.grey)),
                      Text('Fri', style: TextStyle(color: Colors.grey)),
                      Text('Sat', style: TextStyle(color: Colors.grey)),
                      Text('Sun', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyReportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${DateFormat.MMMM().format(DateTime(_selectedYear, _selectedMonth))} $_selectedYear',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Income', totalIncome, Colors.green),
          _buildStatRow('Expense', totalExpense, Colors.red),
          const Divider(
            color: Colors.grey,
            thickness: 2.0, // 默认是 0.0，可调大如 2.0、3.0、4.0
          ),
          _buildStatRow(
            'Balance',
            balance,
            balance >= 0 ? Colors.greenAccent : Colors.redAccent,
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
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
