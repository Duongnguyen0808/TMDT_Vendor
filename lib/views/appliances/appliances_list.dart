import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/common/shimmers/applianceslist_shimmer.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/hooks/applianceslist_hook.dart';
import 'package:appliances_flutter/views/appliances/widgets/appliances_tile.dart';

class AppliancesList extends HookWidget {
  const AppliancesList({super.key});

  @override
  Widget build(BuildContext context) {
    final hookResult = fetchappliancesList();
    final appliances = hookResult.data;
    final isLoading = hookResult.isLoading;
    final error = hookResult.error;

    if (isLoading) {
      return Scaffold(
        backgroundColor: kSecondary,
        appBar: AppBar(
          backgroundColor: kSecondary,
          title: ReusableText(
            text: "Danh sách sản phẩm",
            style: appStyle(18, kLightWhite, FontWeight.w600),
          ),
        ),
        body: const BackGroundContainer(child: AppliancesListShimmer()),
      );
    }

    if (error != null) {
      return Center(
        child: Text(error.message),
      );
    }

    return Scaffold(
      backgroundColor: kSecondary,
      appBar: AppBar(
        backgroundColor: kSecondary,
        title: ReusableText(
          text: "Danh sách sản phẩm",
          style: appStyle(18, kLightWhite, FontWeight.w600),
        ),
      ),
      body: BackGroundContainer(
          child: Padding(
        padding: EdgeInsets.only(top: 20.h),
        child: ListView.builder(
            itemCount: appliances?.length ?? 0,
            itemBuilder: (context, i) {
              final appliance = appliances![i];
              return AppliancesTile(
                appliances: appliance,
                onUpdate: () => hookResult.refetch(), // Refresh sau khi update
                onDelete: () => hookResult.refetch(), // Refresh sau khi delete
              );
            }),
      )),
    );
  }
}
