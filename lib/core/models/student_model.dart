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
    final routes = map['routes'];
    final buses = map['buses'];
    final profiles = map['profiles'];

    return Student(
      id: map['id'] ?? '',
      admissionNumber: map['admission_number'] ?? '',
      fullName: map['full_name'] ?? '',
      grade: map['grade'],
      section: map['section'],
      parentId: map['parent_id'],
      parentName: profiles != null ? profiles['full_name'] : map['parent_name'],
      parentPhone: profiles != null ? profiles['phone_number'] : map['parent_phone'],
      busId: map['bus_id'],
      routeId: map['route_id'],
      routeName: routes != null ? routes['route_name'] : map['route_name'],
      busNumber: buses != null ? buses['bus_number'] : map['bus_number'],
      busPlate: buses != null ? (buses['vehicle_number'] ?? buses['plate']) : map['bus_plate'],
      boardingPoint: map['boarding_point'],
      monthlyFee: (map['monthly_fee'] ?? 0).toDouble(),
      status: (map['status'] ?? 'ACTIVE').toString().toLowerCase(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
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
