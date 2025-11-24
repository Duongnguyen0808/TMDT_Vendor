import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/chat_controller.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:appliances_flutter/hooks/multi_orders_hook.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/views/chat/chat_detail_page.dart';
import 'package:appliances_flutter/views/orders/order_detail_page.dart';

class ReturnCenterPage extends HookWidget {
  const ReturnCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VendorOrderController());
    final tabs = <_ReturnTabConfig>[
      const _ReturnTabConfig(
        id: 'requested',
        label: 'Yêu cầu mới',
        returnStatuses: ['Requested'],
      ),
      const _ReturnTabConfig(
        id: 'approved',
        label: 'Chờ xử lý',
        returnStatuses: ['Approved'],
      ),
      const _ReturnTabConfig(
        id: 'done',
        label: 'Đã hoàn tất',
        returnStatuses: ['Refunded', 'Returned', 'Rejected'],
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trả hàng & hoàn tiền'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final tab in tabs) Tab(text: tab.label)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in tabs)
              _ReturnTabView(config: tab, controller: controller),
          ],
        ),
      ),
    );
  }
}

class _ReturnTabConfig {
  final String id;
  final String label;
  final List<String> returnStatuses;
  const _ReturnTabConfig({
    required this.id,
    required this.label,
    required this.returnStatuses,
  });
}

class _ReturnTabView extends HookWidget {
  final _ReturnTabConfig config;
  final VendorOrderController controller;
  const _ReturnTabView({required this.config, required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = useMultiOrders(
      statuses: const [],
      includeAllPayments: true,
      returnStatuses: config.returnStatuses,
      returnOnly: true,
    );
    final orders = result.data ?? const <OrdersModel>[];

    if (result.isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (result.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.error!.message.isEmpty
                ? 'Không thể tải dữ liệu'
                : result.error!.message),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: result.refetch,
              child: const Text('Thử lại'),
            )
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => result.refetch(),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.move_to_inbox, size: 80, color: kGrayLight),
            SizedBox(height: 12),
            Center(child: Text('Chưa có yêu cầu trong mục này')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => result.refetch(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: orders.length + (result.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= orders.length) {
            return TextButton(
              onPressed: result.loadMore,
              child: const Text('Tải thêm'),
            );
          }
          final order = orders[index];
          return _ReturnOrderCard(
            order: order,
            controller: controller,
            onChanged: result.refetch,
          );
        },
      ),
    );
  }
}

