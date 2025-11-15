// To parse this JSON data, do
//
//     final appliancessModel = appliancessModelFromJson(jsonString);

import 'dart:convert';

import 'package:appliances_flutter/models/add_appliances_models.dart';

List<AppliancessModel> appliancessModelFromJson(String str) =>
    List<AppliancessModel>.from(
        json.decode(str).map((x) => AppliancessModel.fromJson(x)));

String appliancessModelToJson(List<AppliancessModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AppliancessModel {
  final String id;
  final String title;
  final List<String> appliancesTags;
  final List<String> appliancesType;
  final String code;
  final bool isAvailable;
  final String store;
  final double rating;
  final String ratingCount;
  final String description;
  final double price;
  final List<Additive> additives;
  final List<String> imageUrl;
  final int v;
  final String category;
  final String time;

  AppliancessModel({
    required this.id,
    required this.title,
    required this.appliancesTags,
    required this.appliancesType,
    required this.code,
    required this.isAvailable,
    required this.store,
    required this.rating,
    required this.ratingCount,
    required this.description,
    required this.price,
    required this.additives,
    required this.imageUrl,
    required this.v,
    required this.category,
    required this.time,
  });

  factory AppliancessModel.fromJson(Map<String, dynamic> json) =>
      AppliancessModel(
        id: json["_id"]?.toString() ?? "",
        title: json["title"]?.toString() ?? "",
        appliancesTags: json["appliancesTags"] != null
            ? List<String>.from(json["appliancesTags"].map((x) => x.toString()))
            : [],
        appliancesType: json["appliancesType"] != null
            ? List<String>.from(json["appliancesType"].map((x) => x.toString()))
            : [],
        code: json["code"]?.toString() ?? "",
        isAvailable: json["isAvailable"] ?? true,
        store: json["store"]?.toString() ?? "",
        rating: (json["rating"] is int)
            ? (json["rating"] as int).toDouble()
            : (json["rating"]?.toDouble() ?? 0.0),
        ratingCount: json["ratingCount"]?.toString() ?? "0",
        description: json["description"]?.toString() ?? "",
        price: (json["price"] is int)
            ? (json["price"] as int).toDouble()
            : (json["price"]?.toDouble() ?? 0.0),
        additives: json["additives"] != null
            ? List<Additive>.from(
                json["additives"].map((x) => Additive.fromJson(x)))
            : [],
        imageUrl: json["imageUrl"] != null
            ? List<String>.from(json["imageUrl"].map((x) => x.toString()))
            : [],
        v: json["__v"] ?? 0,
        category: json["category"]?.toString() ?? "",
        time: json["time"]?.toString() ?? "",
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "title": title,
        "appliancesTags": List<dynamic>.from(appliancesTags.map((x) => x)),
        "appliancesType": List<dynamic>.from(appliancesType.map((x) => x)),
        "code": code,
        "isAvailable": isAvailable,
        "store": store,
        "rating": rating,
        "ratingCount": ratingCount,
        "description": description,
        "price": price,
        "additives": List<dynamic>.from(additives.map((x) => x.toJson())),
        "imageUrl": List<dynamic>.from(imageUrl.map((x) => x)),
        "__v": v,
        "category": category,
        "time": time,
      };
}
