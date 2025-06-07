import 'package:flutter/material.dart';
import '../models/transaction.dart' as model;
import '../database/transaction_db.dart';

class AddTransactionPage extends StatefulWidget {
  final model.Transaction? transaction;
  const AddTransactionPage({super.key, this.transaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0;
  String _type = 'Income';
  DateTime _selectedDate = DateTime.now();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _title = t.title;
      _amount = t.amount.abs();
      _type = t.amount >= 0 ? 'Income' : 'Expense';
      _selectedDate = t.date;
      _titleController.text = t.title;
      _amountController.text = t.amount.abs().toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final t = model.Transaction(
        id: widget.transaction?.id,
        title: _title,
        amount: _type == 'Income' ? _amount : -_amount,
        date: _selectedDate,
        type: _type,
        tag: '-',
        note: '-',
      );

      if (widget.transaction == null) {
        await TransactionDB.instance.create(t);
      } else {
        await TransactionDB.instance.update(t);
      }

      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteTransaction() async {
    if (widget.transaction == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this transaction?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TransactionDB.instance.delete(widget.transaction!.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'New Transaction' : 'Edit Transaction'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              Text(
                'Fill in transaction info',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color.onBackground),
              ),
              const SizedBox(height: 16),

              _buildSectionLabel('Purpose'),
              _buildInputField(
                controller: _titleController,
                hintText: 'e.g. Grocery, Salary...',
                icon: Icons.description,
                validator: (val) =>
                val == null || val.trim().isEmpty ? 'Enter a title' : null,
                onSaved: (val) => _title = val!.trim(),
              ),

              const SizedBox(height: 16),
              _buildSectionLabel('Amount'),
              _buildInputField(
                controller: _amountController,
                hintText: 'e.g. 100.00',
                icon: Icons.attach_money,
                inputType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  final parsed = double.tryParse(val ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
                onSaved: (val) =>
                _amount = double.tryParse(val ?? '0')?.abs() ?? 0,
              ),

              const SizedBox(height: 16),
              _buildSectionLabel('Date'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white54),
                          const SizedBox(width: 12),
                          Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const Icon(Icons.edit_calendar, color: Colors.white30),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _buildSectionLabel('Type'),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  value: _type,
                  icon: const Icon(Icons.arrow_drop_down),
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: const [
                    DropdownMenuItem(value: 'Income', child: Text('Income')),
                    DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                  ],
                  onChanged: (val) => setState(() => _type = val ?? 'Income'),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: Icon(widget.transaction == null ? Icons.add : Icons.save),
                label: Text(widget.transaction == null ? 'Add Transaction' : 'Update Transaction'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: color.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),

              if (widget.transaction != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _deleteTransaction,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  label: const Text('Delete Transaction'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[500],
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    TextInputType? inputType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}
