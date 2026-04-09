class BusRoute {
  final String id;
  final String routeName;
  final String code;
  final double? baseFee;
  final double? distanceKm;
  final String? startPoint;
  final String? endPoint;
  final bool isActive;
  final DateTime? createdAt;

  BusRoute({
    required this.id,
    required this.routeName,
    required this.code,
    this.baseFee,
    this.distanceKm,
    this.startPoint,
    this.endPoint,
    this.isActive = true,
    this.createdAt,
  });

  factory BusRoute.fromMap(Map<String, dynamic> map) {
    return BusRoute(
      id: map['id'] ?? '',
      routeName: map['route_name'] ?? '',
      code: map['code'] ?? '',
      baseFee: map['base_fee']?.toDouble(),
      distanceKm: map['distance_km']?.toDouble(),
      startPoint: map['start_point'],
      endPoint: map['end_point'],
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'route_name': routeName,
    'code': code,
    'base_fee': baseFee,
    'distance_km': distanceKm,
    'start_point': startPoint,
    'end_point': endPoint,
    'is_active': isActive,
  };
}
