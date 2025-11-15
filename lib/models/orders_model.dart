// To parse this JSON data, do
//
//     final ordersModel = ordersModelFromJson(jsonString);

import 'dart:convert';

List<OrdersModel> ordersModelFromJson(String str) => List<OrdersModel>.from(
    json.decode(str).map((x) => OrdersModel.fromJson(x)));

String ordersModelToJson(List<OrdersModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class OrdersModel {
  final String id;
  final UserId userId;
  final List<OrderItem> orderItems;
  final double orderTotal;
  final double deliveryFee;
  final double grandTotal;
  final DeliveryAddress deliveryAddress;
  final String orderStatus;
  final StoreId storeId;
  final List<double> storeCoords;
  final List<double> recipientCoords;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrdersModel({
    required this.id,
    required this.userId,
    required this.orderItems,
    required this.orderTotal,
    required this.deliveryFee,
    required this.grandTotal,
    required this.deliveryAddress,
    required this.orderStatus,
    required this.storeId,
    required this.storeCoords,
    required this.recipientCoords,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrdersModel.fromJson(Map<String, dynamic> json) => OrdersModel(
        id: json["_id"],
        userId: UserId.fromJson(json["userId"]),
        orderItems: List<OrderItem>.from(
            json["orderItems"].map((x) => OrderItem.fromJson(x))),
        orderTotal: json["orderTotal"]?.toDouble() ?? 0.0,
        deliveryFee: json["deliveryFee"]?.toDouble() ?? 0.0,
        grandTotal: json["grandTotal"]?.toDouble() ?? 0.0,
        deliveryAddress: DeliveryAddress.fromJson(json["deliveryAddress"]),
        orderStatus: json["orderStatus"],
        storeId: StoreId.fromJson(json["storeId"]),
        storeCoords:
            List<double>.from(json["storeCoords"].map((x) => x?.toDouble())),
        recipientCoords: List<double>.from(
            json["recipientCoords"].map((x) => x?.toDouble())),
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "userId": userId.toJson(),
        "orderItems": List<dynamic>.from(orderItems.map((x) => x.toJson())),
        "orderTotal": orderTotal,
        "deliveryFee": deliveryFee,
        "grandTotal": grandTotal,
        "deliveryAddress": deliveryAddress.toJson(),
        "orderStatus": orderStatus,
        "storeId": storeId.toJson(),
        "storeCoords": List<dynamic>.from(storeCoords.map((x) => x)),
        "recipientCoords": List<dynamic>.from(recipientCoords.map((x) => x)),
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };
}

class DeliveryAddress {
  final String id;
  final String addressLine1;

  DeliveryAddress({
    required this.id,
    required this.addressLine1,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      DeliveryAddress(
        id: json["_id"],
        addressLine1: json["addressLine1"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "addressLine1": addressLine1,
      };
}

class OrderItem {
  final AppliancesId appliancesId;
  final int quantity;
  final double price;
  final List<String> additives;
  final String instructions;
  final String id;

  OrderItem({
    required this.appliancesId,
    required this.quantity,
    required this.price,
    required this.additives,
    required this.instructions,
    required this.id,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        appliancesId: AppliancesId.fromJson(json["appliancesId"]),
        quantity: json["quantity"],
        price: json["price"]?.toDouble(),
        additives: List<String>.from(json["additives"].map((x) => x)),
        instructions: json["instructions"],
        id: json["_id"],
      );

  Map<String, dynamic> toJson() => {
        "appliancesId": appliancesId.toJson(),
        "quantity": quantity,
        "price": price,
        "additives": List<dynamic>.from(additives.map((x) => x)),
        "instructions": instructions,
        "_id": id,
      };
}

class AppliancesId {
  final String id;
  final String title;
  final String time;
  final List<String> imageUrl;

  AppliancesId({
    required this.id,
    required this.title,
    required this.time,
    required this.imageUrl,
  });

  factory AppliancesId.fromJson(Map<String, dynamic> json) => AppliancesId(
        id: json["_id"],
        title: json["title"],
        time: json["time"],
        imageUrl: List<String>.from(json["imageUrl"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "title": title,
        "time": time,
        "imageUrl": List<dynamic>.from(imageUrl.map((x) => x)),
      };
}

class StoreId {
  final Coords coords;
  final String id;
  final String title;
  final String time;
  final String imageUrl;
  final String logoUrl;

  StoreId({
    required this.coords,
    required this.id,
    required this.title,
    required this.time,
    required this.imageUrl,
    required this.logoUrl,
  });

  factory StoreId.fromJson(Map<String, dynamic> json) => StoreId(
        coords: Coords.fromJson(json["coords"]),
        id: json["_id"],
        title: json["title"],
        time: json["time"],
        imageUrl: json["imageUrl"],
        logoUrl: json["logoUrl"],
      );

  Map<String, dynamic> toJson() => {
        "coords": coords.toJson(),
        "_id": id,
        "title": title,
        "time": time,
        "imageUrl": imageUrl,
        "logoUrl": logoUrl,
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

class UserId {
  final String id;
  final String phone;
  final String profile;

  UserId({
    required this.id,
    required this.phone,
    required this.profile,
  });

  factory UserId.fromJson(Map<String, dynamic> json) => UserId(
        id: json["_id"],
        phone: json["phone"],
        profile: json["profile"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "phone": phone,
        "profile": profile,
      };
}
