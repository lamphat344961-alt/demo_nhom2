// Model này dựa trên 'CtDonHangReadDto' từ Swagger
class OrderDetailReadModel {
  final String madon;
  final String mahh;
  final double dongia;
  final int sl;
  // Thêm các trường này để hiển thị thông tin dễ dàng hơn
  final String? tenhh;
  final String? maloai;

  OrderDetailReadModel({
    required this.madon,
    required this.mahh,
    required this.dongia,
    required this.sl,
    this.tenhh,
    this.maloai,
  });

  factory OrderDetailReadModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailReadModel(
      madon: json['madon'] ?? '',
      mahh: json['mahh'] ?? '',
      dongia: (json['dongia'] ?? 0).toDouble(),
      sl: (json['sl'] ?? 0) as int,
      // Giả sử API của bạn trả về thông tin sản phẩm lồng nhau
      tenhh: json['hangHoa'] != null ? json['hangHoa']['tenhh'] : null,
      maloai: json['hangHoa'] != null ? json['hangHoa']['maloai'] : null,
    );
  }

  // Nếu API không trả về lồng nhau, bạn có thể cần một factory khác
  // hoặc xử lý join dữ liệu ở frontend
}

// Model này dựa trên 'CtDonHangCreateDto' từ Swagger
class OrderDetailCreateModel {
  final String madon;
  final String mahh;
  final double dongia;
  final int sl;

  OrderDetailCreateModel({
    required this.madon,
    required this.mahh,
    required this.dongia,
    required this.sl,
  });

  Map<String, dynamic> toJson() {
    return {'madon': madon, 'mahh': mahh, 'dongia': dongia, 'sl': sl};
  }
}
