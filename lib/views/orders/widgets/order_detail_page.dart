import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/custom_button.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatelessWidget {
  final OrdersModel order;

  const OrderDetailPage({super.key, required this.order});

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ xác nhận';
      case 'Preparing':
        return 'Đang chuẩn bị';
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
    final controller = Get.find<VendorOrderController>();
    final orderDate = order.createdAt;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(orderDate);

    return Scaffold(
      backgroundColor: kSecondary,
      appBar: AppBar(
        backgroundColor: kSecondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: kLightWhite),
          onPressed: () => Get.back(),
        ),
        title: ReusableText(
          text: "Chi tiết đơn hàng",
          style: appStyle(18, kLightWhite, FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          BackGroundContainer(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // Order Status Card
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(order.orderStatus).withOpacity(0.8),
                        _getStatusColor(order.orderStatus),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        size: 48.sp,
                        color: kLightWhite,
                      ),
                      SizedBox(height: 8.h),
                      ReusableText(
                        text: _getStatusText(order.orderStatus),
                        style: appStyle(18, kLightWhite, FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      ReusableText(
                        text: "Đơn #${order.id.substring(order.id.length - 6)}",
                        style: appStyle(12, kLightWhite, FontWeight.normal),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Customer Info
                _buildInfoCard(
                  title: "Thông tin khách hàng",
                  children: [
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: "Số điện thoại",
                      value: order.userId.phone,
                    ),
                    SizedBox(height: 8.h),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: "Địa chỉ giao hàng",
                      value: order.deliveryAddress.addressLine1,
                    ),
                    SizedBox(height: 8.h),
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: "Thời gian đặt",
                      value: formattedDate,
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Order Items
                _buildInfoCard(
                  title: "Danh sách sản phẩm",
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: order.orderItems.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 16.h),
                      itemBuilder: (context, index) {
                        final item = order.orderItems[index];
                        return Row(
                          children: [
                            Container(
                              width: 60.w,
                              height: 60.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.network(
                                  item.appliancesId.imageUrl[0],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: kGrayLight,
                                      child: Icon(Icons.image, color: kGray),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ReusableText(
                                    text: item.appliancesId.title,
                                    style: appStyle(13, kDark, FontWeight.w600),
                                  ),
                                  SizedBox(height: 4.h),
                                  ReusableText(
                                    text: "x${item.quantity}",
                                    style:
                                        appStyle(12, kGray, FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                            ReusableText(
                              text: "${item.price.toStringAsFixed(0)}đ",
                              style: appStyle(13, kPrimary, FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Payment Summary
                _buildInfoCard(
                  title: "Thanh toán",
                  children: [
                    _buildPriceRow("Tạm tính", order.orderTotal),
                    SizedBox(height: 8.h),
                    _buildPriceRow("Phí giao hàng", order.deliveryFee),
                    SizedBox(height: 8.h),
                    Divider(),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ReusableText(
                          text: "Tổng cộng",
                          style: appStyle(14, kDark, FontWeight.bold),
                        ),
                        ReusableText(
                          text: "${order.grandTotal.toStringAsFixed(0)}đ",
                          style: appStyle(16, kPrimary, FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 100.h), // Space for buttons
              ],
            ),
          ),

          // Action Buttons at bottom
          if (order.orderStatus != 'Delivered' &&
              order.orderStatus != 'Cancelled')
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: kOffWhite,
                  boxShadow: [
                    BoxShadow(
                      color: kGray.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Obx(() => controller.isLoading.value
                    ? Center(child: CircularProgressIndicator(color: kPrimary))
                    : _buildActionButtons(controller)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(VendorOrderController controller) {
    switch (order.orderStatus) {
      case 'Pending':
        return CustomButton(
          text: "CHẤP NHẬN ĐƠN",
          btnWidth: width,
          btnColor: kPrimary,
          btnHieght: 45,
          btnRadius: 12,
          onTap: () async {
            await controller.updateOrderStatus(order.id, 'Preparing');
          },
        );

      case 'Preparing':
        return CustomButton(
          text: "SẴN SÀNG GIAO HÀNG",
          btnWidth: width,
          btnColor: kPrimary,
          btnHieght: 45,
          btnRadius: 12,
          onTap: () async {
            await controller.updateOrderStatus(order.id, 'Delivering');
          },
        );

      case 'Delivering':
        return CustomButton(
          text: "ĐÃ GIAO HÀNG",
          btnWidth: width,
          btnColor: Colors.green,
          btnHieght: 45,
          btnRadius: 12,
          onTap: () async {
            await controller.updateOrderStatus(order.id, 'Delivered');
          },
        );

      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReusableText(
            text: title,
            style: appStyle(14, kDark, FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: kGray),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReusableText(
                text: label,
                style: appStyle(11, kGray, FontWeight.normal),
              ),
              SizedBox(height: 2.h),
              ReusableText(
                text: value,
                style: appStyle(13, kDark, FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ReusableText(
          text: label,
          style: appStyle(13, kGray, FontWeight.normal),
        ),
        ReusableText(
          text: "${amount.toStringAsFixed(0)}đ",
          style: appStyle(13, kDark, FontWeight.w500),
        ),
      ],
    );
  }
}
