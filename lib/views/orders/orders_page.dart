import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:appliances_flutter/views/orders/widgets/vendor_order_tile.dart';
import 'package:appliances_flutter/controllers/chat_controller.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(VendorOrderController());
  final chatCtrl = Get.put(VendorChatController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // load unread summary for order tiles badges
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatCtrl.loadUnreadSummary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSecondary,
      appBar: AppBar(
        backgroundColor: kSecondary,
        title: ReusableText(
          text: "Đơn hàng",
          style: appStyle(18, kLightWhite, FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: kLightWhite),
            onPressed: () => controller.fetchAllOrders(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: kLightWhite,
          unselectedLabelColor: kGrayLight,
          indicatorColor: kPrimary,
          isScrollable: true,
          labelStyle: appStyle(12, kLightWhite, FontWeight.w600),
          unselectedLabelStyle: appStyle(12, kGrayLight, FontWeight.normal),
          tabs: [
            Tab(
                child: _buildTabWithBadge(
                    "Chờ xác nhận", controller.pendingOrders)),
            Tab(
                child: _buildTabWithBadge(
                    "Đang chuẩn bị", controller.preparingOrders)),
            Tab(
                child: _buildTabWithBadge(
                    "Tìm shipper", controller.waitingShipperOrders)),
            Tab(
                child: _buildTabWithBadge(
                    "Đang vận chuyển", controller.deliveringOrders)),
            Tab(
                child:
                    _buildTabWithBadge("Đã giao", controller.deliveredOrders)),
            Tab(
                child:
                    _buildTabWithBadge("Đã hủy", controller.cancelledOrders)),
          ],
        ),
      ),
      body: BackGroundContainer(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersList(controller.pendingOrders, "Chờ xác nhận"),
            _buildOrdersList(controller.preparingOrders, "Đang chuẩn bị"),
            _buildOrdersList(controller.waitingShipperOrders, "Tìm shipper"),
            _buildOrdersList(controller.deliveringOrders, "Đang vận chuyển"),
            _buildOrdersList(controller.deliveredOrders, "Đã giao"),
            _buildOrdersList(controller.cancelledOrders, "Đã hủy"),
          ],
        ),
      ),
    );
  }

  Widget _buildTabWithBadge(String title, RxList<dynamic> list) {
    return Obx(() {
      final displayCount = list.length; // reactive dependency registered here
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (displayCount > 0) ...[
            SizedBox(width: 4.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$displayCount',
                style: appStyle(10, kLightWhite, FontWeight.bold),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildOrdersList(RxList orders, String status) {
    return Obx(() {
      if (orders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80.sp,
                color: kGrayLight,
              ),
              SizedBox(height: 16.h),
              ReusableText(
                text: "Chưa có đơn hàng $status",
                style: appStyle(14, kGray, FontWeight.normal),
              ),
              SizedBox(height: 8.h),
              ReusableText(
                text: "Đơn hàng sẽ hiển thị ở đây khi có khách đặt",
                style: appStyle(12, kGray, FontWeight.w300),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchAllOrders(),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return VendorOrderTile(
              order: orders[index],
              onStatusChanged: () => controller.fetchAllOrders(),
            );
          },
        ),
      );
    });
  }
}
