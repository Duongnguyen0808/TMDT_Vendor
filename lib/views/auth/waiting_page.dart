import 'package:appliances_flutter/controllers/login_controller.dart';
import 'package:appliances_flutter/controllers/store_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/custom_button.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/views/auth/login_page.dart';

class WaitingPage extends StatefulWidget {
  const WaitingPage({super.key});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  final storeController = Get.put(StoreController());
  final loginController = Get.put(LoginController());
  final box = GetStorage();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    storeController.store = storeController.getStoreData();
  }

  void checkVerification() async {
    setState(() {
      isLoading = true;
    });

    String? accessToken = box.read('accessToken');
    if (accessToken != null) {
      loginController.getVendorInfo(accessToken);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackGroundContainer(
          color: Colors.white,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 50.h, 24.w, 20.h),
              child: Column(
                children: [
                  SizedBox(
                    height: 250.h,
                    child: Lottie.asset('assets/anime/delivery.json'),
                  ),
                  SizedBox(height: 20.h),
                  ReusableText(
                      text: storeController.store?.title ?? "",
                      style: appStyle(18, kPrimary, FontWeight.bold)),
                  SizedBox(
                    height: 10.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: ReusableText(
                            text:
                                "Trạng thái: ${storeController.store?.verification ?? ''}",
                            style: appStyle(14, kGray, FontWeight.bold)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.to(
                            () => const Login(),
                          );
                        },
                        child: ReusableText(
                            text: "Thử đăng nhập",
                            style: appStyle(14, kTertiary, FontWeight.bold)),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Text(
                    storeController.store?.verificationMessage ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                      color: kGray,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  CustomButton(
                    text: isLoading
                        ? "Đang kiểm tra..."
                        : "KIỂM TRA LẠI TRẠNG THÁI",
                    btnHieght: 45.h,
                    onTap: isLoading ? null : checkVerification,
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
