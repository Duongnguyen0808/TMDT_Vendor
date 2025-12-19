import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:appliances_flutter/hooks/multi_orders_hook.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:appliances_flutter/views/orders/widgets/vendor_order_tile.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:appliances_flutter/utils/invoice_pdf.dart';

class OrdersStatusTabsPage extends StatefulHookWidget {
  const OrdersStatusTabsPage({super.key});
  @override
  State<OrdersStatusTabsPage> createState() => _OrdersStatusTabsPageState();
}

class _OrdersStatusTabsPageState extends State<OrdersStatusTabsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _statuses = const [
    'Pending',
    'Preparing',
    'WaitingShipper',
    'Delivering',
    'Delivered',
    'Cancelled',
  ];
  final _labels = const [
    'Mới',
    'Chuẩn bị',
    'Tìm shipper',
    'Đang giao',
    'Hoàn tất',
    'Hủy',
  ];
  static const _pendingProofLabel = 'Chờ shop duyệt';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: _labels.length + 1 /* pending tab */, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VendorOrderController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: appStyle(12, kDark, FontWeight.w600),
          tabs: [
            for (final l in _labels) Tab(text: l),
            const Tab(text: _pendingProofLabel),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (int i = 0; i < _statuses.length; i++)
            _StatusList(
              status: _statuses[i],
              controller: controller,
            ),
          _PendingProofList(controller: controller),
        ],
      ),
    );
  }
}

class _StatusList extends HookWidget {
  final String status;
  final VendorOrderController controller;
  const _StatusList({required this.status, required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = useMultiOrders(
        statuses: [status], includeAllPayments: true, initialLimit: 30);
    final isPreparing = status == 'Preparing';
    final bulkProcessing = useState(false);

    useEffect(() {
      return null; // no cleanup
    }, []);

    if (result.isLoading && (result.data?.isEmpty ?? true)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (result.error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Lỗi: ${result.error!.message}'),
      ));
    }
    final orders = result.data ?? <OrdersModel>[];
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => result.refetch(),
        child: ListView(children: [
          SizedBox(height: 140.h),
          Center(
              child: Text('Không có đơn ở trạng thái này',
                  style: appStyle(12, kGray, FontWeight.w500))),
        ]),
      );
    }
    Future<void> onBulkPrint() async {
      if (!isPreparing || orders.isEmpty || bulkProcessing.value) return;
      bulkProcessing.value = true;
      try {
        final bytes = await buildInvoicePdf(orders);
        await Printing.layoutPdf(onLayout: (_) async => bytes);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
              content:
                  Text('Đã gửi ${orders.length} phiếu chuẩn bị đến trình in')),
        );
      } catch (err) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Không thể in hàng loạt: $err')),
        );
      } finally {
        bulkProcessing.value = false;
      }
    }

    final listView = RefreshIndicator(
      onRefresh: () async => result.refetch(),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(0, 0, 0, isPreparing ? 120.h : 0),
        itemCount: orders.length + (result.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= orders.length) {
            return TextButton(
                onPressed: result.loadMore, child: const Text('Tải thêm...'));
          }
          final o = orders[index];
          return VendorOrderTile(order: o);
        },
      ),
    );

    if (!isPreparing || orders.isEmpty) {
      return listView;
    }

    return Stack(
      children: [
        Positioned.fill(child: listView),
        Positioned(
          right: 16.w,
          bottom: 24.h,
          child: FloatingActionButton.extended(
            heroTag: 'vendor_preparing_bulk_print',
            backgroundColor: kPrimary,
            onPressed: bulkProcessing.value ? null : onBulkPrint,
            icon: bulkProcessing.value
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.print_outlined),
            label: Text(bulkProcessing.value
                ? 'Đang in...'
                : 'In tất cả (${orders.length})'),
          ),
        ),
      ],
    );
  }
}

class _PendingProofList extends StatelessWidget {
  final VendorOrderController controller;
  const _PendingProofList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.pendingProofLoading.value;
      final orders = controller.pendingProofOrders;
      if (isLoading && orders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (orders.isEmpty) {
        return RefreshIndicator(
          onRefresh: () async => controller.fetchPendingDeliveryProofs(),
          child: ListView(
            children: [
              SizedBox(height: 140.h),
              Center(
                child: Text('Không có đơn cần shop duyệt',
                    style: appStyle(12, kGray, FontWeight.w500)),
              )
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async => controller.fetchPendingDeliveryProofs(),
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _PendingProofCard(order: order, controller: controller);
          },
        ),
      );
    });
  }
}

class _PendingProofCard extends StatelessWidget {
  final OrdersModel order;
  final VendorOrderController controller;
  const _PendingProofCard({required this.order, required this.controller});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM HH:mm');
    final photo = order.deliveryProofPhoto ?? '';
    final proofTime = order.deliveryProofAt != null
        ? formatter.format(order.deliveryProofAt!.toLocal())
        : null;
    final location = order.deliveryProofLocation;
    final locationText = location == null
        ? null
        : '${location.latitude.toStringAsFixed(5)}, '
            '${location.longitude.toStringAsFixed(5)}';
    final confirmStatus = order.shopDeliveryConfirmStatus ?? 'pending';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order.id.substring(0, order.id.length.clamp(0, 8))}',
                    style: appStyle(13, kDark, FontWeight.w700)),
                Chip(
                  label: Text(
                    confirmStatus == 'approved'
                        ? 'Đã xác nhận'
                        : (confirmStatus == 'rejected'
                            ? 'Đã từ chối'
                            : 'Chờ duyệt'),
                    style: appStyle(11, kLightWhite, FontWeight.w600),
                  ),
                  backgroundColor: confirmStatus == 'approved'
                      ? Colors.green
                      : confirmStatus == 'rejected'
                          ? Colors.red
                          : Colors.orangeAccent,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.deliveryAddress.addressLine1,
              style: appStyle(12, kDark, FontWeight.w500),
            ),
            if (proofTime != null) ...[
              const SizedBox(height: 4),
              Text('Giao lúc: $proofTime',
                  style: appStyle(11, kGray, FontWeight.w500)),
            ],
            if ((order.deliveryProofRecipient ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Người nhận: ${order.deliveryProofRecipient}',
                  style: appStyle(11, kGray, FontWeight.w500)),
            ],
            if ((order.deliveryProofNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Ghi chú shipper: ${order.deliveryProofNote}',
                  style: appStyle(11, kGray, FontWeight.w500)),
            ],
            if (locationText != null) ...[
              const SizedBox(height: 4),
              Text('Vị trí: $locationText',
                  style: appStyle(11, kGray, FontWeight.w500)),
            ],
            const SizedBox(height: 12),
            if (photo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photo,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: kGray.withOpacity(.2),
                    alignment: Alignment.center,
                    child: const Text('Không tải được ảnh'),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: kGray.withOpacity(.1),
                ),
                alignment: Alignment.center,
                child: Text('Không có ảnh bằng chứng',
                    style: appStyle(11, kGray, FontWeight.w500)),
              ),
            const SizedBox(height: 12),
            Obx(() {
              final busy = controller.reviewingOrderId.value == order.id;
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          busy ? null : () => _promptReject(context, order),
                      child: busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy
                          ? null
                          : () => controller.reviewDeliveryProof(order.id,
                              approve: true),
                      child: busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Xác nhận giao'),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _promptReject(BuildContext context, OrdersModel order) async {
    final noteController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Từ chối bằng chứng giao'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Lý do (tùy chọn)',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(noteController.text),
              child: const Text('Từ chối'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await controller.reviewDeliveryProof(order.id,
          approve: false, note: result.trim());
    }
  }
}
