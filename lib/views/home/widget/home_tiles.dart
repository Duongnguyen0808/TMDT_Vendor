import 'package:appliances_flutter/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/home_tile.dart';
import 'package:appliances_flutter/views/add_appliances/add_appliances.dart';
import 'package:appliances_flutter/views/appliances/appliances_list.dart';
import 'package:appliances_flutter/views/wallet/wallet_page.dart';
import 'package:appliances_flutter/views/orders/orders_page.dart';

class HomeTiles extends StatelessWidget {
  const HomeTiles({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      height: 70.h,
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HomeTile(
                onTap: () {
                  Get.to(() => const AddAppliancess(),
                      transition: Transition.fadeIn,
                      duration: const Duration(milliseconds: 900));
                },
                text: "Thêm sản phẩm",
                icon: Icons.add_shopping_cart),
            HomeTile(
                onTap: () {
                  Get.to(() => const WalletPage(),
                      transition: Transition.fadeIn,
                      duration: const Duration(milliseconds: 900));
                },
                text: "Ví",
                icon: Icons.account_balance_wallet),
            HomeTile(
                onTap: () {
                  Get.to(() => const AppliancesList(),
                      transition: Transition.fadeIn,
                      duration: const Duration(milliseconds: 900));
                },
                text: "Sản phẩm",
                icon: Icons.kitchen),
            HomeTile(
                onTap: () {
                  Get.to(() => const OrdersPage(),
                      transition: Transition.fadeIn,
                      duration: const Duration(milliseconds: 900));
                },
                text: "Đơn hàng",
                icon: Icons.local_shipping),
          ],
        ),
      ),
    );
  }
}
