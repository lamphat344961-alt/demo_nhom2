class VehicleModel {
  final String bsXe;
  final String? tenxe;
  final String? ttXe;
  final int? userId;
  final String? driverFullName;

  VehicleModel({
    required this.bsXe,
    this.tenxe,
    this.ttXe,
    this.userId,
    this.driverFullName,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {

    return VehicleModel(
      bsXe: json['bS_XE'] ?? '',
      tenxe: json['tenxe'],
      ttXe: json['tT_XE'],
      userId: json['userId'],
      driverFullName: json['driverFullName'],
    );
  }
}