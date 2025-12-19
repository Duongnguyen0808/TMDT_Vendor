import 'package:appliances_flutter/common/shimmers/applianceslist_shimmer.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/hooks/orders_hook.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/utils/invoice_pdf.dart';
import 'package:appliances_flutter/views/home/widget/order_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';

class Preparing extends HookWidget {
  const Preparing({super.key});

  @override
  Widget build(BuildContext context) {
    final hookResults = fetchOrders('Preparing');
    final isLoading = hookResults.isLoading;
    final data = hookResults.data;
    final error = hookResults.error;
    final isBulkProcessing = useState(false);

    if (isLoading) {
      return const AppliancesListShimmer();
    }

    if (error != null) {
      return Center(
        child: Text(error.message),
      );
    }

    final orders = data ?? <OrdersModel>[];

    Future<void> onBulkPrint() async {
      if (orders.isEmpty || isBulkProcessing.value) return;
      isBulkProcessing.value = true;
      try {
        final bytes = await buildInvoicePdf(orders);
        await Printing.layoutPdf(onLayout: (_) async => bytes);
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(content: Text('Đã gửi ${orders.length} phiếu đến trình in')),
        );
      } catch (err) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(content: Text('Không thể in hàng loạt: $err')),
        );
      } finally {
        isBulkProcessing.value = false;
      }
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15.r), topRight: Radius.circular(15.r)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: kGrayLight.withOpacity(0.3),
            ),
            child: Column(
              children: [
                if (orders.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: kPrimary),
                      onPressed: isBulkProcessing.value ? null : onBulkPrint,
                      icon: isBulkProcessing.value
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.print_outlined),
                      label: Text(isBulkProcessing.value
                          ? 'Đang gửi ${orders.length} phiếu'
                          : 'In ${orders.length} phiếu chuẩn bị'),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
                    itemCount: orders.length,
                    itemBuilder: (_, i) {
                      final order = orders[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: OrderTile(order: order),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (orders.isNotEmpty)
          Positioned(
            right: 16.w,
            bottom: 24.h,
            child: FloatingActionButton.extended(
              heroTag: 'print_all_preparing',
              backgroundColor: kPrimary,
              onPressed: isBulkProcessing.value ? null : onBulkPrint,
              icon: const Icon(Icons.print_outlined),
              label: Text(isBulkProcessing.value
                  ? 'Đang in...'
                  : 'In tất cả (${orders.length})'),
            ),
          ),
      ],
    );
  }
}
