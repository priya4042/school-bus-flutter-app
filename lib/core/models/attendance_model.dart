class Attendance {
  final String id;
  final String studentId;
  final String? studentName;
  final String? admissionNumber;
  final String? busId;
  final String status;
  final String type;
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.studentId,
    this.studentName,
    this.admissionNumber,
    this.busId,
    this.status = 'PRESENT',
    this.type = 'PICKUP',
    required this.createdAt,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? students;
    if (map['students'] is Map) {
      students = Map<String, dynamic>.from(map['students'] as Map);
    }
    return Attendance(
      id: (map['id'] ?? '').toString(),
      studentId: (map['student_id'] ?? '').toString(),
      studentName: students?['full_name']?.toString() ?? map['student_name']?.toString(),
      admissionNumber: students?['admission_number']?.toString() ?? map['admission_number']?.toString(),
      busId: map['bus_id']?.toString(),
      status: (map['status'] ?? 'PRESENT').toString().toUpperCase(),
      type: (map['type'] ?? 'PICKUP').toString().toUpperCase(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'student_id': studentId,
    'bus_id': busId,
    'status': status,
    'type': type,
  };

  bool get isPresent => status == 'PRESENT';
  bool get isPickup => type == 'PICKUP';
}
