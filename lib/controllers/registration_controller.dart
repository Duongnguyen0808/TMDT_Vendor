import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/success_model.dart';
import 'package:appliances_flutter/views/auth/login_page.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RegistrationController extends GetxController {
  RxBool _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  set isLoading(bool value) => _isLoading.value = value;

  void registration(String data) async {
    isLoading = true;

    var url = Uri.parse('$appBaseUrl/register');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    try {
      var response = await http.post(url, body: data, headers: headers);

      if (response.statusCode == 201) {
        var data = successResponseFromJson(response.body);

        Get.snackbar(
          'Đăng ký thành công, vui lòng đăng nhập',
          data.message,
          backgroundColor: kPrimary,
          colorText: kLightWhite,
        );

        isLoading = false;
        Get.to(
          () => const Login(),
          transition: kTransition,
          duration: kDuration,
        );
      } else {
        var data = successResponseFromJson(response.body);
        Get.snackbar(
          'Thành công',
          data.message,
          backgroundColor: kPrimary,
          colorText: kLightWhite,
        );
        isLoading = false;
      }
    } catch (e) {
      isLoading = false;

      Get.snackbar(
        'Lỗi',
        e.toString(),
        backgroundColor: kPrimary,
        colorText: kLightWhite,
      );
    }
  }
}
