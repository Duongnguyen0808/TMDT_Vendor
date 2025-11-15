import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/store_controller.dart';
import 'package:appliances_flutter/views/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoreController());
    controller.getStoreData();
    return Container(
      width: width,
      height: 150.h,
      padding: EdgeInsets.fromLTRB(12.w, 40.h, 12.w, 10.h),
      color: kPrimary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.network(
                      controller.store!.logoUrl,
                      width: 36.r,
                      height: 36.r,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.store,
                          size: 20.r,
                          color: kPrimary,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kPrimary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReusableText(
                          text: controller.store!.title,
                          style: appStyle(13, Colors.white, FontWeight.bold)),
                      SizedBox(height: 3.h),
                      Text(controller.store!.coords.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appStyle(10, Colors.white, FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => _handleLogout(context),
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.logout,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    final box = GetStorage();
    box.erase();
    Get.offAll(() => const Login(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 900));
  }
}
