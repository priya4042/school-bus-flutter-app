import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  static String currencyFull(double amount) {
    final f = NumberFormat('#,##,##0', 'en_IN');
    return '₹${f.format(amount)}';
  }

  static String date(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String dateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  static String dateShort(DateTime dt) {
    return DateFormat('dd MMM').format(dt);
  }

  static String timeOnly(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  static String monthYear(int month, int year) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (month >= 1 && month <= 12) return '${months[month - 1]} $year';
    return '$month/$year';
  }

  static String monthShort(int month, int year) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (month >= 1 && month <= 12) return '${months[month - 1]} $year';
    return '$month/$year';
  }

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(dt);
  }

  static String statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PAID': return 'Paid';
      case 'UNPAID': return 'Unpaid';
      case 'OVERDUE': return 'Overdue';
      case 'PARTIAL': return 'Partial';
      case 'PENDING': return 'Pending';
      default: return status;
    }
  }
}
