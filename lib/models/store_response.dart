// To parse this JSON data, do
//
//     final restaurantResponse = restaurantResponseFromJson(jsonString);

import 'dart:convert';

StoreResponse storeResponseFromJson(String str) =>
    StoreResponse.fromJson(json.decode(str));

String storeResponseToJson(StoreResponse data) => json.encode(data.toJson());

class StoreResponse {
  final String id;
  final String title;
  final String time;
  final String imageUrl;
  final String owner;
  final String code;
  final bool isAvailable;
  final bool pickup;
  final bool delivery;
  final List<dynamic> appliances;
  final String logoUrl;
  final int rating;
  final String ratingCount;
  final String verification;
  final String verificationMessage;
  final Coords coords;
  final double earnings;

  StoreResponse({
    required this.id,
    required this.title,
    required this.time,
    required this.imageUrl,
    required this.owner,
    required this.code,
    required this.isAvailable,
    required this.pickup,
    required this.delivery,
    required this.appliances,
    required this.logoUrl,
    required this.rating,
    required this.ratingCount,
    required this.verification,
    required this.verificationMessage,
    required this.coords,
    required this.earnings,
  });

  factory StoreResponse.fromJson(Map<String, dynamic> json) => StoreResponse(
        id: (json["_id"] ?? "").toString(),
        title: (json["title"] ?? "").toString(),
        time: (json["time"] ?? "").toString(),
        imageUrl: (json["imageUrl"] ?? "").toString(),
        owner: (json["owner"] ?? "").toString(),
        code: (json["code"] ?? "").toString(),
        isAvailable: json["isAvailable"] is bool ? json["isAvailable"] : true,
        pickup: json["pickup"] is bool ? json["pickup"] : true,
        delivery: json["delivery"] is bool ? json["delivery"] : true,
        appliances: json["appliances"] != null
            ? List<dynamic>.from((json["appliances"] as List).map((x) => x))
            : [],
        logoUrl: (json["logoUrl"] ?? "").toString(),
        rating: (json["rating"] is int)
            ? json["rating"]
            : (json["rating"] is num ? (json["rating"] as num).round() : 3),
        // Trường ratingCount đôi khi backend gửi int -> ép chuỗi
        ratingCount: (json["ratingCount"] ?? "0").toString(),
        verification: (json["verification"] ?? "Đang chờ duyệt").toString(),
        verificationMessage: (json["verificationMessage"] ??
                "Cửa hàng của bạn đang được xem xét")
            .toString(),
        coords: json["coords"] is Map
            ? Coords.fromJson(json["coords"])
            : Coords.empty(),
        earnings: _toDouble(json["earnings"]),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "title": title,
        "time": time,
        "imageUrl": imageUrl,
        "owner": owner,
        "code": code,
        "isAvailable": isAvailable,
        "pickup": pickup,
        "delivery": delivery,
        "appliances": List<dynamic>.from(appliances.map((x) => x)),
        "logoUrl": logoUrl,
        "rating": rating,
        "ratingCount": ratingCount,
        "verification": verification,
        "verificationMessage": verificationMessage,
        "coords": coords.toJson(),
        "earnings": earnings,
      };
}

class Coords {
  final String id;
  final double latitude;
  final double longitude;
  final String address;
  final String title;

  Coords({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.title,
  });

  factory Coords.fromJson(Map<String, dynamic> json) => Coords(
        id: (json["id"] ?? "").toString(),
        latitude: _toDouble(json["latitude"]),
        longitude: _toDouble(json["longitude"]),
        address: (json["address"] ?? "").toString(),
        title: (json["title"] ?? "").toString(),
      );

  factory Coords.empty() => Coords(
        id: "",
        latitude: 0,
        longitude: 0,
        address: "",
        title: "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "title": title,
      };
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) {
    return double.tryParse(v) ?? 0.0;
  }
  return 0.0;
}