class _ReturnOrderCard extends StatefulWidget {
  final OrdersModel order;
  final VendorOrderController controller;
  final VoidCallback onChanged;
  const _ReturnOrderCard({
    required this.order,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_ReturnOrderCard> createState() => _ReturnOrderCardState();
}

class _ReturnOrderCardState extends State<_ReturnOrderCard> {
  bool _busy = false;
  final _dateFormat = DateFormat('dd/MM HH:mm');
  final VendorChatController _chatController = Get.put(VendorChatController());

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return _dateFormat.format(dt.toLocal());
  }

  String _shortId(String id) {
    if (id.length <= 6) return id.toUpperCase();
    return '#${id.substring(id.length - 6).toUpperCase()}';
  }

  String _customerLabel() {
    final profile = widget.order.userId.profile;
    if (profile.isNotEmpty) return profile;
    final phone = widget.order.userId.phone;
    if (phone.isNotEmpty) return phone;
    return 'Khách hàng';
  }

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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: appStyle(12, kGray, FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: appStyle(12, kDark, FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Future<void> _handle(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await action();
      if (ok) widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() async {
    await _handle(
        () => widget.controller.reviewReturn(widget.order.id, 'approve'));
  }

  Future<void> _reject() async {
    await _handle(
        () => widget.controller.reviewReturn(widget.order.id, 'reject'));
  }

  Future<double?> _promptRefundAmount() async {
    final fallbackTotal = widget.order.grandTotal > 0
        ? widget.order.grandTotal
        : widget.order.orderTotal;
    final defaultValue =
        widget.order.refundAmount != null && widget.order.refundAmount! > 0
            ? widget.order.refundAmount!
            : fallbackTotal;
    final controller =
        TextEditingController(text: defaultValue.toStringAsFixed(0));
    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập số tiền hoàn'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: 250000',
            helperText: 'Để nguyên để hoàn đầy đủ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = controller.text.replaceAll(RegExp(r'[^0-9\.]'), '');
              if (raw.isEmpty) {
                Navigator.of(ctx).pop(defaultValue);
                return;
              }
              final parsed = double.tryParse(raw);
              if (parsed == null || parsed <= 0) {
                Get.snackbar(
                  'Sai số tiền',
                  'Vui lòng nhập số dương hợp lệ',
                  backgroundColor: kRed,
                  colorText: kLightWhite,
                );
                return;
              }
              Navigator.of(ctx).pop(parsed);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _confirmReturned() async {
    final amount = await _promptRefundAmount();
    if (amount == null) return;
    await _handle(() => widget.controller
        .confirmReturned(widget.order.id, refundAmount: amount));
  }

  Future<void> _openChat() async {
    final userId = widget.order.userId.id;
    if (userId.isEmpty) {
      Get.snackbar('Không có khách', 'Không tìm thấy tài khoản khách',
          backgroundColor: kRed, colorText: kLightWhite);
      return;
    }
    try {
      final conversation = await _chatController.getOrCreateWithUser(userId);
      if (conversation == null) {
        Get.snackbar('Không thể mở hội thoại',
            'Máy chủ chưa sẵn sàng hoặc khách đã khóa chat',
            backgroundColor: kRed, colorText: kLightWhite);
        return;
      }
      final conversationId =
          (conversation['id'] ?? conversation['_id'] ?? '').toString();
      if (conversationId.isEmpty) {
        Get.snackbar('Thiếu dữ liệu', 'Không có conversationId hợp lệ',
            backgroundColor: kRed, colorText: kLightWhite);
        return;
      }
      Get.to(() => VendorChatDetailPage(
            conversationId: conversationId,
            title: _customerLabel(),
          ));
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể mở chat: $e',
          backgroundColor: kRed, colorText: kLightWhite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final chips = [
      Chip(
        label: Text(order.returnStatus ?? '-'),
        backgroundColor: kPrimary.withOpacity(.08),
        labelStyle: appStyle(11, kPrimary, FontWeight.w600),
      ),
      Chip(
        label: Text(order.orderStatus),
        backgroundColor: kGrayLight.withOpacity(.15),
        labelStyle: appStyle(11, kDark, FontWeight.w500),
      ),
    ];

    final reason = (order.returnReason ?? '').isEmpty
        ? 'Khách không ghi chú'
        : order.returnReason!;

    final amountText =
        '${formatVND(order.grandTotal > 0 ? order.grandTotal : order.orderTotal)} đ';
    final refundText = order.refundAmount != null && order.refundAmount! > 0
        ? '${formatVND(order.refundAmount!)} đ'
        : '--';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ReusableText(
                    text: 'Đơn ${_shortId(order.id)}',
                    style: appStyle(14, kDark, FontWeight.w700),
                  ),
                ),
                Wrap(spacing: 6, children: chips),
              ],
            ),
            const SizedBox(height: 8),
            Text('Lý do khách: $reason',
                style: appStyle(12, kDark, FontWeight.w500)),
            const SizedBox(height: 8),
            _infoRow('Tổng đơn', amountText),
            _infoRow('Thanh toán', _paymentStatusLabel(order.paymentStatus)),
            if ((order.paymentMethod ?? '').isNotEmpty)
              _infoRow(
                'Phương thức',
                _paymentMethodLabel(order.paymentMethod),
              ),
            _infoRow('Yêu cầu lúc', _formatDate(order.returnRequestedAt)),
            _infoRow('Xử lý lúc', _formatDate(order.returnProcessedAt)),
            _infoRow('Số tiền hoàn', refundText),
            if ((order.refundMethod ?? '').isNotEmpty)
              _infoRow(
                'Phương thức hoàn',
                _paymentMethodLabel(order.refundMethod),
              ),
            if ((order.paymentMethod ?? '').toUpperCase() == 'COD')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: kSecondary.withOpacity(.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Đơn COD: sau khi bấm "Đã nhận hàng hoàn" hãy hoàn tiền mặt trực tiếp cho khách. Hệ thống sẽ ghi nhận trạng thái để kiểm soát.',
                  style: appStyle(12, kSecondary, FontWeight.w600),
                ),
              ),
            const Divider(height: 24),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.order.userId.id.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _openChat,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Nhắn khách'),
                  ),
                if (order.returnStatus == 'Requested') ...[
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _approve,
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt trả hàng'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _reject,
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                  ),
                ] else if (order.returnStatus == 'Approved') ...[
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _confirmReturned,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Đã nhận hàng hoàn'),
                  ),
                ] else
                  Chip(
                    label: Text(_statusDescription(order.returnStatus)),
                  ),
                TextButton(
                  onPressed: () =>
                      Get.to(() => OrderDetailPage(orderId: order.id)),
                  child: const Text('Chi tiết đơn'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusDescription(String? status) {
    switch (status) {
      case 'Refunded':
        return 'Đã hoàn tiền';
      case 'Returned':
        return 'Đã nhận lại hàng';
      case 'Rejected':
        return 'Đã từ chối yêu cầu';
      default:
        return status ?? '--';
    }
  }
}
