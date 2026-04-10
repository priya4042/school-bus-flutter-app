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

    // Pay only the selected month (not bundled). Each month is independently payable.
    final ledger = calculateCurrentLedger(targetDue, referenceDate: now);
    final items = <PaymentBundleItem>[
      PaymentBundleItem(
        due: targetDue,
        baseFee: targetDue.amount,
        lateFee: ledger.lateFee,
        total: ledger.total,
        reason: 'Selected month',
      ),
    ];
    final totalBase = targetDue.amount;
    final totalLate = ledger.lateFee;
    final totalAmount = totalBase + totalLate;
    const hasArrears = false;

    String explanation = '';
    if (totalLate > 0) {
      explanation = 'Late fees: ₹${totalLate.toStringAsFixed(0)}';
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

  /// Check if a month can be paid.
  /// Returns true if the month is unpaid (allows paying any unpaid month — admin
  /// may create yearly fees and parents should be able to pay any month).
  static bool isMonthPayable(MonthlyDue targetDue, List<MonthlyDue> allDues) {
    return !targetDue.isPaid;
  }
}
