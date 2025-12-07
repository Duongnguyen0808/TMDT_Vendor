import 'dart:convert';

import 'package:appliances_flutter/constants/constants.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class RatingCheckResult {
  final bool hasRating;
  final double? rating;
  final String? comment;
  final String message;

  const RatingCheckResult({
    required this.hasRating,
    required this.rating,
    required this.comment,
    required this.message,
  });
}

class RatingSubmitResult {
  final bool success;
  final String message;

  const RatingSubmitResult({required this.success, required this.message});
}

class VendorRatingEntry {
  final String author;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String relatedProductTitle;
  final String? relatedProductId;

  const VendorRatingEntry({
    required this.author,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.relatedProductTitle,
    this.relatedProductId,
  });

  factory VendorRatingEntry.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final author = user is Map && user['username'] != null
        ? user['username'].toString()
        : 'Khách hàng ẩn danh';
    final ratingValue = json['rating'];
    final createdAtRaw = json['createdAt'];
    final createdAt =
        createdAtRaw is String ? DateTime.tryParse(createdAtRaw) : null;
    return VendorRatingEntry(
      author: author,
      rating: ratingValue is num ? ratingValue.toDouble() : 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: createdAt ?? DateTime.now(),
      relatedProductTitle: json['relatedProductTitle']?.toString() ?? '',
      relatedProductId: json['relatedProductId'] != null &&
              json['relatedProductId'].toString().isNotEmpty
          ? json['relatedProductId'].toString()
          : null,
    );
  }
}

class VendorRatingSummary {
  final double average;
  final int total;
  final Map<int, int> breakdown;

  const VendorRatingSummary({
    required this.average,
    required this.total,
    required this.breakdown,
  });
}

class VendorRatingFeed {
  final VendorRatingSummary summary;
  final List<VendorRatingEntry> entries;

  const VendorRatingFeed({required this.summary, required this.entries});
}

class VendorRatingService {
  VendorRatingService._();

  static final VendorRatingService instance = VendorRatingService._();
  final _box = GetStorage();

  String? get _token {
    final access = _box.read('accessToken');
    if (access is String && access.isNotEmpty) return access;
    final fallback = _box.read('token');
    if (fallback is String && fallback.isNotEmpty) return fallback;
    return null;
  }

  Map<String, String> _headers({bool withJson = false}) {
    final token = _token;
    if (token == null) {
      throw Exception('Bạn cần đăng nhập lại để gửi đánh giá');
    }
    return {
      'Authorization': 'Bearer $token',
      if (withJson) 'Content-Type': 'application/json',
    };
  }

  String? get currentStoreId {
    final store = _box.read('storeId');
    if (store is String && store.isNotEmpty) return store;
    return null;
  }

  Future<RatingCheckResult> checkRating({
    required String ratingType,
    required String productId,
  }) async {
    final url = Uri.parse('$appBaseUrl/api/rating').replace(
      queryParameters: {
        'ratingType': ratingType,
        'product': productId,
      },
    );
    final resp = await http.get(url, headers: _headers());
    final Map<String, dynamic> body = _decode(resp.body);
    final statusOk = resp.statusCode == 200;
    if (!statusOk) {
      throw Exception(body['message'] ?? 'Không thể kiểm tra đánh giá');
    }
    final hasRating = body['status'] == true;
    final ratingValue = body['rating'];
    final commentValue = body['comment'];
    return RatingCheckResult(
      hasRating: hasRating,
      rating: ratingValue is num ? ratingValue.toDouble() : null,
      comment: commentValue is String ? commentValue : null,
      message: body['message']?.toString() ?? '',
    );
  }

  Future<RatingSubmitResult> submitRating({
    required String ratingType,
    required String productId,
    required double rating,
    String comment = '',
  }) async {
    final payload = jsonEncode({
      'ratingType': ratingType,
      'product': productId,
      'rating': rating,
      'comment': comment,
    });
    // Backend path uses /api/rating (singular)
    final url = Uri.parse('$appBaseUrl/api/rating');
    final resp =
        await http.post(url, headers: _headers(withJson: true), body: payload);
    final Map<String, dynamic> body = _decode(resp.body);
    final success = (resp.statusCode == 200 || resp.statusCode == 201) &&
        (body['status'] == true);
    final message = body['message']?.toString() ??
        (success ? 'Đã ghi nhận đánh giá' : 'Không thể gửi đánh giá');
    return RatingSubmitResult(success: success, message: message);
  }

  Future<VendorRatingFeed> fetchStoreRatings({
    required String storeId,
    int limit = 6,
  }) async {
    if (storeId.isEmpty) {
      throw Exception('Không xác định được cửa hàng');
    }
    final uri = Uri.parse('$appBaseUrl/api/rating/Store/$storeId').replace(
      queryParameters: {'limit': limit.toString()},
    );
    return _fetchRatingsFeed(uri);
  }

  Future<VendorRatingFeed> fetchProductRatings({
    required String productId,
    int limit = 12,
  }) async {
    if (productId.isEmpty) {
      throw Exception('Không xác định được sản phẩm');
    }
    final uri =
        Uri.parse('$appBaseUrl/api/rating/Appliances/$productId').replace(
      queryParameters: {'limit': limit.toString()},
    );
    return _fetchRatingsFeed(uri);
  }

  Future<VendorRatingFeed> _fetchRatingsFeed(Uri uri) async {
    final resp = await http.get(uri, headers: _headers());
    final body = _decode(resp.body);
    if (resp.statusCode != 200 || body['status'] != true) {
      throw Exception(body['message']?.toString() ?? 'Không tải được đánh giá');
    }
    final summaryRaw = body['summary'];
    final breakdown = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double average = 0;
    int total = 0;
    if (summaryRaw is Map) {
      final avgRaw = summaryRaw['average'];
      final totalRaw = summaryRaw['total'];
      average = avgRaw is num ? avgRaw.toDouble() : 0;
      total = totalRaw is num ? totalRaw.toInt() : 0;
      final breakdownRaw = summaryRaw['breakdown'];
      if (breakdownRaw is Map) {
        breakdownRaw.forEach((key, value) {
          final star = int.tryParse(key.toString());
          if (star != null && breakdown.containsKey(star)) {
            breakdown[star] = value is num ? value.toInt() : 0;
          }
        });
      }
    }
    final ratingsRaw = body['ratings'];
    final entries = <VendorRatingEntry>[];
    if (ratingsRaw is List) {
      for (final item in ratingsRaw) {
        if (item is Map<String, dynamic>) {
          entries.add(VendorRatingEntry.fromJson(item));
        } else if (item is Map) {
          entries.add(VendorRatingEntry.fromJson(
            Map<String, dynamic>.from(item),
          ));
        }
      }
    }
    final summary = VendorRatingSummary(
      average: average,
      total: total,
      breakdown: breakdown,
    );
    return VendorRatingFeed(summary: summary, entries: entries);
  }

  Map<String, dynamic> _decode(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }
}
