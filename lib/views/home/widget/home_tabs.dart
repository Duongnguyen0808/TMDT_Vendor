import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/tab_widget.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeTabs extends StatelessWidget {
  const HomeTabs({
    super.key,
    required TabController tabController,
  }) : _tabController = tabController;

  final TabController _tabController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Container(
        height: 25.h,
        width: width,
        decoration: BoxDecoration(
          color: kOffWhite,
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(25.r),
          ),
          labelColor: kLightWhite,
          dividerColor: Colors.transparent,
          unselectedLabelColor: kGrayLight,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: EdgeInsets.zero,
          unselectedLabelStyle: appStyle(12, kGray, FontWeight.normal),
          labelStyle: appStyle(12, kLightWhite, FontWeight.w600),
          tabs: List.generate(orderList.length, (i) {
            return TabWidget(text: orderList[i]);
          }),
        ),
      ),
    );
  }
}
