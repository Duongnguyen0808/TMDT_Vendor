import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/common/shimmers/applianceslist_shimmer.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/appliances_controller.dart';
import 'package:appliances_flutter/hooks/category_list_hook.dart';

class ChooseCategory extends HookWidget {
  const ChooseCategory({
    super.key,
    required this.next,
  });
  final Function() next;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppliancesController());
    final hookResults = fetchCategories();
    final categories = hookResults.data;
    final isLoading = hookResults.isLoading;
    final error = hookResults.error;

    if (isLoading) {
      return const AppliancesListShimmer();
    }
    if (error != null) {
      return Center(
        child: Text(error.toString()),
      );
    }

    return SizedBox(
        height: hieght,
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 12.h, bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableText(
                      text: "Chọn danh mục",
                      style: appStyle(16, kGray, FontWeight.w600)),
                  ReusableText(
                      text:
                          "Bạn cần chọn danh mục để tiếp tục thêm món",
                      style: appStyle(11, kGray, FontWeight.normal)),
                ],
              ),
            ),
            SizedBox(
              height: hieght * 0.8,
              child: ListView.builder(
                  itemCount: categories!.length,
                  itemBuilder: (context, i) {
                    final category = categories[i];
                    return ListTile(
                      onTap: () {
                        controller.setCategory = category.id;
                        next();
                      },
                      leading: CircleAvatar(
                          radius: 18.r,
                          backgroundColor: kPrimary,
                          child: Image.network(category.imageUrl,
                              fit: BoxFit.contain)),
                      title: ReusableText(
                          text: category.title,
                          style: appStyle(12, kGray, FontWeight.normal)),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: kGray,
                        size: 15.sp,
                      ),
                    );
                  }),
            )
          ],
        ));
  }
}
