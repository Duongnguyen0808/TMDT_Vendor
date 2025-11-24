import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/custom_button.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';

class OrderDetailPage extends StatelessWidget {
  final OrdersModel order;
  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VendorOrderController>()
        ? Get.find<VendorOrderController>()
        : Get.put(VendorOrderController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng #${order.id.substring(0, 8)}'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderStatus(),
                  if (order.pickupCheckinAt != null) ...[
                    SizedBox(height: 12.h),
                    _buildShipperArrivalCard(),
                  ],
                  SizedBox(height: 16.h),
                  _buildCustomerInfo(),
                  SizedBox(height: 16.h),
                  _buildReturnSection(controller),
                  SizedBox(height: 16.h),
                  _buildItemsSection(),
                  SizedBox(height: 16.h),
                  _buildPaymentSection(),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
          if (order.orderStatus != 'Delivered' &&
              order.orderStatus != 'Cancelled')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: kOffWhite,
                  boxShadow: [
                    BoxShadow(
                      color: kGray.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Obx(() => controller.isLoading.value
                    ? Center(child: CircularProgressIndicator(color: kPrimary))
                    : _buildActionButtons(context, controller)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatus() {
    final hasDriver = order.driverId != null && order.driverId!.isNotEmpty;
    Color statusColor;
    String statusLabel;
    String? statusNote;

    switch (order.orderStatus) {
      case 'Pending':
        statusColor = Colors.orange;
        statusLabel = 'Đơn hàng mới';
        break;
      case 'Preparing':
        statusColor = Colors.blue;
        statusLabel = 'Đang chuẩn bị';
        break;
      case 'WaitingShipper':
        if (hasDriver) {
          statusColor = Colors.teal;
          statusLabel = 'Shipper đã nhận';
          statusNote = 'Tài xế đang trên đường đến cửa hàng để nhận hàng.';
        } else {
          statusColor = Colors.purple;
          statusLabel = 'Đang tìm shipper';
          statusNote =
              'Hệ thống sẽ tiếp tục tìm tài xế sẵn sàng nhận đơn cho bạn.';
        }
        break;
      case 'PickedUp':
        statusColor = Colors.blueGrey;
        statusLabel = 'Đang lấy hàng';
        statusNote = 'Shipper đang bàn giao hàng với cửa hàng.';
        break;
      case 'Delivering':
        statusColor = Colors.green;
        statusLabel = 'Đang giao hàng';
        break;
      case 'Delivered':
        statusColor = Colors.teal;
        statusLabel = 'Đã giao hàng';
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusLabel = 'Đã hủy';
        break;
      default:
        statusColor = kPrimary;
        statusLabel = order.orderStatus;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient:
            LinearGradient(colors: [statusColor.withOpacity(.15), kOffWhite]),
        border: Border.all(color: statusColor.withOpacity(.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: statusColor),
              SizedBox(width: 8.w),
              Expanded(
                child: ReusableText(
                  text: 'Trạng thái: $statusLabel',
                  style: appStyle(13, kDark, FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (statusNote != null) ...[
            ReusableText(
              text: statusNote,
              style: appStyle(12, kDark, FontWeight.w500),
            ),
            SizedBox(height: 6.h),
          ],
        ],
      ),
    );
  }

  Widget _buildShipperArrivalCard() {
    final checkin = order.pickupCheckinAt;
    if (checkin == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.blueGrey.withOpacity(.08),
        border: Border.all(color: Colors.blueGrey.withOpacity(.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.directions_bike, color: Colors.blueGrey.shade600),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: 'Shipper đã báo có mặt',
                  style: appStyle(13, kDark, FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                ReusableText(
                  text:
                      'Vui lòng bàn giao hàng và xác nhận "ĐÃ GIAO HÀNG CHO SHIPPER".',
                  style: appStyle(12, kGray, FontWeight.w400),
                ),
                SizedBox(height: 4.h),
                ReusableText(
                  text: 'Thời gian: ${_formatDateTime(checkin)}',
                  style: appStyle(12, kGray, FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return _buildInfoCard(title: 'Thông tin khách hàng', children: [
      _buildInfoRow(
          icon: Icons.phone,
          label: 'SĐT',
          value:
              order.userId.phone.isNotEmpty ? order.userId.phone : 'Không có'),
      SizedBox(height: 8.h),
      _buildInfoRow(
          icon: Icons.location_on,
          label: 'Địa chỉ',
          value: order.deliveryAddress.addressLine1.isNotEmpty
              ? order.deliveryAddress.addressLine1
              : 'Không có'),
    ]);
  }

  Widget _buildReturnSection(VendorOrderController controller) {
    return FutureBuilder<OrdersModel?>(
      future: controller.fetchOrderDetail(order.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
            ),
          );
        }
        final detail = snap.data;
        final rs = detail?.returnStatus ?? 'None';
        if (detail == null || rs == 'None') {
          return const SizedBox.shrink();
        }
        return _buildInfoCard(title: 'Trả hàng/Hoàn tiền', children: [
          Row(
            children: [
              Icon(Icons.assignment_return, size: 18.sp, color: kGray),
              SizedBox(width: 8.w),
              Expanded(
                child: ReusableText(
                  text: _mapReturnStatus(rs),
                  style: appStyle(13, kDark, FontWeight.w600),
                ),
              ),
            ],
          ),
          if ((detail.returnReason ?? '').isNotEmpty) ...[
            SizedBox(height: 6.h),
            ReusableText(
              text: 'Lý do: ${detail.returnReason}',
              style: appStyle(12, kGray, FontWeight.w400),
            ),
          ],
          if ((rs == 'Requested') || (rs == 'Approved')) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 10.w,
              children: [
                if (rs == 'Requested')
                  ElevatedButton(
                    onPressed: () async {
                      final ok =
                          await controller.reviewReturn(order.id, 'approve');
                      if (ok) {
                        final refreshed =
                            await controller.fetchOrderDetail(order.id);
                        if (refreshed != null) {
                          Get.off(() => OrderDetailPage(order: refreshed));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: kLightWhite),
                    child: const Text('Duyệt'),
                  ),
                if (rs == 'Requested')
                  ElevatedButton(
                    onPressed: () async {
                      final ok =
                          await controller.reviewReturn(order.id, 'reject');
                      if (ok) {
                        final refreshed =
                            await controller.fetchOrderDetail(order.id);
                        if (refreshed != null) {
                          Get.off(() => OrderDetailPage(order: refreshed));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: kLightWhite),
                    child: const Text('Từ chối'),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    final ctrl = TextEditingController(
                        text: formatVND(detail.grandTotal));
                    final amount = await showDialog<double?>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Xác nhận hoàn / trả'),
                        content: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số tiền hoàn (đ)',
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Get.back(result: null),
                              child: const Text('Hủy')),
                          TextButton(
                            onPressed: () {
                              final v = double.tryParse(ctrl.text
                                  .replaceAll('.', '')
                                  .replaceAll(',', ''));
                              Get.back(result: v);
                            },
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    );
                    if (amount == null) return;
                    final ok = await controller.confirmReturned(order.id,
                        refundAmount: amount);
                    if (ok) {
                      final refreshed =
                          await controller.fetchOrderDetail(order.id);
                      if (refreshed != null) {
                        Get.off(() => OrderDetailPage(order: refreshed));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: kLightWhite),
                  child: const Text('Xác nhận hoàn'),
                ),
              ],
            ),
          ],
          if (rs == 'Refunded') ...[
            SizedBox(height: 8.h),
            ReusableText(
              text: 'Đã hoàn: ${formatVND(detail.refundAmount ?? 0)}đ',
              style: appStyle(12, kGray, FontWeight.w400),
            ),
          ],
        ]);
      },
    );
  }

  Widget _buildItemsSection() {
    return _buildInfoCard(title: 'Danh sách sản phẩm', children: [
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: order.orderItems.length,
        separatorBuilder: (_, __) => Divider(height: 16.h),
        itemBuilder: (_, i) {
          final item = order.orderItems[i];
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
                    errorBuilder: (_, __, ___) => Container(
                      color: kGrayLight,
                      child: Icon(Icons.image, color: kGray),
                    ),
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
                    Row(
                      children: [
                        ReusableText(
                          text: 'x${item.quantity}',
                          style: appStyle(12, kGray, FontWeight.normal),
                        ),
                        SizedBox(width: 8.w),
                        if (item.appliancesId.stock != null)
                          Row(
                            children: [
                              Icon(Icons.inventory_2,
                                  size: 12.sp,
                                  color: (item.appliancesId.stock ?? 0) > 0
                                      ? kGray
                                      : Colors.red),
                              SizedBox(width: 2.w),
                              ReusableText(
                                text: 'Tồn: ${item.appliancesId.stock}',
                                style: appStyle(
                                    11,
                                    (item.appliancesId.stock ?? 0) > 0
                                        ? kGray
                                        : Colors.red,
                                    FontWeight.w500),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              ReusableText(
                text: '${formatVND(item.price)}đ',
                style: appStyle(13, kPrimary, FontWeight.bold),
              ),
            ],
          );
        },
      ),
    ]);
  }

  Widget _buildPaymentSection() {
    return _buildInfoCard(title: 'Thanh toán', children: [
      _buildPriceRow('Tạm tính', order.orderTotal),
      SizedBox(height: 8.h),
      _buildPriceRow('Phí giao hàng', order.deliveryFee),
      SizedBox(height: 8.h),
      const Divider(),
      SizedBox(height: 8.h),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ReusableText(
            text: 'Tổng cộng',
            style: appStyle(14, kDark, FontWeight.bold),
          ),
          ReusableText(
            text: '${formatVND(order.grandTotal)}đ',
            style: appStyle(16, kPrimary, FontWeight.bold),
          ),
        ],
      ),
    ]);
  }

  Widget _buildActionButtons(
      BuildContext context, VendorOrderController controller) {
    final width = MediaQuery.of(context).size.width;
    final hasDriver = order.driverId != null && order.driverId!.isNotEmpty;
    switch (order.orderStatus) {
      case 'Pending':
        return CustomButton(
          text: 'CHẤP NHẬN ĐƠN',
          btnWidth: width,
          btnColor: kPrimary,
          btnHieght: 45,
          btnRadius: 12,
          onTap: () => _handleStatusUpdate(controller, 'Preparing'),
        );
      case 'Preparing':
        return CustomButton(
          text: 'TÌM SHIPPER',
          btnWidth: width,
          btnColor: kPrimary,
          btnHieght: 45,
          btnRadius: 12,
          onTap: () => _handleStatusUpdate(controller, 'WaitingShipper'),
        );
      case 'WaitingShipper':
        return CustomButton(
          text: hasDriver ? 'ĐÃ GIAO HÀNG CHO SHIPPER' : 'ĐANG TÌM SHIPPER...',
          btnWidth: width,
          btnColor: hasDriver ? Colors.teal : kGrayLight,
          btnHieght: 45,
          btnRadius: 12,
          onTap: hasDriver
              ? () => _handleStatusUpdate(controller, 'Delivering')
              : null,
        );
      case 'PickedUp':
      case 'Delivering':
        return Container(
          width: width,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 8.w),
              Expanded(
                child: ReusableText(
                  text:
                      'Shipper sẽ xác nhận "Đã giao hàng" trong ứng dụng tài xế. Shop chỉ cần chờ cập nhật tự động.',
                  style: appStyle(12, kDark, FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleStatusUpdate(
      VendorOrderController controller, String newStatus) async {
    final ok = await controller.updateOrderStatus(order.id, newStatus,
        shouldPop: false);
    if (!ok) return;
    final refreshed = await controller.fetchOrderDetail(order.id);
    if (refreshed != null) {
      Get.off(() => OrderDetailPage(order: refreshed));
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
          text: '${formatVND(amount)}đ',
          style: appStyle(13, kDark, FontWeight.w500),
        ),
      ],
    );
  }

  String _mapReturnStatus(String status) {
    switch (status) {
      case 'Requested':
        return 'Khách yêu cầu trả hàng/hoàn tiền';
      case 'Approved':
        return 'Đã duyệt yêu cầu trả hàng';
      case 'Rejected':
        return 'Đã từ chối yêu cầu trả hàng';
      case 'Returned':
        return 'Đã nhận hàng trả lại';
      case 'Refunded':
        return 'Đã hoàn tiền';
      default:
        return 'Không có yêu cầu';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }
}
