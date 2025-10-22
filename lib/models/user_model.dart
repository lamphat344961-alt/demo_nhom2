class UserModel {
  final int userId;
  final String username;
  final String fullName;
  final String? phoneNumber;
  final String? cccd;

  UserModel({
    required this.userId,
    required this.username,
    required this.fullName,
    this.phoneNumber,
    this.cccd,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? json['UserId'] ?? 0,
      username: json['username'] ?? json['Username'] ?? '',
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'],
      cccd: json['cccd'] ?? json['CCCD'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'cccd': cccd,
    };
  }
}
