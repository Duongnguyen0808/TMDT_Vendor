import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool pickupActionLoading = false;

  String _paymentStatusLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
        return 'Chờ thanh toán';
      case 'refunded':
        return 'Đã hoàn tiền';
      case 'failed':
        return 'Thanh toán thất bại';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy thanh toán';
      case 'partiallypaid':
      case 'partial':
        return 'Thanh toán một phần';
      case 'awaitingpayment':
      case 'awaiting':
        return 'Đang chờ đối soát';
      case 'authorized':
        return 'Đã ủy quyền';
      default:
        return raw == null || raw.isEmpty ? '--' : raw;
    }
  }

  String _paymentMethodLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'cod':
        return 'Thanh toán khi nhận (COD)';
      case 'cash':
        return 'Tiền mặt';
      case 'wallet':
        return 'Ví khách hàng';
      case 'banktransfer':
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      case 'card':
      case 'credit':
      case 'debit':
        return 'Thẻ tín dụng/ghi nợ';
      case 'vnpay':
        return 'VNPay';
      case 'momo':
        return 'MoMo';
      case 'zalopay':
        return 'ZaloPay';
      case 'paypal':
        return 'PayPal';
      default:
        return raw == null || raw.isEmpty ? '--' : raw;
    }
  }

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

  Future<void> _handlePickupAction(
      Future<Map<String, dynamic>?> Function() action) async {
    if (pickupActionLoading) return;
    setState(() {
      pickupActionLoading = true;
    });
    try {
      final result = await action();
      if (result != null) {
        await _load();
      }
    } finally {
      if (mounted)
        setState(() {
          pickupActionLoading = false;
        });
    }
  }

  Future<void> _markReady() async {
    final currentOrder = order;
    if (currentOrder == null) return;
    await _handlePickupAction(() => ctrl.markReadyForPickup(currentOrder.id));
  }

  Future<void> _regenCode() async {
    final currentOrder = order;
    if (currentOrder == null) return;
    await _handlePickupAction(() => ctrl.regeneratePickupCode(currentOrder.id));
  }

  Future<void> _copyPickupCode() async {
    final code = order?.pickupCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    Get.snackbar('Đã sao chép', 'Mã giao hàng đã được lưu clipboard',
        backgroundColor: kPrimary, colorText: kLightWhite);
  }

  bool _shouldShowPickupCard(OrdersModel o) {
    const relatedStatuses = {
      'Pending',
      'Preparing',
      'ReadyForPickup',
      'WaitingShipper',
      'PickedUp',
      'Delivering'
    };
    if (relatedStatuses.contains(o.orderStatus)) return true;
    return o.pickupReadyAt != null || o.pickupConfirmedAt != null;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '---';
    if (dt.millisecondsSinceEpoch == 0) return '---';
    final local = dt.toLocal();
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }

  String _formatLatLng(PickupCheckinLocation? loc) {
    if (loc == null) return '';
    return '(${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)})';
  }

  Widget _pickupInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: Icon(icon, size: 16, color: kDark.withOpacity(0.7)),
            ),
          Expanded(
            flex: 2,
            child: Text(label,
                style: appStyle(13, kDark.withOpacity(0.7), FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: appStyle(13, kDark, FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPickupCard(OrdersModel o) {
    final showCode =
        ['ReadyForPickup', 'WaitingShipper'].contains(o.orderStatus) &&
            (o.pickupCode?.isNotEmpty ?? false);
    final canMarkReady =
        ['Pending', 'Preparing', 'WaitingShipper'].contains(o.orderStatus);
    final canRegen = showCode;
    final hasCheckin = o.pickupCheckinAt != null;
    final hasConfirm = o.pickupConfirmedAt != null;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code, size: 20, color: kPrimary),
                const SizedBox(width: 8),
                Text('Bàn giao shop → shipper',
                    style: appStyle(15, kDark, FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            _pickupInfoRow('Sẵn sàng lúc', _formatDate(o.pickupReadyAt),
                icon: Icons.storefront),
            if (showCode) ...[
              const SizedBox(height: 12),
              Text('Mã đưa cho shipper',
                  style: appStyle(13, kDark, FontWeight.w600)),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: kPrimary.withOpacity(0.4), width: 1.4),
                  color: kPrimary.withOpacity(0.08),
                ),
                child: Center(
                  child: Text(o.pickupCode ?? '-- -- --',
                      style: appStyle(22, kPrimary, FontWeight.bold)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _copyPickupCode,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy mã'),
                  ),
                  Text(
                    o.pickupCodeExpiresAt != null
                        ? 'Hết hạn: ${_formatDate(o.pickupCodeExpiresAt)}'
                        : 'Không có hạn',
                    style:
                        appStyle(12, kDark.withOpacity(0.6), FontWeight.w500),
                  )
                ],
              )
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Chưa phát mã pickup. Khi món đã sẵn sàng, bấm "Phát mã" để hệ thống cung cấp mã bảo mật cho shipper.',
                style: appStyle(12, kDark.withOpacity(0.7), FontWeight.w400),
              ),
            ],
            const Divider(height: 24),
            _pickupInfoRow('Shipper check-in',
                hasCheckin ? _formatDate(o.pickupCheckinAt) : 'Chưa đến',
                icon: Icons.punch_clock),
            if (o.pickupCheckinLocation != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_formatLatLng(o.pickupCheckinLocation),
                    style:
                        appStyle(12, kDark.withOpacity(0.6), FontWeight.w500)),
              ),
            _pickupInfoRow('Bàn giao xác nhận',
                hasConfirm ? _formatDate(o.pickupConfirmedAt) : 'Chưa',
                icon: Icons.task_alt),
            if ((o.pickupNotes ?? '').isNotEmpty)
              _pickupInfoRow('Ghi chú', o.pickupNotes!),
            if ((o.handoverPhoto ?? '').isNotEmpty)
              _pickupInfoRow('Ảnh bàn giao', 'Đã tải lên'),
            if (pickupActionLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (canMarkReady)
              ElevatedButton.icon(
                onPressed: pickupActionLoading ? null : _markReady,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Phát mã Ready for Pickup'),
              ),
            if (canRegen)
              OutlinedButton.icon(
                onPressed: pickupActionLoading ? null : _regenCode,
                icon: const Icon(Icons.refresh),
                label: const Text('Tạo mã mới'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = order?.orderStatus ?? '';
    final nextStatus = ctrl.nextStatus(current);
    final bool shouldShowGeneric = nextStatus != null &&
        nextStatus != 'ReadyForPickup' &&
        nextStatus != 'Delivered';
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
                        if (pickupActionLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (pickupActionLoading) const SizedBox(height: 12),
                        ReusableText(
                          text: 'Trạng thái: ${order!.orderStatus}',
                          style: appStyle(14, kDark, FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thanh toán: ${_paymentStatusLabel(order!.paymentStatus)}',
                        ),
                        if ((order!.paymentMethod ?? '').isNotEmpty)
                          Text(
                            'Phương thức: ${_paymentMethodLabel(order!.paymentMethod)}',
                          ),
                        Text(
                            'Tổng tiền: ${formatVND(order!.grandTotal > 0 ? order!.grandTotal : order!.orderTotal)} đ'),
                        const SizedBox(height: 8),
                        if (order!.deliveryAddress.addressLine1.isNotEmpty)
                          Text(
                              'Địa chỉ: ${order!.deliveryAddress.addressLine1}'),
                        const Divider(height: 24),
                        if (_shouldShowPickupCard(order!))
                          _buildPickupCard(order!),
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
                        if (shouldShowGeneric)
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
                          Text(
                            nextStatus == 'ReadyForPickup'
                                ? 'Hãy dùng nút "Phát mã" trong thẻ pickup ở trên.'
                                : current == 'Delivering'
                                    ? 'Đơn đang được shipper giao, vui lòng chờ xác nhận từ shipper.'
                                    : 'Đơn đã hoàn tất',
                            style: appStyle(13, kDark, FontWeight.w500),
                          ),
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
