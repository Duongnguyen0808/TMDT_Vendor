// To parse this JSON data, do
//
//     final addappliancessModel = addappliancessModelFromJson(jsonString);

import 'dart:convert';

AddAppliancessModel addAppliancessModelFromJson(String str) =>
    AddAppliancessModel.fromJson(json.decode(str));

String addAppliancessModelToJson(AddAppliancessModel data) =>
    json.encode(data.toJson());

class AddAppliancessModel {
  final String title;
  final List<String> appliancesTags;
  final List<String> appliancesType;
  final String code;
  final String category;
  final String time;
  final bool isAvailable;
  final String store;
  final String description;
  final double price;
  final List<Additive> additives;
  final List<String> imageUrl;

  AddAppliancessModel({
    required this.title,
    required this.appliancesTags,
    required this.appliancesType,
    required this.code,
    required this.category,
    required this.time,
    required this.isAvailable,
    required this.store,
    required this.description,
    required this.price,
    required this.additives,
    required this.imageUrl,
  });

  factory AddAppliancessModel.fromJson(Map<String, dynamic> json) =>
      AddAppliancessModel(
        title: json["title"]?.toString() ?? "",
        appliancesTags: json["appliancesTags"] != null
            ? List<String>.from(json["appliancesTags"].map((x) => x.toString()))
            : [],
        appliancesType: json["appliancesType"] != null
            ? List<String>.from(json["appliancesType"].map((x) => x.toString()))
            : [],
        code: json["code"]?.toString() ?? "",
        category: json["category"]?.toString() ?? "",
        time: json["time"]?.toString() ?? "",
        isAvailable: json["isAvailable"] ?? true,
        store: json["store"]?.toString() ?? "",
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
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "appliancesTags": List<dynamic>.from(appliancesTags.map((x) => x)),
        "appliancesType": List<dynamic>.from(appliancesType.map((x) => x)),
        "code": code,
        "category": category,
        "time": time,
        "isAvailable": isAvailable,
        "store": store,
        "description": description,
        "price": price,
        "additives": List<dynamic>.from(additives.map((x) => x.toJson())),
        "imageUrl": List<dynamic>.from(imageUrl.map((x) => x)),
      };
}

class Additive {
  final int id;
  final String title;
  final String price;

  Additive({
    required this.id,
    required this.title,
    required this.price,
  });

  factory Additive.fromJson(Map<String, dynamic> json) => Additive(
        id: json["id"] is int
            ? json["id"]
            : int.tryParse(json["id"].toString()) ?? 0,
        title: json["title"]?.toString() ?? "",
        price: json["price"]?.toString() ?? "0",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "price": price,
      };
}
