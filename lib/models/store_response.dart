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
        id: json["_id"] ?? "",
        title: json["title"] ?? "",
        time: json["time"] ?? "",
        imageUrl: json["imageUrl"] ?? "",
        owner: json["owner"] ?? "",
        code: json["code"] ?? "",
        isAvailable: json["isAvailable"] ?? true,
        pickup: json["pickup"] ?? true,
        delivery: json["delivery"] ?? true,
        appliances: json["appliances"] != null
            ? List<dynamic>.from(json["appliances"].map((x) => x))
            : [],
        logoUrl: json["logoUrl"] ?? "",
        rating: json["rating"] ?? 3,
        ratingCount: json["ratingCount"] ?? "0",
        verification: json["verification"] ?? "Đang chờ duyệt",
        verificationMessage:
            json["verificationMessage"] ?? "Cửa hàng của bạn đang được xem xét",
        coords: Coords.fromJson(json["coords"]),
        earnings: json["earnings"]?.toDouble() ?? 0.0,
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
        id: json["id"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        address: json["address"],
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "title": title,
      };
}
