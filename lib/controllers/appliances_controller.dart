// ignore_for_file: prefer_final_fields

import 'dart:math';

import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/add_appliances_models.dart';
import 'package:appliances_flutter/models/api_error.dart';
import 'package:appliances_flutter/models/success_model.dart';
import 'package:appliances_flutter/views/home/home_page.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:http/http.dart' as http;

class AppliancesController extends GetxController {
  final box = GetStorage();

  RxBool _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  set isLoading(bool value) => _isLoading.value = value;

  String _category = '';

  String get category => _category;

  set setCategory(String newValue) {
    _category = newValue;
  }

  RxList<String> _types = <String>[].obs;

  RxList<String> get types => _types;

  set setTypes(String newValue) {
    _types.add(newValue);
  }

  int generateId() {
    int min = 0;
    int max = 10000;

    return min + Random().nextInt(max - min);
  }

  RxList<Additive> _additivesList = <Additive>[].obs;

  List<Additive> get additivesList => _additivesList;

  set addAdditive(Additive newValue) {
    _additivesList.add(newValue);
  }

  void clearAdditives() {
    _additivesList.clear();
  }

  RxList<String> _tags = <String>[].obs;

  RxList<String> get tags => _tags;

  set setTags(String newValue) {
    _tags.add(newValue);
  }

  void addappliancessFunction(String data) async {
    String accessToken = box.read('accessToken');
    isLoading = true;

    Uri url = Uri.parse('$appBaseUrl/api/appliances');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    try {
      var response = await http.post(url, headers: headers, body: data);

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        var data = successResponseFromJson(response.body);
        isLoading = false;
        Get.snackbar(
            colorText: kLightWhite,
            backgroundColor: kPrimary,
            'Thành công',
            data.message);
        Get.offAll(() => const HomePage(),
            transition: kTransition, duration: kDuration);
      } else {
        isLoading = false;
        try {
          var errorData = apiErrorFromJson(response.body);
          Get.snackbar(
              colorText: kLightWhite,
              backgroundColor: kRed,
              'Không thể tải lên',
              errorData.message,
              duration: const Duration(seconds: 5));
        } catch (e) {
          Get.snackbar(
              colorText: kLightWhite,
              backgroundColor: kRed,
              'Lỗi server',
              'Response: ${response.body}',
              duration: const Duration(seconds: 5));
        }
      }
    } catch (e) {
      isLoading = false;
      print('Exception: $e');
      Get.snackbar(
          colorText: kLightWhite,
          backgroundColor: kRed,
          'Lỗi kết nối',
          'Không thể kết nối đến server. Chi tiết: ${e.toString()}',
          duration: const Duration(seconds: 5));
    }
  }

  // Cập nhật sản phẩm
  Future<bool> updateAppliancesFunction(
      String appliancesId, String data) async {
    String accessToken = box.read('accessToken');
    isLoading = true;

    Uri url = Uri.parse('$appBaseUrl/api/appliances/$appliancesId');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    try {
      var response = await http.put(url, headers: headers, body: data);

      print('Update Status code: ${response.statusCode}');
      print('Update Response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = successResponseFromJson(response.body);
        isLoading = false;
        Get.snackbar('Thành công', data.message,
            colorText: kLightWhite,
            backgroundColor: kPrimary,
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.TOP);

        // Đợi một chút để snackbar hiển thị trước khi navigate
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back(result: true); // Trả về true khi thành công
        return true;
      } else {
        isLoading = false;
        try {
          var errorData = apiErrorFromJson(response.body);
          Get.snackbar(
              colorText: kLightWhite,
              backgroundColor: kRed,
              'Không thể cập nhật',
              errorData.message,
              duration: const Duration(seconds: 5));
        } catch (e) {
          Get.snackbar(
              colorText: kLightWhite,
              backgroundColor: kRed,
              'Lỗi server',
              'Response: ${response.body}',
              duration: const Duration(seconds: 5));
        }
        return false;
      }
    } catch (e) {
      isLoading = false;
      print('Exception: $e');
      Get.snackbar(
          colorText: kLightWhite,
          backgroundColor: kRed,
          'Lỗi kết nối',
          'Không thể kết nối đến server. Chi tiết: ${e.toString()}',
          duration: const Duration(seconds: 5));
      return false;
    }
  }

  // Xóa sản phẩm
  Future<bool> deleteAppliancesFunction(String appliancesId) async {
    String accessToken = box.read('accessToken');
    isLoading = true;

    Uri url = Uri.parse('$appBaseUrl/api/appliances/$appliancesId');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    try {
      var response = await http.delete(url, headers: headers);

      print('Delete Status code: ${response.statusCode}');
      print('Delete Response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = successResponseFromJson(response.body);
        isLoading = false;
        Get.snackbar(
            colorText: kLightWhite,
            backgroundColor: kPrimary,
            'Thành công',
            data.message);
        return true;
      } else {
        isLoading = false;
        try {
          var errorData = apiErrorFromJson(response.body);
          Get.snackbar(
              colorText: kLightWhite,
              backgroundColor: kRed,
              'Không thể xóa',
              errorData.message,
              duration: const Duration(seconds: 5));
        } catch (e) {
          Get.snackbar(
              colorText: kLightWhite,
              backgroundColor: kRed,
              'Lỗi server',
              'Response: ${response.body}',
              duration: const Duration(seconds: 5));
        }
        return false;
      }
    } catch (e) {
      isLoading = false;
      print('Exception: $e');
      Get.snackbar(
          colorText: kLightWhite,
          backgroundColor: kRed,
          'Lỗi kết nối',
          'Không thể kết nối đến server. Chi tiết: ${e.toString()}',
          duration: const Duration(seconds: 5));
      return false;
    }
  }
}
