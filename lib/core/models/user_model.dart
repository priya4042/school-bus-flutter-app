enum UserRole { superAdmin, admin, parent, driver }

enum PaymentStatus { paid, unpaid, overdue, partial, pending }

enum PaymentMethod { cash, online, upi, card, netbanking }

enum BusStatus { onRoute, idle, maintenance }

enum StudentStatus { active, inactive, graduated }

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phoneNumber;
  final String? admissionNumber;
  final String? avatarUrl;
  final UserPreferences preferences;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.admissionNumber,
    this.avatarUrl,
    UserPreferences? preferences,
    this.createdAt,
  }) : preferences = preferences ?? UserPreferences();

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? map['fullName'] ?? '',
      role: _parseRole(map['role']),
      phoneNumber: map['phone_number'] ?? map['phoneNumber'],
      admissionNumber: map['admission_number'] ?? map['admissionNumber'],
      avatarUrl: map['avatar_url'],
      preferences: UserPreferences.fromMap(map['preferences'] ?? {}),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role.name.toUpperCase(),
    'phone_number': phoneNumber,
    'admission_number': admissionNumber,
    'avatar_url': avatarUrl,
    'preferences': preferences.toMap(),
  };

  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isParent => role == UserRole.parent;
  bool get isSuperAdmin => role == UserRole.superAdmin;

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.parent;
    final r = role.toString().toUpperCase();
    switch (r) {
      case 'SUPER_ADMIN': return UserRole.superAdmin;
      case 'ADMIN': return UserRole.admin;
      case 'PARENT': return UserRole.parent;
      case 'DRIVER': return UserRole.driver;
      default: return UserRole.parent;
    }
  }
}

class UserPreferences {
  final bool sms;
  final bool email;
  final bool push;
  final bool? camera;
  final bool? tracking;

  UserPreferences({
    this.sms = true,
    this.email = true,
    this.push = true,
    this.camera,
    this.tracking,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      sms: map['sms'] ?? true,
      email: map['email'] ?? true,
      push: map['push'] ?? true,
      camera: map['camera'],
      tracking: map['tracking'],
    );
  }

  Map<String, dynamic> toMap() => {
    'sms': sms,
    'email': email,
    'push': push,
    if (camera != null) 'camera': camera,
    if (tracking != null) 'tracking': tracking,
  };
}
