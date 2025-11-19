import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ctrl = Get.find<VendorOrderController>();
  OrdersModel? order;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ctrl.fetchOrderDetail(widget.orderId);
      if (data == null) {
        error = 'Không lấy được dữ liệu đơn hàng';
      } else {
        order = data;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted)
        setState(() {
          loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = order?.orderStatus ?? '';
    final nextStatus = ctrl.nextStatus(current);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Đơn: ${widget.orderId.substring(0, widget.orderId.length > 8 ? 8 : widget.orderId.length)}'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : order == null
                  ? const Center(child: Text('Không có dữ liệu'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ReusableText(
                          text: 'Trạng thái: ${order!.orderStatus}',
                          style: appStyle(14, kDark, FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text('Thanh toán: ${order!.paymentStatus ?? 'N/A'}'),
                        Text(
                            'Tổng tiền: ${formatVND(order!.grandTotal > 0 ? order!.grandTotal : order!.orderTotal)} đ'),
                        const SizedBox(height: 8),
                        if (order!.deliveryAddress.addressLine1.isNotEmpty)
                          Text(
                              'Địa chỉ: ${order!.deliveryAddress.addressLine1}'),
                        const Divider(height: 24),
                        Text('Sản phẩm:',
                            style: appStyle(13, kDark, FontWeight.w600)),
                        const SizedBox(height: 6),
                        ...order!.orderItems.map((it) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(it.appliancesId.title),
                              subtitle: Text(
                                  'SL: ${it.quantity}  Giá: ${formatVND(it.price)}'),
                            )),
                        const Divider(height: 24),
                        if (nextStatus != null)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await ctrl.progressOrder(
                                  order!.id, order!.orderStatus);
                              await _load();
                            },
                            icon: const Icon(Icons.fast_forward),
                            label: Text('Chuyển sang "$nextStatus"'),
                          )
                        else
                          const Text('Đơn đã hoàn tất'),
                        const SizedBox(height: 12),
                        if (order!.orderStatus == 'Pending')
                          OutlinedButton(
                            onPressed: () async {
                              await ctrl.approvePending(order!.id);
                              await _load();
                            },
                            child: const Text('Duyệt (Preparing)'),
                          ),
                      ],
                    ),
    );
  }
}
