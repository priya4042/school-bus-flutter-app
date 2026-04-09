class Bus {
  final String id;
  final String busNumber;
  final String vehicleNumber;
  final String? model;
  final int capacity;
  final String? driverName;
  final String? driverPhone;
  final String? routeId;
  final String? routeName;
  final String status;
  final DateTime? createdAt;

  Bus({
    required this.id,
    required this.busNumber,
    required this.vehicleNumber,
    this.model,
    this.capacity = 40,
    this.driverName,
    this.driverPhone,
    this.routeId,
    this.routeName,
    this.status = 'idle',
    this.createdAt,
  });

  factory Bus.fromMap(Map<String, dynamic> map) {
    final routes = map['routes'];
    return Bus(
      id: map['id'] ?? '',
      busNumber: map['bus_number'] ?? '',
      vehicleNumber: map['vehicle_number'] ?? map['plate'] ?? '',
      model: map['model'],
      capacity: map['capacity'] ?? 40,
      driverName: map['driver_name'],
      driverPhone: map['driver_phone'],
      routeId: map['route_id'],
      routeName: routes != null ? routes['route_name'] : map['route_name'],
      status: _normalizeStatus(map['status']),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'bus_number': busNumber,
    'vehicle_number': vehicleNumber,
    'model': model,
    'capacity': capacity,
    'driver_name': driverName,
    'driver_phone': driverPhone,
    'route_id': routeId,
    'status': status.toUpperCase(),
  };

  static String _normalizeStatus(dynamic s) {
    if (s == null) return 'idle';
    final v = s.toString().toUpperCase();
    switch (v) {
      case 'ON_ROUTE':
      case 'ACTIVE':
        return 'active';
      case 'MAINTENANCE':
        return 'maintenance';
      default:
        return 'idle';
    }
  }

  bool get isActive => status == 'active';
}
