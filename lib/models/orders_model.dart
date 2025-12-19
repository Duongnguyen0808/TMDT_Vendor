// To parse this JSON data, do
//
//     final ordersModel = ordersModelFromJson(jsonString);

import 'dart:convert';

List<OrdersModel> ordersModelFromJson(String str) {
  try {
    final decoded = json.decode(str);
    if (decoded is List) {
      return decoded
          .map<OrdersModel>((x) => OrdersModel.fromJson(_asMap(x)))
          .toList();
    }
    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map<OrdersModel>((x) => OrdersModel.fromJson(_asMap(x)))
          .toList();
    }
    // Không đúng dạng -> trả về rỗng để tránh null crash
    return [];
  } catch (e) {
    return [];
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

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
  final String? driverId;
  final String? proposedDriverId;
  final String? returnStatus;
  final String? returnReason;
  final double? refundAmount;
  final DateTime? returnRequestedAt;
  final DateTime? returnProcessedAt;
  final DateTime? refundAt;
  final String? refundMethod;
  final String? refundReference;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? pickupCode;
  final DateTime? pickupReadyAt;
  final DateTime? pickupCodeExpiresAt;
  final DateTime? pickupAssignedAt;
  final DateTime? pickupCheckinAt;
  final PickupCheckinLocation? pickupCheckinLocation;
  final DateTime? pickupConfirmedAt;
  final String? shopReadyBy;
  final String? shipperPickupBy;
  final String? pickupNotes;
  final String? handoverPhoto;
  final String? deliveryProofPhoto;
  final String? deliveryProofNote;
  final String? deliveryProofRecipient;
  final DateTime? deliveryProofAt;
  final DeliveryProofLocation? deliveryProofLocation;
  final String? shopDeliveryConfirmStatus;
  final DateTime? shopDeliveryConfirmedAt;
  final String? shopDeliveryConfirmedBy;
  final String? shopDeliveryConfirmNote;
  final String? shopDeliveryRejectReason;
  final DateTime? shopDeliveryRejectedAt;
  final String? deliveryIssueStatus;
  final String? deliveryIssueNote;
  final String? customerDisputeStatus;
  final String? customerDisputeNote;
  final DateTime? customerDisputeAt;
  final DateTime? customerDisputeResolvedAt;
  final String? customerDisputeResolution;
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
    this.driverId,
    this.proposedDriverId,
    this.returnStatus,
    this.returnReason,
    this.refundAmount,
    this.returnRequestedAt,
    this.returnProcessedAt,
    this.refundAt,
    this.refundMethod,
    this.refundReference,
    this.paymentMethod,
    this.paymentStatus,
    this.pickupCode,
    this.pickupReadyAt,
    this.pickupCodeExpiresAt,
    this.pickupAssignedAt,
    this.pickupCheckinAt,
    this.pickupCheckinLocation,
    this.pickupConfirmedAt,
    this.shopReadyBy,
    this.shipperPickupBy,
    this.pickupNotes,
    this.handoverPhoto,
    this.deliveryProofPhoto,
    this.deliveryProofNote,
    this.deliveryProofRecipient,
    this.deliveryProofAt,
    this.deliveryProofLocation,
    this.shopDeliveryConfirmStatus,
    this.shopDeliveryConfirmedAt,
    this.shopDeliveryConfirmedBy,
    this.shopDeliveryConfirmNote,
    this.shopDeliveryRejectReason,
    this.shopDeliveryRejectedAt,
    this.deliveryIssueStatus,
    this.deliveryIssueNote,
    this.customerDisputeStatus,
    this.customerDisputeNote,
    this.customerDisputeAt,
    this.customerDisputeResolvedAt,
    this.customerDisputeResolution,
  });

  factory OrdersModel.fromJson(Map<String, dynamic> json) => OrdersModel(
        id: (json["_id"] ?? '').toString(),
        userId: json["userId"] is Map
            ? UserId.fromJson(_asMap(json["userId"]))
            : UserId.empty(),
        orderItems: json["orderItems"] is List
            ? List<OrderItem>.from((json["orderItems"] as List)
                .map((x) => OrderItem.fromJson(_asMap(x))))
            : <OrderItem>[],
        orderTotal: _toDouble(json["orderTotal"]),
        deliveryFee: _toDouble(json["deliveryFee"]),
        grandTotal: _toDouble(json["grandTotal"]),
        deliveryAddress: json["deliveryAddress"] is Map
            ? DeliveryAddress.fromJson(_asMap(json["deliveryAddress"]))
            : DeliveryAddress.empty(),
        orderStatus: (json["orderStatus"] ?? '').toString(),
        storeId: json["storeId"] is Map
            ? StoreId.fromJson(_asMap(json["storeId"]))
            : StoreId.empty(),
        storeCoords: json["storeCoords"] is List
            ? List<double>.from((json["storeCoords"] as List).map(_toDouble))
            : <double>[],
        recipientCoords: json["recipientCoords"] is List
            ? List<double>.from(
                (json["recipientCoords"] as List).map(_toDouble))
            : <double>[],
        driverId: (json["driverId"])?.toString(),
        proposedDriverId: (json["proposedDriverId"])?.toString(),
        returnStatus: (json["returnStatus"])?.toString(),
        returnReason: (json["returnReason"])?.toString(),
        refundAmount: json["refundAmount"] == null
            ? null
            : _toDouble(json["refundAmount"]),
        returnRequestedAt: _parseDateOrNull(json["returnRequestedAt"]),
        returnProcessedAt: _parseDateOrNull(json["returnProcessedAt"]),
        refundAt: _parseDateOrNull(json["refundAt"]),
        refundMethod: _nullableString(json["refundMethod"]),
        refundReference: _nullableString(json["refundReference"]),
        paymentMethod: _nullableString(json["paymentMethod"]),
        paymentStatus: (json["paymentStatus"])?.toString(),
        pickupCode: _nullableString(json["pickupCode"]),
        pickupReadyAt: _parseDateOrNull(json["pickupReadyAt"]),
        pickupCodeExpiresAt: _parseDateOrNull(json["pickupCodeExpiresAt"]),
        pickupAssignedAt: _parseDateOrNull(json["pickupAssignedAt"]),
        pickupCheckinAt: _parseDateOrNull(json["pickupCheckinAt"]),
        pickupCheckinLocation: json["pickupCheckinLocation"] is Map
            ? PickupCheckinLocation.fromJson(
                _asMap(json["pickupCheckinLocation"]))
            : null,
        pickupConfirmedAt: _parseDateOrNull(json["pickupConfirmedAt"]),
        shopReadyBy: _nullableString(json["shopReadyBy"]),
        shipperPickupBy: _nullableString(json["shipperPickupBy"]),
        pickupNotes: _nullableString(json["pickupNotes"]),
        handoverPhoto: _nullableString(json["handoverPhoto"]),
        deliveryProofPhoto: _nullableString(json["deliveryProofPhoto"]),
        deliveryProofNote: _nullableString(json["deliveryProofNote"]),
        deliveryProofRecipient: _nullableString(json["deliveryProofRecipient"]),
        deliveryProofAt: _parseDateOrNull(json["deliveryProofAt"]),
        deliveryProofLocation: json["deliveryProofLocation"] is Map
            ? DeliveryProofLocation.fromJson(
                _asMap(json["deliveryProofLocation"]))
            : null,
        shopDeliveryConfirmStatus:
            _nullableString(json["shopDeliveryConfirmStatus"]),
        shopDeliveryConfirmedAt:
            _parseDateOrNull(json["shopDeliveryConfirmedAt"]),
        shopDeliveryConfirmedBy:
            _nullableString(json["shopDeliveryConfirmedBy"]),
        shopDeliveryConfirmNote:
            _nullableString(json["shopDeliveryConfirmNote"]),
        shopDeliveryRejectReason:
            _nullableString(json["shopDeliveryRejectReason"]),
        shopDeliveryRejectedAt:
            _parseDateOrNull(json["shopDeliveryRejectedAt"]),
        deliveryIssueStatus: _nullableString(json['deliveryIssueStatus']),
        deliveryIssueNote: _nullableString(json['deliveryIssueNote']),
        customerDisputeStatus: _nullableString(json['customerDisputeStatus']),
        customerDisputeNote: _nullableString(json['customerDisputeNote']),
        customerDisputeAt: _parseDateOrNull(json['customerDisputeAt']),
        customerDisputeResolvedAt:
            _parseDateOrNull(json['customerDisputeResolvedAt']),
        customerDisputeResolution:
            _nullableString(json['customerDisputeResolution']),
        createdAt: _parseDate(json["createdAt"]),
        updatedAt: _parseDate(json["updatedAt"]),
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
        "driverId": driverId,
        "proposedDriverId": proposedDriverId,
        "returnStatus": returnStatus,
        "returnReason": returnReason,
        "refundAmount": refundAmount,
        "returnRequestedAt": returnRequestedAt?.toIso8601String(),
        "returnProcessedAt": returnProcessedAt?.toIso8601String(),
        "refundAt": refundAt?.toIso8601String(),
        "refundMethod": refundMethod,
        "refundReference": refundReference,
        "paymentMethod": paymentMethod,
        "paymentStatus": paymentStatus,
        "pickupCode": pickupCode,
        "pickupReadyAt": pickupReadyAt?.toIso8601String(),
        "pickupCodeExpiresAt": pickupCodeExpiresAt?.toIso8601String(),
        "pickupAssignedAt": pickupAssignedAt?.toIso8601String(),
        "pickupCheckinAt": pickupCheckinAt?.toIso8601String(),
        "pickupCheckinLocation": pickupCheckinLocation?.toJson(),
        "pickupConfirmedAt": pickupConfirmedAt?.toIso8601String(),
        "shopReadyBy": shopReadyBy,
        "shipperPickupBy": shipperPickupBy,
        "pickupNotes": pickupNotes,
        "handoverPhoto": handoverPhoto,
        "deliveryProofPhoto": deliveryProofPhoto,
        "deliveryProofNote": deliveryProofNote,
        "deliveryProofRecipient": deliveryProofRecipient,
        "deliveryProofAt": deliveryProofAt?.toIso8601String(),
        "deliveryProofLocation": deliveryProofLocation?.toJson(),
        "shopDeliveryConfirmStatus": shopDeliveryConfirmStatus,
        "shopDeliveryConfirmedAt": shopDeliveryConfirmedAt?.toIso8601String(),
        "shopDeliveryConfirmedBy": shopDeliveryConfirmedBy,
        "shopDeliveryConfirmNote": shopDeliveryConfirmNote,
        "shopDeliveryRejectReason": shopDeliveryRejectReason,
        "shopDeliveryRejectedAt": shopDeliveryRejectedAt?.toIso8601String(),
        "deliveryIssueStatus": deliveryIssueStatus,
        "deliveryIssueNote": deliveryIssueNote,
        "customerDisputeStatus": customerDisputeStatus,
        "customerDisputeNote": customerDisputeNote,
        "customerDisputeAt": customerDisputeAt?.toIso8601String(),
        "customerDisputeResolvedAt":
            customerDisputeResolvedAt?.toIso8601String(),
        "customerDisputeResolution": customerDisputeResolution,
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
        id: (json["_id"] ?? '').toString(),
        addressLine1: (json["addressLine1"] ?? '').toString(),
      );

  factory DeliveryAddress.empty() => DeliveryAddress(id: '', addressLine1: '');

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
        appliancesId: json["appliancesId"] is Map
            ? AppliancesId.fromJson(_asMap(json["appliancesId"]))
            : AppliancesId.empty(),
        quantity: json["quantity"] is int
            ? json["quantity"]
            : int.tryParse('${json["quantity"]}') ?? 0,
        price: _toDouble(json["price"]),
        additives: json["additives"] is List
            ? List<String>.from(
                (json["additives"] as List).map((x) => x.toString()))
            : <String>[],
        instructions: (json["instructions"] ?? '').toString(),
        id: (json["_id"] ?? '').toString(),
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
  final int? stock;

  AppliancesId({
    required this.id,
    required this.title,
    required this.time,
    required this.imageUrl,
    this.stock,
  });

  factory AppliancesId.fromJson(Map<String, dynamic> json) => AppliancesId(
        id: (json["_id"] ?? '').toString(),
        title: (json["title"] ?? '').toString(),
        time: (json["time"] ?? '').toString(),
        imageUrl: json["imageUrl"] is List
            ? List<String>.from(
                (json["imageUrl"] as List).map((x) => x.toString()))
            : <String>[],
        stock: (() {
          final v = json["stock"];
          if (v == null) return null;
          if (v is int) return v;
          if (v is double) return v.toInt();
          if (v is String) return int.tryParse(v);
          return null;
        })(),
      );

  factory AppliancesId.empty() => AppliancesId(
      id: '', title: '', time: '', imageUrl: <String>[], stock: null);

  Map<String, dynamic> toJson() => {
        "_id": id,
        "title": title,
        "time": time,
        "imageUrl": List<dynamic>.from(imageUrl.map((x) => x)),
        if (stock != null) "stock": stock,
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
        coords: json["coords"] is Map
            ? Coords.fromJson(_asMap(json["coords"]))
            : Coords.empty(),
        id: (json["_id"] ?? '').toString(),
        title: (json["title"] ?? '').toString(),
        time: (json["time"] ?? '').toString(),
        imageUrl: (json["imageUrl"] ?? '').toString(),
        logoUrl: (json["logoUrl"] ?? '').toString(),
      );

  factory StoreId.empty() => StoreId(
      coords: Coords.empty(),
      id: '',
      title: '',
      time: '',
      imageUrl: '',
      logoUrl: '');

  Map<String, dynamic> toJson() => {
        "coords": coords.toJson(),
        "_id": id,
        "title": title,
        "time": time,
        "imageUrl": imageUrl,
        "logoUrl": logoUrl,
      };
}

