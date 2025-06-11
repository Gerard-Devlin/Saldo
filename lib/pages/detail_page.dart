import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart' as model;
import '../database/transaction_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'alipay_detail_page.dart';
import 'wechat_detail_page.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List<model.Transaction> _transactions = [];
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final savedYear = prefs.getInt('selected_year');
    final savedMonth = prefs.getInt('selected_month');

    final txs = await TransactionDB.instance.readAll();

    setState(() {
      _selectedYear = savedYear ?? DateTime.now().year;
      _selectedMonth = savedMonth ?? DateTime.now().month;
      _transactions = txs;
    });
  }

  double get totalIncome => _transactions
      .where((t) => _inSelectedMonth(t.date) && t.amount > 0)
      .fold(0.0, (a, b) => a + b.amount);

  double get totalExpense => _transactions
      .where((t) => _inSelectedMonth(t.date) && t.amount < 0)
      .fold(0.0, (a, b) => a + b.amount.abs());

  double get balance => totalIncome - totalExpense;

  double get wechatBalance => _transactions
      .where((t) => t.account == 'WeChat')
      .fold(0.0, (a, b) => a + b.amount);

  double get alipayBalance => _transactions
      .where((t) => t.account == 'Alipay')
      .fold(0.0, (a, b) => a + b.amount);

  bool _inSelectedMonth(DateTime date) {
    return date.year == _selectedYear && date.month == _selectedMonth;
  }

  Map<int, double> get dailyExpenses {
    final map = <int, double>{};
    for (final t in _transactions) {
      if (_inSelectedMonth(t.date)) {
        final day = t.date.day;
        map[day] = (map[day] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Map<int, double> get monthlyTotals {
    final map = <int, double>{};
    for (final t in _transactions) {
      if (t.date.year == _selectedYear) {
        final m = t.date.month;
        map[m] = (map[m] ?? 0) + t.amount;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    final maxExpense = dailyExpenses.values.isEmpty
        ? 1.0
        : dailyExpenses.values.reduce(max).toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 10, top: 15),
          child: Text(
            "📊",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontFamily: 'cursive',
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.black,
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
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(100),
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
                      onChanged: (val) async {
                        if (val != null) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('selected_month', val);
                          setState(() => _selectedMonth = val);
                        }
                      },
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
                      onChanged: (val) async {
                        if (val != null) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('selected_year', val);
                          setState(() => _selectedYear = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMonthlyReportCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAccountCard(
                  'Alipay',
                  alipayBalance,
                  FontAwesomeIcons.alipay,
                ),
                const SizedBox(width: 16),
                _buildAccountCard(
                  'WeChat',
                  wechatBalance,
                  FontAwesomeIcons.weixin,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCalendarHeatmap(daysInMonth, firstWeekday, maxExpense),
            const SizedBox(height: 16),
            _buildMonthlyBarChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(String label, double value, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (label == 'Alipay') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AlipayDetailPage(),
              ),
            );
          } else if (label == 'WeChat') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WechatDetailPage(),
              ),
            );
          }
        },
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: label == 'WeChat'
                      ? const Color(0xFF07C160)
                      : const Color(0xFF1677FF),
                ),
                const SizedBox(height: 8),
                Text(
                  '$label',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '¥${value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeatmap(
    int daysInMonth,
    int firstWeekday,
    double maxExpense,
  ) {
    final maxAmount = dailyExpenses.values.isEmpty
        ? 1.0
        : dailyExpenses.values.map((e) => e.abs()).reduce(max);
    final minAmount = dailyExpenses.values.isEmpty
        ? 0.0
        : dailyExpenses.values.map((e) => e.abs()).reduce(min);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅  Monthly Overview',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + (firstWeekday - 1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) return const SizedBox();

              final day = index - (firstWeekday - 1) + 1;
              final amount = dailyExpenses[day] ?? 0;
              final isIncome = amount >= 0;

              final color = _colorForAmount(amount, maxAmount, minAmount);

              return Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: amount != 0 ? Colors.white : Colors.grey,
                      ),
                    ),
                    if (amount != 0)
                      Text(
                        '¥${amount.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                  ],
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
    );
  }

  Widget _buildMonthlyBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💴  Yearly Overview',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.8,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final monthIndex = value.toInt();
                        if (monthIndex < 0 || monthIndex > 11)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat.MMM().format(
                              DateTime(0, monthIndex + 1),
                            ),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 30),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) {
                  final value = (monthlyTotals[i + 1] ?? 0).toDouble();
                  final isIncome = value >= 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: value.abs(),
                        width: 12,
                        color: isIncome ? Colors.greenAccent : Colors.redAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
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
          Divider(color: Colors.grey[800], thickness: 1.5),
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
            '¥${amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

Color _colorForAmount(double amount, double maxAmount, double minAmount) {
  if (amount == 0) return Colors.grey[850]!;

  final isIncome = amount > 0;
  final normalizedAmount = (amount.abs() - minAmount) / (maxAmount - minAmount);
  
  if (isIncome) {
    if (normalizedAmount <= 0.25) {
      return Color.lerp(Colors.green[100], Colors.green[300], normalizedAmount * 4)!;
    } else if (normalizedAmount <= 0.5) {
      return Color.lerp(Colors.green[300], Colors.green[500], (normalizedAmount - 0.25) * 4)!;
    } else if (normalizedAmount <= 0.75) {
      return Color.lerp(Colors.green[500], Colors.green[700], (normalizedAmount - 0.5) * 4)!;
    } else {
      return Color.lerp(Colors.green[700], Colors.green[900], (normalizedAmount - 0.75) * 4)!;
    }
  } else {
    if (normalizedAmount <= 0.25) {
      return Color.lerp(Colors.red[100], Colors.red[300], normalizedAmount * 4)!;
    } else if (normalizedAmount <= 0.5) {
      return Color.lerp(Colors.red[300], Colors.red[500], (normalizedAmount - 0.25) * 4)!;
    } else if (normalizedAmount <= 0.75) {
      return Color.lerp(Colors.red[500], Colors.red[700], (normalizedAmount - 0.5) * 4)!;
    } else {
      return Color.lerp(Colors.red[700], Colors.red[900], (normalizedAmount - 0.75) * 4)!;
    }
  }
}
