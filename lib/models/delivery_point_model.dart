class DeliveryPointModel {
  final String idDD;
  final String? ten;
  final String? vitri;
  final double? lat;
  final double? lng;

  DeliveryPointModel({
    required this.idDD,
    this.ten,
    this.vitri,
    this.lat,
    this.lng,
  });

  factory DeliveryPointModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPointModel(
      idDD: json['idDD'] ?? json['IdDD'] ?? json['d_DD'] ?? json['D_DD'] ?? '',
      ten: json['ten'] ?? json['TEN'],
      vitri: json['vitri'] ?? json['VITRI'],
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
    );
  }
}
