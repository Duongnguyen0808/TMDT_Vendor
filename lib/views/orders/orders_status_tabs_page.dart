import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:appliances_flutter/hooks/multi_orders_hook.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:appliances_flutter/views/orders/widgets/vendor_order_tile.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/constants/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
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
    final orders = result.data ?? [];
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
    return RefreshIndicator(
      onRefresh: () async => result.refetch(),
      child: ListView.builder(
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
  }
}
