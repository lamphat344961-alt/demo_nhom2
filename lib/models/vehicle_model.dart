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
      bsXe: json['bs_XE'] ?? json['BS_XE'] ?? '',
      tenxe: json['tenxe'] ?? json['TENXE'],
      ttXe: json['tt_XE'] ?? json['TT_XE'],
      userId: json['userId'] ?? json['UserId'],
      driverFullName: json['driverFullName'] ?? json['DriverFullName'],
    );
  }
}
