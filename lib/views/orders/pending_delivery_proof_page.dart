import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'order_detail_page.dart';

class PendingDeliveryProofPage extends StatelessWidget {
  PendingDeliveryProofPage({super.key});

  final VendorOrderController controller = Get.find<VendorOrderController>();

  Future<void> _refresh() async {
    await controller.fetchPendingDeliveryProofs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bằng chứng chờ duyệt'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        final loading = controller.pendingProofLoading.value;
        final items = controller.pendingProofOrders;
        if (loading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 140),
                    Icon(Icons.assignment_turned_in, size: 48, color: kPrimary),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Không có bằng chứng nào đang chờ xác nhận',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _PendingProofCard(
                      order: items[index],
                      controller: controller,
                      onReviewed: _refresh,
                    );
                  },
                ),
        );
      }),
    );
  }
}

class _PendingProofCard extends StatelessWidget {
  const _PendingProofCard({
    required this.order,
    required this.controller,
    required this.onReviewed,
  });

  final OrdersModel order;
  final VendorOrderController controller;
  final Future<void> Function() onReviewed;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }

  String _formatLocation(DeliveryProofLocation? loc) {
    if (loc == null) return '';
    return '(${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)})';
  }

  Future<void> _handleReview(BuildContext context,
      {required bool approve}) async {
    String note = '';
    if (!approve) {
      final typed = await _askRejectReason(context);
      if (typed == null) return;
      note = typed;
    }
    final ok = await controller.reviewDeliveryProof(order.id,
        approve: approve, note: note);
    if (ok) {
      await onReviewed();
    }
  }

  Future<String?> _askRejectReason(BuildContext context) async {
    final textCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lý do từ chối'),
        content: TextField(
          controller: textCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Mô tả lý do từ chối bằng chứng',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(textCtrl.text.trim()),
            child: const Text('Gửi'),
          ),
        ],
      ),
    ).then((value) {
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reviewing = controller.reviewingOrderId.value == order.id;
      final proofPhoto = order.deliveryProofPhoto ?? '';
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ReusableText(
                      text:
                          'Đơn ${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                      style: appStyle(14, kDark, FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Get.to(() => OrderDetailPage(orderId: order.id)),
                    child: const Text('Xem chi tiết'),
                  ),
                ],
              ),
              if ((order.userId.phone).isNotEmpty)
                Text('Khách: ${order.userId.phone}',
                    style: appStyle(12, kDark, FontWeight.w500)),
              if (order.deliveryAddress.addressLine1.isNotEmpty)
                Text(order.deliveryAddress.addressLine1,
                    style:
                        appStyle(12, kDark.withOpacity(.7), FontWeight.w400)),
              const SizedBox(height: 12),
              if (proofPhoto.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      proofPhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: kGrayLight,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 32),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if ((order.deliveryProofRecipient ?? '').isNotEmpty)
                _infoRow('Người nhận', order.deliveryProofRecipient!),
              if ((order.deliveryProofNote ?? '').isNotEmpty)
                _infoRow('Ghi chú', order.deliveryProofNote!),
              _infoRow('Thời gian', _formatDate(order.deliveryProofAt)),
              if (order.deliveryProofLocation != null)
                _infoRow(
                    'Vị trí', _formatLocation(order.deliveryProofLocation)),
              const SizedBox(height: 12),
              if (reviewing)
                const LinearProgressIndicator(minHeight: 2)
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleReview(context, approve: true),
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Xác nhận giao'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleReview(context, approve: false),
                        icon: const Icon(Icons.block),
                        label: const Text('Từ chối'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: appStyle(12, kDark.withOpacity(.6), FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: appStyle(12, kDark, FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }
}
