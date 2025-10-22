// Order Model
class OrderModel {
  final String madon;
  final String? maloai;
  final DateTime ngaylap;
  final double tongtien;
  final String? bsXe;

  OrderModel({
    required this.madon,
    this.maloai,
    required this.ngaylap,
    required this.tongtien,
    this.bsXe,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      madon: json['madon'] ?? json['MADON'] ?? '',
      maloai: json['maloai'] ?? json['MALOAI'],
      ngaylap: DateTime.parse(json['ngaylap'] ?? json['NGAYLAP']),
      tongtien: (json['tongtien'] ?? json['TONGTIEN'] ?? 0).toDouble(),
      bsXe: json['bs_XE'] ?? json['BS_XE'],
    );
  }
}

// Vehicle Model
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

// Delivery Point Model
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

// Product Model
class ProductModel {
  final String mahh;
  final String? tenhh;
  final int sl;
  final String? maloai;

  ProductModel({required this.mahh, this.tenhh, required this.sl, this.maloai});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      mahh: json['mahh'] ?? json['MAHH'] ?? '',
      tenhh: json['tenhh'] ?? json['TENHH'],
      sl: json['sl'] ?? json['SL'] ?? 0,
      maloai: json['maloai'] ?? json['MALOAI'],
    );
  }
}

// Route Stop Model
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

// Route Model
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

// Delivery Model (for Driver)
class DeliveryModel {
  final String maDonHang;
  final String? bienSoXe;
  final String idDiemGiao;
  final String? tenDiemGiao;

  final String? diaChiGiao;
  final String trangThai;
  final DateTime? ngayGiaoDuKien;

  DeliveryModel({
    required this.maDonHang,
    this.bienSoXe,
    required this.idDiemGiao,
    this.tenDiemGiao,
    this.diaChiGiao,
    required this.trangThai,
    this.ngayGiaoDuKien,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      maDonHang: json['maDonHang'] ?? json['MaDonHang'] ?? '',
      bienSoXe: json['bienSoXe'] ?? json['BienSoXe'],
      idDiemGiao: json['idDiemGiao'] ?? json['IdDiemGiao'] ?? '',
      tenDiemGiao: json['tenDiemGiao'] ?? json['TenDiemGiao'],
      diaChiGiao: json['diaChiGiao'] ?? json['DiaChiGiao'],
      trangThai: json['trangThai'] ?? json['TrangThai'] ?? '',
      ngayGiaoDuKien: json['ngayGiaoDuKien'] != null
          ? DateTime.parse(json['ngayGiaoDuKien'])
          : null,
    );
  }
}
