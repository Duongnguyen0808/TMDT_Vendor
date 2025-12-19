import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/hooks/multi_orders_hook.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/views/orders/delivery_issue_dashboard_page.dart';
import 'package:appliances_flutter/views/orders/order_detail_page.dart';
import 'package:appliances_flutter/views/orders/pending_delivery_proof_page.dart';
import 'package:appliances_flutter/views/orders/vendor_rating_center_page.dart';

class OrdersDashboardPage extends HookWidget {
  const OrdersDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller exists
    final ctrl = Get.put(VendorOrderController());
    final tabs = const [
      _StatusTabConf('Pending', 'Đơn mới'),
      _StatusTabConf('Preparing', 'Chuẩn bị'),
      _StatusTabConf('Delivering', 'Đang giao'),
      _StatusTabConf('Delivered', 'Hoàn tất'),
      _StatusTabConf('Cancelled', 'Đã hủy'),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý đơn hàng'),
          actions: [
            IconButton(
              tooltip: 'Đánh giá đối tác',
              onPressed: () => Get.to(() => const VendorRatingCenterPage()),
              icon: const Icon(Icons.star_rate_rounded),
            ),
            IconButton(
              tooltip: 'Dashboard cảnh báo',
              onPressed: () => Get.to(() => const DeliveryIssueDashboardPage()),
              icon: const Icon(Icons.monitor_heart),
            ),
            Obx(() {
              final pendingCount = ctrl.pendingProofOrders.length;
              final isLoading = ctrl.pendingProofLoading.value;
              return IconButton(
                tooltip: 'Bằng chứng chờ duyệt',
                onPressed: () => Get.to(() => PendingDeliveryProofPage()),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(isLoading ? Icons.sync : Icons.assignment_turned_in),
                    if (pendingCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: const BoxDecoration(
                            color: kRed,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Text(
                            pendingCount > 99 ? '99+' : '$pendingCount',
                            style: appStyle(10, kLightWhite, FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final t in tabs) Tab(text: t.label)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final t in tabs)
              _OrdersStatusList(
                status: t.status,
                controller: ctrl,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusTabConf {
  final String status;
  final String label;
  const _StatusTabConf(this.status, this.label);
}

class _OrdersStatusList extends HookWidget {
  final String status;
  final VendorOrderController controller;
  const _OrdersStatusList({required this.status, required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = useMultiOrders(
        statuses: [status], includeAllPayments: true, initialLimit: 25);
    final orders = result.data ?? [];
    if (result.isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (result.error != null) {
      return Center(child: Text('Lỗi: ${result.error!.message}'));
    }
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => result.refetch(),
        child: ListView(children: [
          const SizedBox(height: 120),
          Center(child: Text('Không có đơn $status'))
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => result.refetch(),
      child: ListView.builder(
        itemCount: orders.length + (result.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= orders.length) {
            return TextButton(
              onPressed: result.loadMore,
              child: const Text('Tải thêm...'),
            );
          }
          final o = orders[index];
          return _OrderCard(
              order: o,
              status: status,
              controller: controller,
              onChanged: () async {
                // after action refresh current tab
                result.refetch();
              });
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrdersModel order;
  final String status;
  final VendorOrderController controller;
  final VoidCallback onChanged;
  const _OrderCard(
      {required this.order,
      required this.status,
      required this.controller,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final next = controller.nextStatus(order.orderStatus);
    final amount = (order.grandTotal > 0 ? order.grandTotal : order.orderTotal)
        .toStringAsFixed(0);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => Get.to(() => OrderDetailPage(orderId: order.id)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ReusableText(
                      text:
                          'Đơn: ${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                      style: appStyle(13, kDark, FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(order.orderStatus,
                        style: appStyle(11, kPrimary, FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Tổng: ${amount}đ',
                  style: appStyle(12, kGray, FontWeight.w500)),
              if (order.deliveryAddress.addressLine1.isNotEmpty)
                Text(order.deliveryAddress.addressLine1,
                    style: appStyle(11, kDark, FontWeight.w400)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (order.orderStatus == 'Pending')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await controller.approvePending(order.id);
                          onChanged();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Duyệt'),
                      ),
                    )
                  else if (next != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await controller.progressOrder(
                              order.id, order.orderStatus);
                          onChanged();
                        },
                        icon: const Icon(Icons.fast_forward),
                        label: Text('Sang $next'),
                      ),
                    )
                  else
                    const Expanded(child: Text('Đã kết thúc')),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () =>
                        Get.to(() => OrderDetailPage(orderId: order.id)),
                    child: const Text('Chi tiết'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
