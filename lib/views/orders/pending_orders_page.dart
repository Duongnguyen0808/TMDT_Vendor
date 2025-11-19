import 'package:appliances_flutter/views/orders/widgets/order_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:appliances_flutter/hooks/multi_orders_hook.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/constants/constants.dart';

class PendingOrdersPage extends HookWidget {
  const PendingOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VendorOrderController());
    final result = useMultiOrders(
        statuses: const ['Pending'],
        includeAllPayments: true,
        initialLimit: 30);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn mới (Pending)'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => result.refetch(),
        child: Builder(
          builder: (_) {
            if (result.isLoading && (result.data?.isEmpty ?? true)) {
              return const Center(child: CircularProgressIndicator());
            }
            if (result.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Lỗi: ${result.error!.message}'),
                ),
              );
            }
            final orders = result.data ?? [];
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Chưa có đơn Pending')),
                ],
              );
            }
            return ListView.builder(
              itemCount: orders.length + (result.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= orders.length) {
                  // nút load thêm
                  return TextButton(
                    onPressed: result.loadMore,
                    child: const Text('Tải thêm...'),
                  );
                }
                final o = orders[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ReusableText(
                                text: 'Mã đơn: ${o.id}',
                                style: appStyle(13, kDark, FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(o.orderStatus,
                                  style:
                                      appStyle(11, kPrimary, FontWeight.w500)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                            'Tổng: ${(o.grandTotal > 0 ? o.grandTotal : o.orderTotal).toStringAsFixed(0)}đ',
                            style: appStyle(12, kGray, FontWeight.w500)),
                        const SizedBox(height: 4),
                        if (o.deliveryAddress.addressLine1.isNotEmpty)
                          Text('Giao tới: ${o.deliveryAddress.addressLine1}',
                              style: appStyle(11, kDark, FontWeight.w400)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => ctrl.approvePending(o.id),
                                icon: const Icon(Icons.check),
                                label: const Text('Duyệt & chuyển chuẩn bị'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                Get.to(() => OrderDetailPage(order: o));
                              },
                              child: const Text('Chi tiết'),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
