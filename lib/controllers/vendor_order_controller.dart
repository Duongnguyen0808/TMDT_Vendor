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
  RxList<OrdersModel> deliveringOrders = <OrdersModel>[].obs;
  RxList<OrdersModel> deliveredOrders = <OrdersModel>[].obs;
  RxList<OrdersModel> cancelledOrders = <OrdersModel>[].obs;

  String get storeId => box.read('storeId') ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchAllOrders();
  }

  Future<void> fetchAllOrders() async {
    await Future.wait([
      fetchOrdersByStatus('Pending'),
      fetchOrdersByStatus('Preparing'),
      fetchOrdersByStatus('Delivering'),
      fetchOrdersByStatus('Delivered'),
      fetchOrdersByStatus('Cancelled'),
    ]);
  }

  Future<void> fetchOrdersByStatus(String status) async {
    String accessToken = box.read('accessToken');

    try {
      final url = Uri.parse('$appBaseUrl/api/orders/store/$storeId/$status');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<OrdersModel> orders =
            data.map((json) => OrdersModel.fromJson(json)).toList();

        switch (status) {
          case 'Pending':
            pendingOrders.value = orders;
            break;
          case 'Preparing':
            preparingOrders.value = orders;
            break;
          case 'Delivering':
            deliveringOrders.value = orders;
            break;
          case 'Delivered':
            deliveredOrders.value = orders;
            break;
          case 'Cancelled':
            cancelledOrders.value = orders;
            break;
        }
      }
    } catch (e) {
      print('Error fetching $status orders: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    String accessToken = box.read('accessToken');
    isLoading.value = true;

    try {
      final url =
          Uri.parse('$appBaseUrl/api/orders/$orderId?status=$newStatus');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
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

        // Go back
        Get.back();
      } else {
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
