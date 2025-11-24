import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:appliances_flutter/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:appliances_flutter/models/orders_model.dart';

class VendorOrderController extends GetxController {
  final box = GetStorage();

  RxBool isLoading = false.obs;
  RxList<OrdersModel> pendingOrders = <OrdersModel>[].obs;
  RxList<OrdersModel> preparingOrders = <OrdersModel>[].obs;
  RxList<OrdersModel> waitingShipperOrders = <OrdersModel>[].obs;
  RxList<OrdersModel> readyForPickupOrders = <OrdersModel>[].obs;
  RxList<OrdersModel> deliveringOrders = <OrdersModel>[].obs;
  RxList<OrdersModel> deliveredOrders = <OrdersModel>[].obs;
  RxList<OrdersModel> cancelledOrders = <OrdersModel>[].obs;

  List<OrdersModel> _claimedWaitingOrders = <OrdersModel>[];
  Set<String> _deliveredSnapshot = <String>{};
  bool _deliveredInitialized = false;

  String get storeId => box.read('storeId') ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchAllOrders();
  }

  Future<void> fetchAllOrders() async {
    isLoading.value = true;
    try {
      await _loadStatus('Pending', pendingOrders);
      await _loadStatus('Preparing', preparingOrders);
      await _loadStatus('ReadyForPickup', readyForPickupOrders);
      await _loadWaitingShipper();
      await _loadDeliveringLikeStatuses();
      await _loadStatus('Delivered', deliveredOrders, trackDelivered: true);
      await _loadStatus('Cancelled', cancelledOrders);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadStatus(String status, RxList<OrdersModel> target,
      {bool trackDelivered = false}) async {
    final orders = await _fetchOrders(status);
    target.value = orders;
    if (trackDelivered) {
      _handleDeliveredSnapshot(orders);
    }
  }

  Future<void> _loadWaitingShipper() async {
    final orders = await _fetchOrders('WaitingShipper');
    final List<OrdersModel> unassigned = [];
    final List<OrdersModel> claimed = [];
    for (final order in orders) {
      final driverId = order.driverId ?? '';
      if (driverId.isEmpty) {
        unassigned.add(order);
      } else {
        claimed.add(order);
      }
    }
    waitingShipperOrders.value = unassigned;
    _claimedWaitingOrders = claimed;
  }

  Future<void> _loadDeliveringLikeStatuses() async {
    final pickedUp = await _fetchOrders('PickedUp');
    final delivering = await _fetchOrders('Delivering');
    final combined = [
      ..._claimedWaitingOrders,
      ...pickedUp,
      ...delivering,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    deliveringOrders.value = combined;
  }

  void _handleDeliveredSnapshot(List<OrdersModel> orders) {
    final ids = orders.map((e) => e.id).where((id) => id.isNotEmpty).toSet();
    if (_deliveredInitialized) {
      final newlyDelivered = ids.difference(_deliveredSnapshot);
      if (newlyDelivered.isNotEmpty) {
        _notifyDeliveredOrders(orders, newlyDelivered);
      }
    } else {
      _deliveredInitialized = true;
    }
    _deliveredSnapshot = ids;
  }

  void _notifyDeliveredOrders(
      List<OrdersModel> delivered, Set<String> newlyDelivered) {
    final recent = delivered
        .where((order) => newlyDelivered.contains(order.id))
        .take(3)
        .map((order) {
      final shortId = order.id.length > 6
          ? order.id.substring(0, 6).toUpperCase()
          : order.id.toUpperCase();
      return '#$shortId';
    }).toList();
    if (recent.isEmpty) return;
    final moreCount = newlyDelivered.length - recent.length;
    final message = moreCount > 0
        ? '${recent.join(', ')} và $moreCount đơn khác đã giao xong.'
        : '${recent.join(', ')} đã giao xong.';
    Get.snackbar(
      'Shipper đã giao thành công',
      message,
      backgroundColor: Colors.green.shade600,
      colorText: kLightWhite,
      duration: const Duration(seconds: 4),
    );
  }

  Future<List<OrdersModel>> _fetchOrders(String status) async {
    final accessToken = box.read('accessToken');
    try {
      final url = Uri.parse(
          '$appBaseUrl/api/orders/store/$storeId?statuses=$status&payment=all&page=1&limit=100');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> wrapper = jsonDecode(response.body);
        final List<dynamic> data =
            (wrapper['data'] is List) ? wrapper['data'] : [];
        return data
            .map(
                (json) => OrdersModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      print(
          '[VendorOrderController][_fetchOrders] HTTP ${response.statusCode} body=${response.body}');
    } catch (e) {
      print('Error fetching $status orders: $e');
    }
    return <OrdersModel>[];
  }

  Future<Map<String, dynamic>?> markReadyForPickup(String orderId) async {
    return _postPickupAction(
      orderId: orderId,
      endpoint: 'ready-for-pickup',
      successTitle: 'Đã phát mã',
    );
  }

  Future<Map<String, dynamic>?> regeneratePickupCode(String orderId) async {
    return _postPickupAction(
      orderId: orderId,
      endpoint: 'pickup-code/regenerate',
      successTitle: 'Tạo mã mới',
    );
  }

  Future<Map<String, dynamic>?> _postPickupAction({
    required String orderId,
    required String endpoint,
    required String successTitle,
  }) async {
    final accessToken = box.read('accessToken');
    try {
      final url = Uri.parse('$appBaseUrl/api/orders/$orderId/$endpoint');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}

      if (response.statusCode == 200 && (data['status'] == true)) {
        Get.snackbar(successTitle, data['message'] ?? 'Thành công',
            backgroundColor: kPrimary, colorText: kLightWhite);
        await fetchAllOrders();
        return data;
      }

      final message = (data['message'] ?? 'Không thể xử lý yêu cầu').toString();
      Get.snackbar('Lỗi', message,
          backgroundColor: kRed, colorText: kLightWhite);
    } catch (e) {
      Get.snackbar('Lỗi', 'Kết nối thất bại: $e',
          backgroundColor: kRed, colorText: kLightWhite);
    }
    return null;
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus,
      {bool shouldPop = true}) async {
    String accessToken = box.read('accessToken');
    isLoading.value = true;

    try {
      final url = Uri.parse('$appBaseUrl/api/orders/$orderId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'orderStatus': newStatus}),
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Thành công',
          'Cập nhật trạng thái đơn hàng thành công',
          backgroundColor: kPrimary,
          colorText: kLightWhite,
        );

        // Refresh orders
        await fetchAllOrders();

        if (shouldPop) {
          final navigator = Get.key.currentState;
          if (navigator?.canPop() ?? false) {
            navigator!.pop();
          }
        }
        return true;
      } else {
        print(
            '[VendorOrderController][updateOrderStatus] HTTP ${response.statusCode} body=${response.body}');
        Get.snackbar(
          'Lỗi',
          'Không thể cập nhật đơn hàng',
          backgroundColor: kRed,
          colorText: kLightWhite,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Lỗi kết nối: ${e.toString()}',
        backgroundColor: kRed,
        colorText: kLightWhite,
      );
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  // Convenience: approve đơn Pending -> chuyển Preparing
  Future<void> approvePending(String orderId) async {
    await updateOrderStatus(orderId, 'Preparing');
  }

  String? nextStatus(String current) {
    const flow = [
      'Pending',
      'Preparing',
      'ReadyForPickup',
      'WaitingShipper',
      'Delivering',
      'Delivered'
    ];
    final idx = flow.indexOf(current);
    if (idx == -1) return null;
    if (idx < flow.length - 1) return flow[idx + 1];
    return null; // delivered cuối
  }

  Future<void> progressOrder(String orderId, String currentStatus) async {
    final ns = nextStatus(currentStatus);
    if (ns == null) {
      Get.snackbar('Trạng thái', 'Đơn đã ở trạng thái cuối cùng',
          backgroundColor: kPrimary, colorText: kLightWhite);
      return;
    }
    await updateOrderStatus(orderId, ns);
  }

  Future<OrdersModel?> fetchOrderDetail(String orderId) async {
    String accessToken = box.read('accessToken');
    try {
      final url = Uri.parse('$appBaseUrl/api/orders/$orderId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final Map<String, dynamic> data = json['data'];
        return OrdersModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> reviewReturn(String orderId, String action,
      {String note = ""}) async {
    final accessToken = box.read('accessToken');
    try {
      final url = Uri.parse('$appBaseUrl/api/orders/$orderId/return-review');
      final resp = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'action': action, 'note': note}),
      );
      if (resp.statusCode == 200) {
        Get.snackbar(
            'Thành công',
            action == 'approve'
                ? 'Đã duyệt yêu cầu trả hàng'
                : 'Đã từ chối yêu cầu trả hàng',
            backgroundColor: kPrimary,
            colorText: kLightWhite);
        await fetchAllOrders();
        return true;
      } else {
        final data = jsonDecode(resp.body);
        Get.snackbar('Lỗi', data['message'] ?? 'Không thể xử lý',
            backgroundColor: kRed, colorText: kLightWhite);
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Kết nối thất bại: $e',
          backgroundColor: kRed, colorText: kLightWhite);
    }
    return false;
  }

  Future<bool> confirmReturned(String orderId, {double? refundAmount}) async {
    final accessToken = box.read('accessToken');
    try {
      final url = Uri.parse('$appBaseUrl/api/orders/$orderId/return-confirm');
      final resp = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
            refundAmount != null ? {'refundAmount': refundAmount} : {}),
      );
      if (resp.statusCode == 200) {
        Get.snackbar('Thành công', 'Đã xác nhận trả hàng/hoàn tiền',
            backgroundColor: Colors.green, colorText: kLightWhite);
        await fetchAllOrders();
        return true;
      } else {
        final data = jsonDecode(resp.body);
        Get.snackbar('Lỗi', data['message'] ?? 'Không thể xác nhận',
            backgroundColor: kRed, colorText: kLightWhite);
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Kết nối thất bại: $e',
          backgroundColor: kRed, colorText: kLightWhite);
    }
    return false;
  }
}
