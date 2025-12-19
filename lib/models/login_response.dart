// To parse this JSON data, do
//
//     final loginResponse = loginResponseFromJson(jsonString);

import 'dart:convert';

LoginResponse loginResponseFromJson(String str) =>
    LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
  final String id;
  final String username;
  final String email;
  final String fcm;
  final bool verification;
  final String phone;
  final bool phoneVerification;
  final String userType;
  final String profile;
  final String userToken;

  LoginResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.fcm,
    required this.verification,
    required this.phone,
    required this.phoneVerification,
    required this.userType,
    required this.profile,
    required this.userToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Backend hiện trả về dạng { status, code, data: {...user fields...}, userToken }
    // Trước đây code giả định các field nằm ở root. Ta chuẩn hoá để dùng được cả hai.
    final root = (json['data'] is Map) ? (json['data'] as Map) : json;
    return LoginResponse(
      id: (root["_id"] ?? '').toString(),
      username: (root["username"] ?? '').toString(),
      email: (root["email"] ?? '').toString(),
      fcm: (root["fcm"] ?? '').toString(),
      verification: _parseFlexibleBool(root["verification"]),
      phone: (root["phone"] ?? '').toString(),
      phoneVerification: _parseFlexibleBool(root["phoneVerification"]),
      userType: (root["userType"] ?? '').toString(),
      profile: (root["profile"] ?? '').toString(),
      userToken: (json["userToken"] ?? root["userToken"] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "username": username,
        "email": email,
        "fcm": fcm,
        "verification": verification,
        "phone": phone,
        "phoneVerification": phoneVerification,
        "userType": userType,
        "profile": profile,
        "userToken": userToken,
      };
}

// Hỗ trợ nhiều dạng biểu diễn boolean từ backend.
bool _parseFlexibleBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final s = value.trim().toLowerCase();
    if (s.isEmpty) return false;
    const trueValues = [
      'true',
      '1',
      'yes',
      'y',
      'verified',
      'đã xác minh',
      'da xac minh',
      'xac minh',
      'approved'
    ];
    return trueValues.contains(s);
  }
  return false;
}
