import 'dart:convert';

import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/store_controller.dart';
import 'package:appliances_flutter/main.dart';
import 'package:appliances_flutter/models/api_error.dart';
import 'package:appliances_flutter/models/login_response.dart';
import 'package:appliances_flutter/models/store_response.dart';
import 'package:appliances_flutter/views/auth/login_page.dart';
import 'package:appliances_flutter/views/auth/store_registaration.dart';
import 'package:appliances_flutter/views/auth/verification_page.dart';
import 'package:appliances_flutter/views/auth/waiting_page.dart';
import 'package:appliances_flutter/views/home/home_page.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class LoginController extends GetxController {
  final controller = Get.put(StoreController());
  final box = GetStorage();
  StoreResponse? store;
  RxBool _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  set isLoading(bool value) => _isLoading.value = value;

  void logout() {
    box.erase();
    defaultHome = const Login();
    Get.offAll(() => defaultHome,
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 900));
  }

  void loginFunc(String data) async {
    isLoading = true;

    var url = Uri.parse('$appBaseUrl/login');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    try {
      var response = await http.post(url, body: data, headers: headers);

      if (response.statusCode == 200) {
        var data = loginResponseFromJson(response.body);

        box.write(data.id, json.encode(data));
        box.write('userId', data.id);
        box.write('accessToken', data.userToken);
        box.write('e-verification', data.verification);

        if (data.verification == false) {
          Get.snackbar(
            'Xác minh',
            'Vui lòng xác thực email của bạn',
            backgroundColor: kPrimary,
            colorText: kLightWhite,
          );

          Get.offAll(
            () => const VerificationPage(),
            transition: kTransition,
            duration: kDuration,
          );
        } else if (data.verification == true && data.userType == 'Client') {
          defaultHome = const Login();
          Get.offAll(
            () => const StoreRegistration(),
            transition: kTransition,
            duration: kDuration,
          );
        } else if (data.verification == true && data.userType == 'Vendor') {
          getVendorInfo(data.userToken);
        }
        isLoading = false;
      } else {
        var data = apiErrorFromJson(response.body);
        Get.snackbar(
          'Đăng nhập thất bại',
          data.message,
          backgroundColor: kPrimary,
          colorText: kLightWhite,
        );
        isLoading = false;
      }
    } catch (e) {
      isLoading = false;

      Get.snackbar(
        'Đăng nhập thất bại',
        e.toString(),
        backgroundColor: kPrimary,
        colorText: kLightWhite,
      );
    }
  }

  LoginResponse? getUserData() {
    String? id = box.read('userId');

    if (id != null) {
      return loginResponseFromJson(box.read(id));
    } else {
      return null;
    }
  }

  void getVendorInfo(String accessToken) async {
    isLoading = true;

    var url = Uri.parse('$appBaseUrl/api/store/owner/profile');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    };

    try {
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        StoreResponse storeData = storeResponseFromJson(response.body);
        store = storeData;
        controller.store = storeData;

        box.write("storeId", storeData.id);
        box.write("verification", storeData.verification);

        String data = storeResponseToJson(storeData);

        box.write(storeData.id, data);

        if (storeData.verification != "Đã xác minh") {
          Get.offAll(() => const WaitingPage(),
              transition: kTransition, duration: kDuration);
        } else {
          defaultHome = const HomePage();
          Get.offAll(() => const HomePage(),
              transition: kTransition, duration: kDuration);
        }

        isLoading = false;
      } else {
        var data = apiErrorFromJson(response.body);
        Get.snackbar(
          'Không thành công',
          data.message,
          backgroundColor: kPrimary,
          colorText: kLightWhite,
        );
        isLoading = false;
      }
    } catch (e) {
      isLoading = false;

      Get.snackbar(
        'Đăng nhập thất bại',
        e.toString(),
        backgroundColor: kPrimary,
        colorText: kLightWhite,
      );
    }
  }
}
