class ProductModel {
  final String mahh;
  final String? tenhh;
  final int sl;
  final String? maloai;

  ProductModel({required this.mahh, this.tenhh, required this.sl, this.maloai});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawSl = json['sl'] ?? json['SL'] ?? 0;
    final parsedSl = rawSl is int ? rawSl : int.tryParse(rawSl.toString()) ?? 0;
    return ProductModel(
      mahh: json['mahh'] ?? json['MAHH'] ?? '',
      tenhh: json['tenhh'] ?? json['TENHH'],
      sl: parsedSl,
      maloai: json['maloai'] ?? json['MALOAI'],
    );
  }
}
