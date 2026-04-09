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
    final students = map['students'];
    return Attendance(
      id: map['id'] ?? '',
      studentId: map['student_id'] ?? '',
      studentName: students != null ? students['full_name'] : map['student_name'],
      admissionNumber: students != null ? students['admission_number'] : map['admission_number'],
      busId: map['bus_id'],
      status: (map['status'] ?? 'PRESENT').toString().toUpperCase(),
      type: (map['type'] ?? 'PICKUP').toString().toUpperCase(),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
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