class PickupCheckinLocation {
  final double latitude;
  final double longitude;

  PickupCheckinLocation({
    required this.latitude,
    required this.longitude,
  });

  factory PickupCheckinLocation.fromJson(Map<String, dynamic> json) =>
      PickupCheckinLocation(
        latitude: _toDouble(json["latitude"]),
        longitude: _toDouble(json["longitude"]),
      );

  factory PickupCheckinLocation.empty() =>
      PickupCheckinLocation(latitude: 0, longitude: 0);

  Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
      };
}

class DeliveryProofLocation {
  final double latitude;
  final double longitude;

  const DeliveryProofLocation(
      {required this.latitude, required this.longitude});

  factory DeliveryProofLocation.fromJson(Map<String, dynamic> json) =>
      DeliveryProofLocation(
        latitude: _toDouble(json["latitude"]),
        longitude: _toDouble(json["longitude"]),
      );

  Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
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
        id: (json["id"] ?? '').toString(),
        latitude: _toDouble(json["latitude"]),
        longitude: _toDouble(json["longitude"]),
        address: (json["address"] ?? '').toString(),
        title: (json["title"] ?? '').toString(),
      );

  factory Coords.empty() =>
      Coords(id: '', latitude: 0, longitude: 0, address: '', title: '');

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
  final String name;
  final String displayName;
  final String email;
  final Map<String, dynamic> raw;

  UserId({
    required this.id,
    required this.phone,
    required this.profile,
    required this.name,
    required this.displayName,
    required this.email,
    required this.raw,
  });

  factory UserId.fromJson(Map<String, dynamic> json) {
    final normalized = _asMap(json);
    return UserId(
      id: (normalized["_id"] ?? '').toString(),
      phone:
          (normalized["phone"] ?? normalized["phoneNumber"] ?? '').toString(),
      profile: (normalized["profile"] ?? '').toString(),
      name: (normalized["fullName"] ??
              normalized["fullname"] ??
              normalized["name"] ??
              normalized["displayName"] ??
              normalized["username"] ??
              '')
          .toString(),
      displayName: (normalized["displayName"] ?? '').toString(),
      email: (normalized["email"] ?? '').toString(),
      raw: Map<String, dynamic>.from(normalized),
    );
  }

  factory UserId.empty() => UserId(
        id: '',
        phone: '',
        profile: '',
        name: '',
        displayName: '',
        email: '',
        raw: const <String, dynamic>{},
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "phone": phone,
        "profile": profile,
        "fullName": name,
        "displayName": displayName,
        "email": email,
      };
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) {
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _parseDateOrNull(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) {
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  return null;
}

String? _nullableString(dynamic v) {
  if (v == null) return null;
  final str = v.toString();
  return str.isEmpty ? null : str;
}
