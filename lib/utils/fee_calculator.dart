import '../core/models/monthly_due_model.dart';

class LedgerResult {
  final double lateFee;
  final double total;
  final bool isFineApplied;

  LedgerResult({
    required this.lateFee,
    required this.total,
    this.isFineApplied = false,
  });
}

class PaymentBundleItem {
  final MonthlyDue due;
  final double baseFee;
  final double lateFee;
  final double total;
  final String reason;

  PaymentBundleItem({
    required this.due,
    required this.baseFee,
    required this.lateFee,
    required this.total,
    required this.reason,
  });
}

class PaymentBundle {
  final List<String> dueIds;
  final double amount;
  final int monthsCount;
  final List<PaymentBundleItem> items;
  final double totalBaseAmount;
  final double totalLateFee;
  final bool hasArrears;
  final String explanation;

  PaymentBundle({
    required this.dueIds,
    required this.amount,
    required this.monthsCount,
    required this.items,
    required this.totalBaseAmount,
    required this.totalLateFee,
    required this.hasArrears,
    required this.explanation,
  });
}

class FeeCalculator {
  static LedgerResult calculateCurrentLedger(
    MonthlyDue due, {
    DateTime? referenceDate,
  }) {
    if (due.isPaid) {
      return LedgerResult(
        lateFee: due.lateFee,
        total: due.amount + due.lateFee - (due.discount ?? 0),
      );
    }

    final now = referenceDate ?? DateTime.now();
    final dueDate = due.dueDate;
    final finePerDay = due.finePerDay ?? 50.0;
    final fineAfterDays = due.fineAfterDays ?? 5;

    if (now.isBefore(dueDate) || now.isAtSameMomentAs(dueDate)) {
      return LedgerResult(lateFee: 0, total: due.amount - (due.discount ?? 0));
    }

    final daysLate = now.difference(dueDate).inDays;
    final penaltyDays = daysLate - fineAfterDays;

    if (penaltyDays <= 0) {
      return LedgerResult(lateFee: 0, total: due.amount - (due.discount ?? 0));
    }

    final lateFee = penaltyDays * finePerDay;
    final total = due.amount + lateFee - (due.discount ?? 0);

    return LedgerResult(lateFee: lateFee, total: total, isFineApplied: true);
  }

  static PaymentBundle buildPaymentBundle(
    MonthlyDue targetDue,
    List<MonthlyDue> allDues, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    // Filter unpaid dues for same student, sorted chronologically
    final unpaid = allDues
        .where((d) =>
            d.studentId == targetDue.studentId &&
            !d.isPaid &&
            (d.year < targetDue.year ||
                (d.year == targetDue.year && d.month <= targetDue.month)))
        .toList()
      ..sort((a, b) {
        final yearCmp = a.year.compareTo(b.year);
        return yearCmp != 0 ? yearCmp : a.month.compareTo(b.month);
      });

    final items = <PaymentBundleItem>[];
    double totalBase = 0;
    double totalLate = 0;

    for (final due in unpaid) {
      final ledger = calculateCurrentLedger(due, referenceDate: now);
      items.add(PaymentBundleItem(
        due: due,
        baseFee: due.amount,
        lateFee: ledger.lateFee,
        total: ledger.total,
        reason: due.id == targetDue.id ? 'Current month' : 'Arrears',
      ));
      totalBase += due.amount;
      totalLate += ledger.lateFee;
    }

    final totalAmount = totalBase + totalLate;
    final hasArrears = items.length > 1;

    String explanation = '';
    if (hasArrears) {
      explanation = '${items.length} months bundled (includes ${items.length - 1} month(s) of arrears)';
    }
    if (totalLate > 0) {
      explanation += explanation.isEmpty ? '' : '. ';
      explanation += 'Late fees: ₹${totalLate.toStringAsFixed(0)}';
    }

    return PaymentBundle(
      dueIds: items.map((i) => i.due.id).toList(),
      amount: totalAmount,
      monthsCount: items.length,
      items: items,
      totalBaseAmount: totalBase,
      totalLateFee: totalLate,
      hasArrears: hasArrears,
      explanation: explanation,
    );
  }

  static bool isMonthPayable(MonthlyDue targetDue, List<MonthlyDue> allDues) {
    final earlier = allDues.where((d) =>
        d.studentId == targetDue.studentId &&
        !d.isPaid &&
        (d.year < targetDue.year ||
            (d.year == targetDue.year && d.month < targetDue.month)));
    return earlier.isEmpty;
  }
}
