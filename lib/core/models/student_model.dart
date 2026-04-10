class Student {
  final String id;
  final String admissionNumber;
  final String fullName;
  final String? grade;
  final String? section;
  final String? parentId;
  final String? parentName;
  final String? parentPhone;
  final String? busId;
  final String? routeId;
  final String? routeName;
  final String? busNumber;
  final String? busPlate;
  final String? boardingPoint;
  final double monthlyFee;
  final String status;
  final DateTime? createdAt;

  Student({
    required this.id,
    required this.admissionNumber,
    required this.fullName,
    this.grade,
    this.section,
    this.parentId,
    this.parentName,
    this.parentPhone,
    this.busId,
    this.routeId,
    this.routeName,
    this.busNumber,
    this.busPlate,
    this.boardingPoint,
    this.monthlyFee = 0,
    this.status = 'active',
    this.createdAt,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    // Safely cast joined relations - they can be null, Map, or List
    Map<String, dynamic>? safeMap(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is List && v.isNotEmpty && v.first is Map) {
        return Map<String, dynamic>.from(v.first as Map);
      }
      return null;
    }

    final routes = safeMap(map['routes']);
    final buses = safeMap(map['buses']);
    final profiles = safeMap(map['profiles']);

    return Student(
      id: (map['id'] ?? '').toString(),
      admissionNumber: (map['admission_number'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      grade: map['grade']?.toString(),
      section: map['section']?.toString(),
      parentId: map['parent_id']?.toString(),
      parentName: profiles?['full_name']?.toString() ?? map['parent_name']?.toString(),
      parentPhone: profiles?['phone_number']?.toString() ?? map['parent_phone']?.toString(),
      busId: map['bus_id']?.toString(),
      routeId: map['route_id']?.toString(),
      routeName: routes?['route_name']?.toString() ?? map['route_name']?.toString(),
      busNumber: buses?['bus_number']?.toString() ?? map['bus_number']?.toString(),
      busPlate: buses?['vehicle_number']?.toString() ?? buses?['plate']?.toString() ?? map['bus_plate']?.toString(),
      boardingPoint: map['boarding_point']?.toString(),
      monthlyFee: (map['monthly_fee'] is num) ? (map['monthly_fee'] as num).toDouble() : 0.0,
      status: (map['status'] ?? 'ACTIVE').toString().toLowerCase(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'admission_number': admissionNumber,
    'full_name': fullName,
    'grade': grade,
    'section': section,
    'parent_id': parentId,
    'bus_id': busId,
    'route_id': routeId,
    'boarding_point': boardingPoint,
    'monthly_fee': monthlyFee,
    'status': status.toUpperCase(),
  };

  bool get isActive => status.toLowerCase() == 'active';

  String get displayGrade => grade != null && section != null
      ? '$grade - $section'
      : grade ?? section ?? 'N/A';
}
