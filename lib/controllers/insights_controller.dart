import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/insights_models.dart';

class InsightsController extends GetxController {
  final GetStorage _box = GetStorage();

  final Rx<VendorAnalyticsOverview?> analytics =
      Rx<VendorAnalyticsOverview?>(null);
  final Rx<StoreRecommendations?> recommendations =
      Rx<StoreRecommendations?>(null);
  final RxBool analyticsLoading = false.obs;
  final RxBool recommendationsLoading = false.obs;
  final RxString errorMessage = ''.obs;

  int _rangeDays = 30;

  String get _storeId => (_box.read('storeId') ?? '').toString();
  String get _token => (_box.read('accessToken') ?? '').toString();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([loadAnalytics(), loadRecommendations()]);
  }

  Future<void> loadAnalytics({int? rangeDays}) async {
    final storeId = _storeId;
    final token = _token;
    if (storeId.isEmpty || token.isEmpty) {
      errorMessage.value = 'Thiếu thông tin cửa hàng hoặc token';
      return;
    }
    _rangeDays = rangeDays ?? _rangeDays;
    analyticsLoading.value = true;
    try {
      final uri = Uri.parse(
          '$appBaseUrl/api/analytics/vendor/$storeId/overview?range=$_rangeDays');
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        analytics.value = vendorAnalyticsOverviewFromJson(response.body);
      } else {
        analytics.value = null;
        errorMessage.value = _extractMessage(response.body) ??
            'Không tải được thống kê (${response.statusCode})';
      }
    } catch (e) {
      analytics.value = null;
      errorMessage.value = 'Lỗi tải thống kê: $e';
    } finally {
      analyticsLoading.value = false;
    }
  }

  Future<void> loadRecommendations() async {
    final storeId = _storeId;
    final token = _token;
    if (storeId.isEmpty || token.isEmpty) {
      return;
    }
    recommendationsLoading.value = true;
    try {
      final uri =
          Uri.parse('$appBaseUrl/api/recommendations/store/$storeId?limit=8');
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        recommendations.value = storeRecommendationsFromJson(response.body);
      } else {
        recommendations.value = StoreRecommendations.empty();
      }
    } catch (e) {
      recommendations.value = StoreRecommendations.empty();
    } finally {
      recommendationsLoading.value = false;
    }
  }

  Future<void> refreshAll() async {
    await loadAll();
  }

  String? _extractMessage(String body) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(body);
      return decoded['message']?.toString();
    } catch (_) {
      return null;
    }
  }
}
