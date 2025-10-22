class RouteStopModel {
  final int pointId;
  final String name;
  final double lat;
  final double lng;
  final int etaEpoch;
  final String etaIso;
  final String polyline;

  RouteStopModel({
    required this.pointId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.etaEpoch,
    required this.etaIso,
    required this.polyline,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      pointId: json['pointId'] ?? 0,
      name: json['name'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      etaEpoch: json['etaEpoch'] ?? 0,
      etaIso: json['etaIso'] ?? '',
      polyline: json['polyline'] ?? '',
    );
  }
}

class RouteModel {
  final int routeId;
  final List<RouteStopModel> stops;
  final int totalSeconds;
  final String readableTotal;

  RouteModel({
    required this.routeId,
    required this.stops,
    required this.totalSeconds,
    required this.readableTotal,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      routeId: json['routeId'] ?? 0,
      stops:
          (json['stops'] as List?)
              ?.map((s) => RouteStopModel.fromJson(s))
              .toList() ??
          [],
      totalSeconds: json['totalSeconds'] ?? 0,
      readableTotal: json['readableTotal'] ?? '',
    );
  }
}
