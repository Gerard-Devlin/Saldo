class Transaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String type;
  final String tag;
  final String note;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.tag,
    required this.note,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      tag: map['tag'],
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'tag': tag,
      'note': note,
    };
  }

  Transaction copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    String? type,
    String? tag,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      tag: tag ?? this.tag,
      note: note ?? this.note,
    );
  }
}
