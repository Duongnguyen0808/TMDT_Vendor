import 'dart:convert';

import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/login_response.dart';
import 'package:appliances_flutter/models/success_model.dart';
import 'package:appliances_flutter/views/auth/login_page.dart';
import 'package:appliances_flutter/views/auth/store_registaration.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:http/http.dart' as http;

// ignore: camel_case_types'

class EmailVerificationController extends GetxController {
  final box = GetStorage();
  RxBool _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  set isLoading(bool value) => _isLoading.value = value;

  RxString _code = ''.obs;

  String get code => _code.value;

  void setCode(String value) => _code.value = value;

  void verifyEmail(String code) async {
    isLoading = true;
    String accessToken = box.read('accessToken');

    var url = Uri.parse("$appBaseUrl/api/users/verify/$code");

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    try {
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        LoginResponse data = loginResponseFromJson(response.body);

        box.write(data.id, json.encode(data));
        box.write('accessToken', data.userToken);
        box.write('e-verification', data.verification);

        Get.snackbar(
          'Xác minh tài khoản thành công',
          'Chúc bạn có trải nghiệm tuyệt vời',
          backgroundColor: kPrimary,
          colorText: kLightWhite,
        );

        if (data.userType == 'Client') {
          Get.offAll(() => const StoreRegistration(),
              transition: kTransition, duration: kDuration);
        } else {
          Get.offAll(() => const Login(),
              transition: kTransition, duration: kDuration);
        }
        isLoading = false;
      } else {
        var data = successResponseFromJson(response.body);
        Get.snackbar(
          'Không thể xác minh tài khoản',
          data.message,
          backgroundColor: kPrimary,
          colorText: kLightWhite,
        );
        isLoading = false;
      }
    } catch (e) {
      Get.snackbar(
        'Không thể xác minh tài khoản',
        e.toString(),
        backgroundColor: kPrimary,
        colorText: kLightWhite,
      );
      isLoading = false;
    }
  }
}

// 466010
