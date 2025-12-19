import 'dart:convert';

import 'package:appliances_flutter/constants/constants.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class VendorDriverController extends GetxController {
  final box = GetStorage();
  RxList<Map<String, dynamic>> drivers = <Map<String, dynamic>>[].obs;
  RxBool loading = false.obs;

  String? get token => box.read('token');

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<void> fetchDrivers() async {
    loading.value = true;
    final url = Uri.parse('$appBaseUrl/api/drivers');
    final res = await http.get(url, headers: _headers());
    loading.value = false;
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body)['data'] ?? [];
      drivers.assignAll(data.map((e) => Map<String, dynamic>.from(e)));
    }
  }

  Future<bool> createDriver({
    required String username,
    required String email,
    required String password,
    String? phone,
    String? vehicleType,
    String? vehiclePlate,
    String? note,
  }) async {
    final url = Uri.parse('$appBaseUrl/api/drivers');
    final body = jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
      if (note != null) 'note': note,
    });
    final res = await http.post(url, headers: _headers(), body: body);
    if (res.statusCode == 201) {
      await fetchDrivers();
      return true;
    }
    return false;
  }

  Future<bool> updateDriver(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$appBaseUrl/api/drivers/$id');
    final res =
        await http.patch(url, headers: _headers(), body: jsonEncode(data));
    if (res.statusCode == 200) {
      await fetchDrivers();
      return true;
    }
    return false;
  }

  Future<bool> assignDriverToOrder(String orderId, String driverId) async {
    final url = Uri.parse('$appBaseUrl/api/drivers/assign');
    final res = await http.post(url,
        headers: _headers(),
        body: jsonEncode({
          'orderId': orderId,
          'driverId': driverId,
        }));
    return res.statusCode == 200;
  }

  Future<bool> unassignDriverFromOrder(String orderId) async {
    final url = Uri.parse('$appBaseUrl/api/drivers/unassign');
    final res = await http.post(url,
        headers: _headers(), body: jsonEncode({'orderId': orderId}));
    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getDriverByUser(String userId) async {
    final url = Uri.parse('$appBaseUrl/api/drivers/by-user/$userId');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'];
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
}
