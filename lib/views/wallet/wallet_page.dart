import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final storeName = box.read('storeName') ?? 'Cửa hàng';

    return Scaffold(
      backgroundColor: kSecondary,
      appBar: AppBar(
        backgroundColor: kSecondary,
        title: ReusableText(
          text: "Ví của tôi",
          style: appStyle(18, kLightWhite, FontWeight.w600),
        ),
      ),
      body: BackGroundContainer(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Wallet Balance Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, kSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text: "Số dư khả dụng",
                      style: appStyle(14, kLightWhite, FontWeight.normal),
                    ),
                    SizedBox(height: 10.h),
                    ReusableText(
                      text: "0đ",
                      style: appStyle(32, kLightWhite, FontWeight.bold),
                    ),
                    SizedBox(height: 10.h),
                    ReusableText(
                      text: storeName,
                      style: appStyle(
                          12, kLightWhite.withOpacity(0.8), FontWeight.normal),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.add_circle_outline,
                    label: "Nạp tiền",
                    onTap: () {
                      Get.snackbar(
                        "Thông báo",
                        "Tính năng đang phát triển",
                        backgroundColor: kPrimary,
                        colorText: kLightWhite,
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.remove_circle_outline,
                    label: "Rút tiền",
                    onTap: () {
                      Get.snackbar(
                        "Thông báo",
                        "Tính năng đang phát triển",
                        backgroundColor: kPrimary,
                        colorText: kLightWhite,
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.history,
                    label: "Lịch sử",
                    onTap: () {
                      Get.snackbar(
                        "Thông báo",
                        "Tính năng đang phát triển",
                        backgroundColor: kPrimary,
                        colorText: kLightWhite,
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 30.h),

              // Transaction History Section
              Align(
                alignment: Alignment.centerLeft,
                child: ReusableText(
                  text: "Lịch sử giao dịch",
                  style: appStyle(16, kDark, FontWeight.w600),
                ),
              ),
              SizedBox(height: 15.h),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80.sp,
                        color: kGrayLight,
                      ),
                      SizedBox(height: 16.h),
                      ReusableText(
                        text: "Chưa có giao dịch nào",
                        style: appStyle(14, kGray, FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: kOffWhite,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: kGrayLight.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: kPrimary, size: 28.sp),
            SizedBox(height: 8.h),
            ReusableText(
              text: label,
              style: appStyle(11, kDark, FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
