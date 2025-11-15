import 'dart:convert';
import 'dart:math';

import 'package:appliances_flutter/models/store_response.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/api_error.dart';
import 'package:appliances_flutter/models/success_model.dart';
import 'package:appliances_flutter/views/auth/waiting_page.dart';

// ignore: camel_case_types'

class StoreController extends GetxController {
  final box = GetStorage();
  StoreResponse? store;
  RxBool _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  set isLoading(bool value) => _isLoading.value = value;

  String generateId() {
    int min = 0;
    int max = 10000;

    return (min + Random().nextInt(max - min)).toString();
  }

  StoreResponse getStoreData() {
    String? id = box.read("storeId");

    if (id != null) {
      String data = box.read(id);
      store = storeResponseFromJson(data);
    }
    return store!;
  }

  void storeRegistration(String data) async {
    String accessToken = box.read('accessToken');
    isLoading = true;

    Uri url = Uri.parse('$appBaseUrl/api/store');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    try {
      var response = await http.post(url, headers: headers, body: data);

      if (response.statusCode == 201) {
        var responseData = json.decode(response.body);

        // Lưu thông tin store
        if (responseData['store'] != null) {
          var storeData = responseData['store'];
          String storeId = storeData['_id'];

          // Lưu storeId và store data vào storage
          box.write('storeId', storeId);
          box.write(storeId, json.encode(storeData));
        }

        isLoading = false;
        Get.snackbar(
            colorText: kLightWhite,
            backgroundColor: kPrimary,
            'Thành công',
            responseData['message'] ?? 'Cửa hàng đã đăng ký thành công');

        // Điều hướng đến WaitingPage thay vì Login
        Get.offAll(() => const WaitingPage(),
            transition: kTransition, duration: kDuration);
      } else {
        var error = apiErrorFromJson(response.body);

        Get.snackbar(
            colorText: kLightWhite,
            backgroundColor: kPrimary,
            error.message,
            'Đăng ký cửa hàng thất bại, vui lòng thử lại');
      }
      isLoading = false;
    } catch (e) {
      isLoading = false;

      Get.snackbar(
          colorText: kLightWhite,
          backgroundColor: kPrimary,
          e.toString(),
          'Đăng ký cửa hàng thất bại, vui lòng thử lại');
    }
  }
}
