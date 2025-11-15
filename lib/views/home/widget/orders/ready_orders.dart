import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appliances_flutter/common/shimmers/applianceslist_shimmer.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/hooks/orders_hook.dart';
import 'package:appliances_flutter/views/home/widget/order_tile.dart';

class ReadyOrders extends HookWidget {
  const ReadyOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final hookResults = fetchOrders('Ready');
    final isLoading = hookResults.isLoading;
    final data = hookResults.data;
    final error = hookResults.error;

    if (isLoading) {
      return const AppliancesListShimmer();
    }

    if (error != null) {
      return Center(
        child: Text(error.message),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.r), topRight: Radius.circular(15.r)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: kGrayLight.withOpacity(0.3),
        ),
        child: ListView(
          children: List.generate(data!.length, (i) {
            final order = data[i];
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: OrderTile(order: order),
            );
          }),
        ),
      ),
    );
  }
}
