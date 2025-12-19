// To parse this JSON data, do
//
//     final apiError = apiErrorFromJson(jsonString);

import 'dart:convert';

ApiError apiErrorFromJson(String str) {
  try {
    final decoded = json.decode(str);
    if (decoded is Map<String, dynamic>) {
      return ApiError.fromJson(decoded);
    }
    // Nếu backend trả về kiểu khác (List, số, chuỗi thuần) thì chuyển thành message
    return ApiError(status: false, message: str.toString());
  } catch (e) {
    // Chuỗi không phải JSON -> gói lại thành message
    return ApiError(status: false, message: str);
  }
}

String apiErrorToJson(ApiError data) => json.encode(data.toJson());

class ApiError {
  final bool status;
  final String message;

  ApiError({
    required this.status,
    required this.message,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        status: json["status"] == true,
        message: (json["message"] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
      };
}
