import 'package:flutter/material.dart';
import '../database/transaction_db.dart';
import '../models/transaction.dart' as model;
import 'package:intl/intl.dart';
import 'transaction_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<model.Transaction> _allTransactions = [];
  List<model.Transaction> _searchResults = [];
  String _selectedAccount = 'All'; // New state for account filter
  DateTime? _selectedFilterDate; // New state for date filter

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '￥',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final txs = await TransactionDB.instance.readAll();
    setState(() {
      _allTransactions = txs;
      _filterTransactions(_searchController.text); // Apply filters after loading
    });
  }

  void _onSearchChanged() {
    _filterTransactions(_searchController.text);
  }

  void _filterTransactions(String query) {
    final filtered = _allTransactions.where((transaction) {
      final titleLower = transaction.title.toLowerCase();
      final accountLower = transaction.account.toLowerCase();
      final dateLower = DateFormat('yyyy-MM-dd').format(transaction.date).toLowerCase();
      final searchLower = query.toLowerCase();

      bool matchesSearch = titleLower.contains(searchLower) ||
          accountLower.contains(searchLower) ||
          dateLower.contains(searchLower);

      bool matchesAccount = _selectedAccount == 'All' ||
          transaction.account == _selectedAccount;

      bool matchesDate = _selectedFilterDate == null ||
          (transaction.date.year == _selectedFilterDate!.year &&
           transaction.date.month == _selectedFilterDate!.month &&
           transaction.date.day == _selectedFilterDate!.day);

      return matchesSearch && matchesAccount && matchesDate;
    }).toList();

    setState(() {
      _searchResults = filtered;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedFilterDate) {
      setState(() {
        _selectedFilterDate = picked;
        _filterTransactions(_searchController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        scrolledUnderElevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAccount,
                    dropdownColor: Colors.grey[850],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Accounts')),
                      DropdownMenuItem(value: 'Alipay', child: Text('Alipay')),
                      DropdownMenuItem(value: 'WeChat', child: Text('WeChat')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAccount = value!;
                        _filterTransactions(_searchController.text);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedFilterDate == null
                                ? 'Select Date'
                                : DateFormat('yyyy-MM-dd').format(_selectedFilterDate!),
                            style: const TextStyle(color: Colors.white),
                          ),
                          if (_selectedFilterDate != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFilterDate = null;
                                  _filterTransactions(_searchController.text);
                                });
                              },
                              child: const Icon(Icons.clear, color: Colors.white54, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildTransactionList(_searchResults),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<model.Transaction> txs) {
    if (txs.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Text(
          'No matching transactions found.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    } else if (txs.isEmpty) {
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
        return GestureDetector(
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
      },
    );
  }
} 