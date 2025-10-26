class UserModel {
  final int userId;
  final String username;
  final String fullName;
  final String? phoneNumber;
  final String? cccd;
  final String? nfcCardId;
  final int score;

  UserModel({
    required this.userId,
    required this.username,
    required this.fullName,
    this.phoneNumber,
    this.cccd,
    this.nfcCardId, // 🆕 THÊM MỚI
    this.score = 0, // 🆕 THÊM MỚI
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? json['UserId'] ?? 0,
      username: json['username'] ?? json['Username'] ?? '',
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'],
      cccd: json['cccd'] ?? json['CCCD'],
      nfcCardId: json['nfcCardId'] ?? json['NfcCardId'], // 🆕 THÊM MỚI
      score: json['score'] ?? json['Score'] ?? 0, // 🆕 THÊM MỚI
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'cccd': cccd,
      'nfcCardId': nfcCardId, // 🆕 THÊM MỚI
      'score': score, // 🆕 THÊM MỚI
    };
  }
}
