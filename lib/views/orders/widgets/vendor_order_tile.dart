import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/views/orders/widgets/order_detail_page.dart';

class VendorOrderTile extends StatelessWidget {
  final OrdersModel order;
  final VoidCallback? onStatusChanged;

  const VendorOrderTile({
    super.key,
    required this.order,
    this.onStatusChanged,
  });

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Đơn hàng mới';
      case 'Preparing':
        return 'Đang chuẩn bị';
      case 'Delivering':
        return 'Đang giao hàng';
      case 'Delivered':
        return 'Đã giao hàng';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Preparing':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return kGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = order.orderItems.length;
    final orderDate = order.createdAt;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(orderDate);

    return GestureDetector(
      onTap: () {
        Get.to(
          () => OrderDetailPage(order: order),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: kOffWhite,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: kGray.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ReusableText(
                    text: "Đơn #${order.id.substring(order.id.length - 6)}",
                    style: appStyle(14, kDark, FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.orderStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getStatusColor(order.orderStatus),
                      width: 1,
                    ),
                  ),
                  child: ReusableText(
                    text: _getStatusText(order.orderStatus),
                    style: appStyle(
                      11,
                      _getStatusColor(order.orderStatus),
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Date
            Row(
              children: [
                Icon(Icons.access_time, size: 14.sp, color: kGray),
                SizedBox(width: 4.w),
                ReusableText(
                  text: formattedDate,
                  style: appStyle(11, kGray, FontWeight.normal),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Customer info
            Row(
              children: [
                Icon(Icons.person_outline, size: 14.sp, color: kGray),
                SizedBox(width: 4.w),
                Expanded(
                  child: ReusableText(
                    text: order.userId.phone,
                    style: appStyle(12, kDark, FontWeight.w500),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Order items preview
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 14.sp, color: kGray),
                SizedBox(width: 4.w),
                Expanded(
                  child: ReusableText(
                    text: "$totalItems sản phẩm",
                    style: appStyle(12, kGray, FontWeight.normal),
                  ),
                ),
                ReusableText(
                  text: "${order.grandTotal.toStringAsFixed(0)}đ",
                  style: appStyle(14, kPrimary, FontWeight.bold),
                ),
              ],
            ),

            // Address
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 14.sp, color: kGray),
                SizedBox(width: 4.w),
                Expanded(
                  child: ReusableText(
                    text: order.deliveryAddress.addressLine1,
                    style: appStyle(11, kGray, FontWeight.normal),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
