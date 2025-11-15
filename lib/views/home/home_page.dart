import 'package:appliances_flutter/views/home/widget/orders/picked_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/custom_appbar.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/views/home/widget/home_tabs.dart';
import 'package:appliances_flutter/views/home/widget/home_tiles.dart';
import 'package:appliances_flutter/views/home/widget/orders/cancelled_orders.dart';
import 'package:appliances_flutter/views/home/widget/orders/delivered_orders.dart';
import 'package:appliances_flutter/views/home/widget/orders/new_orders.dart';
import 'package:appliances_flutter/views/home/widget/orders/preparing.dart';
import 'package:appliances_flutter/views/home/widget/orders/ready_orders.dart';
import 'package:appliances_flutter/views/home/widget/orders/seld_deliveries.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: orderList.length,
    vsync: this,
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimary,
        flexibleSpace: const CustomAppBar(),
      ),
      body: BackGroundContainer(
          child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 15.h,
          ),
          const HomeTiles(),
          SizedBox(
            height: 15.h,
          ),
          HomeTabs(tabController: _tabController),
          SizedBox(
            height: 15.h,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            height: hieght * 0.65,
            color: Colors.transparent,
            child: TabBarView(
              controller: _tabController,
              children: const [
                NewOrders(),
                Preparing(),
                ReadyOrders(),
                PickedOrders(),
                SelfDeliveries(),
                DeliveredOrders(),
                CancelledOrders()
              ],
            ),
          )
        ],
      )),
    );
  }
}
