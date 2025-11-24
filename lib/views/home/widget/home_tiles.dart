import 'package:appliances_flutter/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/home_tile.dart';
import 'package:appliances_flutter/views/add_appliances/add_appliances.dart';
import 'package:appliances_flutter/views/appliances/appliances_list.dart';
import 'package:appliances_flutter/views/wallet/wallet_page.dart';
import 'package:appliances_flutter/views/orders/orders_page.dart';
import 'package:appliances_flutter/views/orders/return_center_page.dart';
import 'package:appliances_flutter/views/profile/vendor_profile_page.dart';
import 'package:appliances_flutter/views/support/service_center_page.dart';

class HomeTiles extends StatelessWidget {
  const HomeTiles({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = [
      HomeTile(
          onTap: () {
            Get.to(() => const AddAppliancess(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 600));
          },
          text: "Thêm sản phẩm",
          icon: Icons.add_shopping_cart),
      HomeTile(
          onTap: () {
            Get.to(() => const AppliancesList(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 600));
          },
          text: "Sản phẩm",
          icon: Icons.inventory_2),
      HomeTile(
          onTap: () {
            Get.to(() => const OrdersPage(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 600));
          },
          text: "Đơn hàng",
          icon: Icons.local_shipping),
      HomeTile(
          onTap: () {
            Get.to(() => const ReturnCenterPage(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 600));
          },
          text: "Trả hàng",
          icon: Icons.assignment_return),
      HomeTile(
          onTap: () {
            Get.to(() => const WalletPage(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 600));
          },
          text: "Ví",
          icon: Icons.account_balance_wallet),
      HomeTile(
          onTap: () {
            Get.to(() => const VendorProfilePage(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 600));
          },
          text: "Hồ sơ",
          icon: Icons.storefront),
      HomeTile(
          onTap: () {
            Get.to(() => const ServiceCenterPage(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 600));
          },
          text: "Dịch vụ",
          icon: Icons.support_agent),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.w,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.9, // wider tiles
        ),
        itemBuilder: (_, i) {
          return _BigTile(child: tiles[i]);
        },
      ),
    );
  }
}

class _BigTile extends StatelessWidget {
  final Widget child;
  const _BigTile({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kPrimary.withOpacity(.15)),
        color: kOffWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
