// To parse this JSON data, do
//
//     final restaurantRequest = restaurantRequestFromJson(jsonString);

import 'dart:convert';

StoreRequest storeRequestFromJson(String str) =>
    StoreRequest.fromJson(json.decode(str));

String storeRequestToJson(StoreRequest data) => json.encode(data.toJson());

class StoreRequest {
  final String title;
  final String time;
  final String owner;
  final String code;
  final String logoUrl;
  final String imageUrl;
  final Coords coords;

  StoreRequest({
    required this.title,
    required this.time,
    required this.owner,
    required this.code,
    required this.logoUrl,
    required this.imageUrl,
    required this.coords,
  });

  factory StoreRequest.fromJson(Map<String, dynamic> json) => StoreRequest(
        title: json["title"],
        time: json["time"],
        owner: json["owner"],
        code: json["code"],
        logoUrl: json["logoUrl"],
        imageUrl: json["imageUrl"],
        coords: Coords.fromJson(json["coords"]),
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "time": time,
        "owner": owner,
        "code": code,
        "logoUrl": logoUrl,
        "imageUrl": imageUrl,
        "coords": coords.toJson(),
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
