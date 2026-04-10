class MonthlyDue {
  final String id;
  final String studentId;
  final String? studentName;
  final String? admissionNumber;
  final int month;
  final int year;
  final double amount;
  final double lateFee;
  final double? discount;
  final double? finePerDay;
  final int? fineAfterDays;
  final DateTime dueDate;
  final DateTime? lastDate;
  final String status;
  final DateTime? paidAt;
  final String? transactionId;
  final DateTime? createdAt;

  MonthlyDue({
    required this.id,
    required this.studentId,
    this.studentName,
    this.admissionNumber,
    required this.month,
    required this.year,
    required this.amount,
    this.lateFee = 0,
    this.discount,
    this.finePerDay,
    this.fineAfterDays,
    required this.dueDate,
    this.lastDate,
    this.status = 'UNPAID',
    this.paidAt,
    this.transactionId,
    this.createdAt,
  });

  factory MonthlyDue.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? students;
    if (map['students'] is Map) {
      students = Map<String, dynamic>.from(map['students'] as Map);
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int parseInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    return MonthlyDue(
      id: (map['id'] ?? '').toString(),
      studentId: (map['student_id'] ?? '').toString(),
      studentName: students?['full_name']?.toString() ?? map['student_name']?.toString(),
      admissionNumber: students?['admission_number']?.toString() ?? map['admission_number']?.toString(),
      month: parseInt(map['month'], 1),
      year: parseInt(map['year'], DateTime.now().year),
      amount: parseDouble(map['amount']),
      lateFee: parseDouble(map['late_fee']),
      discount: map['discount'] != null ? parseDouble(map['discount']) : null,
      finePerDay: parseDouble(map['fine_per_day'] ?? 50),
      fineAfterDays: parseInt(map['fine_after_days'], 5),
      dueDate: DateTime.tryParse((map['due_date'] ?? '').toString()) ?? DateTime.now(),
      lastDate: map['last_date'] != null ? DateTime.tryParse(map['last_date'].toString()) : null,
      status: (map['status'] ?? 'UNPAID').toString().toUpperCase(),
      paidAt: map['paid_at'] != null ? DateTime.tryParse(map['paid_at'].toString()) : null,
      transactionId: map['transaction_id']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'student_id': studentId,
    'month': month,
    'year': year,
    'amount': amount,
    'late_fee': lateFee,
    'due_date': dueDate.toIso8601String().split('T')[0],
    if (lastDate != null) 'last_date': lastDate!.toIso8601String().split('T')[0],
    'fine_per_day': finePerDay,
    'fine_after_days': fineAfterDays,
    'status': status,
  };

  bool get isPaid => status == 'PAID';
  bool get isOverdue => status == 'OVERDUE' || (!isPaid && DateTime.now().isAfter(dueDate));
  bool get isPending => status == 'PENDING' || status == 'UNPAID';

  double get totalDue => amount + lateFee - (discount ?? 0);

  String get monthLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (month >= 1 && month <= 12) return '${months[month - 1]} $year';
    return '$month/$year';
  }

  String get fullMonthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (month >= 1 && month <= 12) return '${months[month - 1]} $year';
    return '$month/$year';
  }
}

class Receipt {
  final String id;
  final String dueId;
  final String receiptNo;
  final double amountPaid;
  final String paymentMethod;
  final String? transactionId;
  final String? generatedBy;
  final DateTime? createdAt;

  Receipt({
    required this.id,
    required this.dueId,
    required this.receiptNo,
    required this.amountPaid,
    this.paymentMethod = 'ONLINE',
    this.transactionId,
    this.generatedBy,
    this.createdAt,
  });

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] ?? '',
      dueId: map['due_id'] ?? '',
      receiptNo: map['receipt_no'] ?? '',
      amountPaid: (map['amount_paid'] ?? 0).toDouble(),
      paymentMethod: map['payment_method'] ?? 'ONLINE',
      transactionId: map['transaction_id'],
      generatedBy: map['generated_by'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }
}
