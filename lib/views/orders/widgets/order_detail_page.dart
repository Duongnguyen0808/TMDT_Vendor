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
import 'package:appliances_flutter/controllers/chat_controller.dart';
import 'package:appliances_flutter/views/chat/chat_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:appliances_flutter/controllers/vendor_driver_controller.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class OrderDetailPage extends StatelessWidget {
  final OrdersModel order;

  const OrderDetailPage({super.key, required this.order});

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ xác nhận';
      case 'Preparing':
        return 'Đang chuẩn bị';
      case 'Delivering':
        return 'Đang vận chuyển';
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
      case 'Delivering':
        return Colors.purple;
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
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: kLightWhite),
            tooltip: 'Chat với khách',
            onPressed: () async {
              final chatCtrl = Get.isRegistered<VendorChatController>()
                  ? Get.find<VendorChatController>()
                  : Get.put(VendorChatController());
              final userId = order.userId.id;
              final conv = await chatCtrl.getOrCreateWithUser(userId);
              if (conv != null) {
                final title = order.userId.phone.isNotEmpty
                    ? order.userId.phone
                    : 'Khách hàng';
                Get.to(() => VendorChatDetailPage(
                      conversationId: conv['id'].toString(),
                      title: title,
                    ));
              } else {
                Get.snackbar('Lỗi', 'Không thể mở hội thoại');
              }
            },
          ),
        ],
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
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: kLightWhite,
                            padding: EdgeInsets.symmetric(
                                vertical: 8.h, horizontal: 12.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          onPressed: () async {
                            await _callPhone(order.userId.phone);
                          },
                          icon: const Icon(Icons.call, size: 18),
                          label: ReusableText(
                            text: 'Gọi khách',
                            style: appStyle(12, kLightWhite, FontWeight.w600),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: kLightWhite,
                            padding: EdgeInsets.symmetric(
                                vertical: 8.h, horizontal: 12.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          onPressed: () async {
                            final chatCtrl =
                                Get.isRegistered<VendorChatController>()
                                    ? Get.find<VendorChatController>()
                                    : Get.put(VendorChatController());
                            final conv = await chatCtrl
                                .getOrCreateWithUser(order.userId.id);
                            if (conv != null) {
                              final title = order.userId.phone.isNotEmpty
                                  ? order.userId.phone
                                  : 'Khách hàng';
                              Get.to(() => VendorChatDetailPage(
                                    conversationId: conv['id'].toString(),
                                    title: title,
                                  ));
                            } else {
                              Get.snackbar('Lỗi', 'Không thể mở hội thoại');
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: ReusableText(
                            text: 'Chat với khách',
                            style: appStyle(12, kLightWhite, FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Driver assignment
                _buildInfoCard(
                  title: "Tài xế giao hàng",
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delivery_dining, size: 18.sp, color: kGray),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ReusableText(
                            text: (order.driverId != null &&
                                    order.driverId!.isNotEmpty)
                                ? 'Đã gán'
                                : 'Chưa gán tài xế',
                            style: appStyle(13, kDark, FontWeight.w500),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final drv =
                                Get.isRegistered<VendorDriverController>()
                                    ? Get.find<VendorDriverController>()
                                    : Get.put(VendorDriverController());
                            await drv.fetchDrivers();
                            if (drv.drivers.isEmpty) {
                              Get.snackbar('Thông báo', 'Chưa có tài xế nào');
                              return;
                            }
                            showModalBottomSheet(
                              context: context,
                              builder: (_) {
                                String statusFilter = 'all';
                                String vehicleFilter = 'all';
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return Obx(() {
                                      // derive vehicle types
                                      final vehicleTypes = <String>{};
                                      for (final d in drv.drivers) {
                                        final vt =
                                            (d['vehicleType'] ?? '').toString();
                                        if (vt.isNotEmpty) vehicleTypes.add(vt);
                                      }
                                      var list = drv.drivers.toList();
                                      // apply filters
                                      list = list.where((d) {
                                        final status =
                                            (d['status'] ?? 'offline')
                                                .toString();
                                        final vt =
                                            (d['vehicleType'] ?? '').toString();
                                        final notBusy = status != 'busy';
                                        final statusOk = statusFilter == 'all'
                                            ? true
                                            : status == statusFilter;
                                        final vehicleOk = vehicleFilter == 'all'
                                            ? true
                                            : vt == vehicleFilter;
                                        return notBusy && statusOk && vehicleOk;
                                      }).toList();
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(12.w),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      DropdownButtonFormField<
                                                          String>(
                                                    value: statusFilter,
                                                    decoration:
                                                        const InputDecoration(
                                                            labelText:
                                                                'Trạng thái'),
                                                    items: const [
                                                      DropdownMenuItem(
                                                          value: 'all',
                                                          child:
                                                              Text('Tất cả')),
                                                      DropdownMenuItem(
                                                          value: 'available',
                                                          child:
                                                              Text('Sẵn sàng')),
                                                      DropdownMenuItem(
                                                          value: 'offline',
                                                          child: Text(
                                                              'Ngoại tuyến')),
                                                      DropdownMenuItem(
                                                          value: 'busy',
                                                          child:
                                                              Text('Đang bận')),
                                                    ],
                                                    onChanged: (v) => setState(
                                                        () => statusFilter =
                                                            v ?? 'all'),
                                                  ),
                                                ),
                                                SizedBox(width: 12.w),
                                                Expanded(
                                                  child:
                                                      DropdownButtonFormField<
                                                          String>(
                                                    value: vehicleFilter,
                                                    decoration:
                                                        const InputDecoration(
                                                            labelText:
                                                                'Loại xe'),
                                                    items: [
                                                      const DropdownMenuItem(
                                                          value: 'all',
                                                          child:
                                                              Text('Tất cả')),
                                                      ...vehicleTypes.map((e) =>
                                                          DropdownMenuItem(
                                                              value: e,
                                                              child: Text(e)))
                                                    ],
                                                    onChanged: (v) => setState(
                                                        () => vehicleFilter =
                                                            v ?? 'all'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(height: 1),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: list.length,
                                              itemBuilder: (_, i) {
                                                final d = list[i];
                                                final user = d['user'] ?? {};
                                                final name = user['username'] ??
                                                    'Tài xế';
                                                final phone =
                                                    user['phone'] ?? '';
                                                final status =
                                                    d['status'] ?? 'offline';
                                                return ListTile(
                                                  leading: const Icon(
                                                      Icons.motorcycle),
                                                  title: Text(name),
                                                  subtitle:
                                                      Text('$phone • $status'),
                                                  onTap: () async {
                                                    final ok = await Get.find<
                                                            VendorDriverController>()
                                                        .assignDriverToOrder(
                                                            order.id,
                                                            d['_id']
                                                                .toString());
                                                    if (ok) {
                                                      Get.back();
                                                      // refresh lists and detail
                                                      final oc = Get.find<
                                                          VendorOrderController>();
                                                      await oc.fetchAllOrders();
                                                      final refreshed = await oc
                                                          .fetchOrderDetail(
                                                              order.id);
                                                      if (refreshed != null) {
                                                        Get.off(() =>
                                                            OrderDetailPage(
                                                                order:
                                                                    refreshed));
                                                      }
                                                      Get.snackbar('Thành công',
                                                          'Đã gán tài xế cho đơn');
                                                    } else {
                                                      Get.snackbar('Lỗi',
                                                          'Gán tài xế thất bại');
                                                    }
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    });
                                  },
                                );
                              },
                            );
                          },
                          child: ReusableText(
                            text: 'Chọn tài xế',
                            style: appStyle(12, kPrimary, FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (order.driverId != null && order.driverId!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _loadAssignedDriver(order.driverId!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: kPrimary),
                                  ),
                                  SizedBox(width: 8.w),
                                  ReusableText(
                                    text: 'Đang tải tài xế...',
                                    style: appStyle(12, kGray, FontWeight.w400),
                                  ),
                                ],
                              );
                            }
                            if (!snapshot.hasData || snapshot.data == null) {
                              return ReusableText(
                                text: 'Không tìm thấy thông tin tài xế',
                                style: appStyle(12, kGray, FontWeight.w400),
                              );
                            }
                            final d = snapshot.data!;
                            final user = d['user'] ?? {};
                            final name =
                                (user['username'] ?? 'Tài xế').toString();
                            final phone = (user['phone'] ?? '').toString();
                            final avatar = (user['avatar'] ?? '').toString();
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 18.r,
                                  backgroundColor: kGrayLight,
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : null,
                                  child: avatar.isEmpty
                                      ? Icon(Icons.person, color: kGray)
                                      : null,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ReusableText(
                                        text: name,
                                        style: appStyle(
                                            13, kDark, FontWeight.w600),
                                      ),
                                      SizedBox(height: 2.h),
                                      ReusableText(
                                        text: phone,
                                        style: appStyle(
                                            12, kGray, FontWeight.w400),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Gọi tài xế',
                                  icon: Icon(Icons.call,
                                      color: Colors.green, size: 20.sp),
                                  onPressed: () async {
                                    if (phone.isEmpty) return;
                                    final uri = Uri(scheme: 'tel', path: phone);
                                    if (await launcher.canLaunchUrl(uri)) {
                                      await launcher.launchUrl(uri);
                                    } else {
                                      Get.snackbar(
                                          'Lỗi', 'Không thể gọi số $phone');
                                    }
                                  },
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final ok = await (Get.isRegistered<
                                                VendorDriverController>()
                                            ? Get.find<VendorDriverController>()
                                            : Get.put(VendorDriverController()))
                                        .unassignDriverFromOrder(order.id);
                                    if (ok) {
                                      // refresh lists and detail
                                      final oc =
                                          Get.find<VendorOrderController>();
                                      await oc.fetchAllOrders();
                                      final refreshed =
                                          await oc.fetchOrderDetail(order.id);
                                      if (refreshed != null) {
                                        Get.off(() =>
                                            OrderDetailPage(order: refreshed));
                                      }
                                      Get.snackbar(
                                          'Thành công', 'Đã bỏ gán tài xế');
                                    } else {
                                      Get.snackbar('Lỗi', 'Bỏ gán thất bại');
                                    }
                                  },
                                  child: ReusableText(
                                    text: 'Bỏ gán',
                                    style: appStyle(
                                        12, Colors.red, FontWeight.w600),
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 16.h),
                FutureBuilder<OrdersModel?>(
                  future: controller.fetchOrderDetail(order.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kPrimary),
                        ),
                      );
                    }
                    final detail = snap.data;
                    final rs = detail?.returnStatus ?? 'None';
                    if (detail == null || rs == 'None') {
                      return const SizedBox.shrink();
                    }
                    return _buildInfoCard(
                      title: 'Trả hàng/Hoàn tiền',
                      children: [
                        Row(
                          children: [
                            Icon(Icons.assignment_return,
                                size: 18.sp, color: kGray),
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
                                    final ok = await controller.reviewReturn(
                                        order.id, 'approve');
                                    if (ok) {
                                      final refreshed = await controller
                                          .fetchOrderDetail(order.id);
                                      if (refreshed != null) {
                                        Get.off(() =>
                                            OrderDetailPage(order: refreshed));
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: kLightWhite),
                                  child: const Text('Duyệt yêu cầu'),
                                ),
                              if (rs == 'Requested')
                                ElevatedButton(
                                  onPressed: () async {
                                    final ok = await controller.reviewReturn(
                                        order.id, 'reject');
                                    if (ok) {
                                      final refreshed = await controller
                                          .fetchOrderDetail(order.id);
                                      if (refreshed != null) {
                                        Get.off(() =>
                                            OrderDetailPage(order: refreshed));
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
                                      text:
                                          detail.grandTotal.toStringAsFixed(0));
                                  final amount = await showDialog<double?>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text(
                                          'Xác nhận trả hàng/hoàn tiền'),
                                      content: TextField(
                                        controller: ctrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Số tiền hoàn (đ)',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Get.back(result: null),
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
                                  final ok = await controller.confirmReturned(
                                      order.id,
                                      refundAmount: amount);
                                  if (ok) {
                                    final refreshed = await controller
                                        .fetchOrderDetail(order.id);
                                    if (refreshed != null) {
                                      Get.off(() =>
                                          OrderDetailPage(order: refreshed));
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
                            text:
                                'Đã hoàn: ${detail.refundAmount?.toStringAsFixed(0) ?? '0'}đ',
                            style: appStyle(12, kGray, FontWeight.w400),
                          ),
                        ],
                      ],
                    );
                  },
                ),

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
                                  Row(
                                    children: [
                                      ReusableText(
                                        text: "x${item.quantity}",
                                        style: appStyle(
                                            12, kGray, FontWeight.normal),
                                      ),
                                      SizedBox(width: 8.w),
                                      if (item.appliancesId.stock != null)
                                        Row(
                                          children: [
                                            Icon(Icons.inventory_2,
                                                size: 12.sp,
                                                color:
                                                    (item.appliancesId.stock ??
                                                                0) >
                                                            0
                                                        ? kGray
                                                        : Colors.red),
                                            SizedBox(width: 2.w),
                                            ReusableText(
                                              text:
                                                  "Tồn: ${item.appliancesId.stock}",
                                              style: appStyle(
                                                  11,
                                                  (item.appliancesId.stock ??
                                                              0) >
                                                          0
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
                    : _buildActionButtons(context, controller)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, VendorOrderController controller) {
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
            if (order.driverId == null || order.driverId!.isEmpty) {
              // prompt assign
              final assigned = await _promptAssignDriver(context);
              if (!assigned) return;
            }
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

  Future<bool> _promptAssignDriver(BuildContext context) async {
    final drv = Get.isRegistered<VendorDriverController>()
        ? Get.find<VendorDriverController>()
        : Get.put(VendorDriverController());
    await drv.fetchDrivers();
    if (drv.drivers.isEmpty) {
      Get.snackbar('Thông báo', 'Chưa có tài xế nào');
      return false;
    }
    String? selectedId;
    await showModalBottomSheet(
      context: context,
      builder: (_) {
        String statusFilter = 'all';
        String vehicleFilter = 'all';
        return StatefulBuilder(
          builder: (context, setState) {
            return Obx(() {
              final vehicleTypes = <String>{};
              for (final d in drv.drivers) {
                final vt = (d['vehicleType'] ?? '').toString();
                if (vt.isNotEmpty) vehicleTypes.add(vt);
              }
              var list = drv.drivers.toList();
              list = list.where((d) {
                final status = (d['status'] ?? 'offline').toString();
                final vt = (d['vehicleType'] ?? '').toString();
                final notBusy = status != 'busy';
                final statusOk =
                    statusFilter == 'all' ? true : status == statusFilter;
                final vehicleOk =
                    vehicleFilter == 'all' ? true : vt == vehicleFilter;
                return notBusy && statusOk && vehicleOk;
              }).toList();
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: statusFilter,
                            decoration:
                                const InputDecoration(labelText: 'Trạng thái'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'all', child: Text('Tất cả')),
                              DropdownMenuItem(
                                  value: 'available', child: Text('Sẵn sàng')),
                              DropdownMenuItem(
                                  value: 'offline', child: Text('Ngoại tuyến')),
                              DropdownMenuItem(
                                  value: 'busy', child: Text('Đang bận')),
                            ],
                            onChanged: (v) =>
                                setState(() => statusFilter = v ?? 'all'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: vehicleFilter,
                            decoration:
                                const InputDecoration(labelText: 'Loại xe'),
                            items: [
                              const DropdownMenuItem(
                                  value: 'all', child: Text('Tất cả')),
                              ...vehicleTypes.map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                            ],
                            onChanged: (v) =>
                                setState(() => vehicleFilter = v ?? 'all'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final d = list[i];
                        final user = d['user'] ?? {};
                        final name = user['username'] ?? 'Tài xế';
                        final phone = user['phone'] ?? '';
                        final status = d['status'] ?? 'offline';
                        return ListTile(
                          leading: const Icon(Icons.motorcycle),
                          title: Text(name),
                          subtitle: Text('$phone • $status'),
                          onTap: () {
                            selectedId = d['_id'].toString();
                            Get.back();
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            });
          },
        );
      },
    );

    if (selectedId != null) {
      final ok = await (Get.isRegistered<VendorDriverController>()
              ? Get.find<VendorDriverController>()
              : Get.put(VendorDriverController()))
          .assignDriverToOrder(order.id, selectedId!);
      if (ok) {
        final oc = Get.find<VendorOrderController>();
        await oc.fetchAllOrders();
        final refreshed = await oc.fetchOrderDetail(order.id);
        if (refreshed != null) {
          Get.off(() => OrderDetailPage(order: refreshed));
        }
        Get.snackbar('Thành công', 'Đã gán tài xế cho đơn');
        return true;
      } else {
        Get.snackbar('Lỗi', 'Gán tài xế thất bại');
        return false;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> _loadAssignedDriver(String driverId) async {
    final drv = Get.isRegistered<VendorDriverController>()
        ? Get.find<VendorDriverController>()
        : Get.put(VendorDriverController());
    if (drv.drivers.isEmpty) {
      await drv.fetchDrivers();
    }
    for (final e in drv.drivers) {
      final id = (e['_id']?.toString() ?? '');
      if (id == driverId) {
        return Map<String, dynamic>.from(e as Map);
      }
    }
    return null;
  }

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) {
      Get.snackbar('Thông báo', 'Không có số điện thoại');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(uri);
      } else {
        Get.snackbar('Lỗi', 'Không thể mở trình gọi');
      }
    } catch (_) {
      Get.snackbar('Lỗi', 'Không thể thực hiện cuộc gọi');
    }
  }
}
