class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'INFO',
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: (map['type'] ?? 'INFO').toString().toUpperCase(),
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'title': title,
    'message': message,
    'type': type,
    'is_read': isRead,
  };

  bool get isFee => type == 'FEE_DUE';
  bool get isPayment => type == 'PAYMENT_SUCCESS';
  bool get isBusUpdate => type == 'BUS_UPDATE';
  bool get isWarning => type == 'WARNING';
}
