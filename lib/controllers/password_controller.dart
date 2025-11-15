import 'package:get/get.dart';

class PasswordController extends GetxController {
  RxBool _password = false.obs;

  bool get password => _password.value;

  void setPassword() {
    _password.value = !_password.value;
  }
}
