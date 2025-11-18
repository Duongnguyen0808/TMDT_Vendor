import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';

import 'package:appliances_flutter/common/custom_button.dart';
import 'package:appliances_flutter/common/custom_textfield.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/appliances_controller.dart';

class AppliancesInfo extends StatelessWidget {
  const AppliancesInfo(
      {super.key,
      required this.back,
      required this.next,
      required this.title,
      required this.description,
      required this.price,
      required this.preparation,
      required this.types,
      required this.stock});

  final Function back;
  final Function next;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController price;
  final TextEditingController preparation;
  final TextEditingController types;
  final TextEditingController stock;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppliancesController());
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
                      text: "Thêm chi tiết",
                      style: appStyle(16, kGray, FontWeight.w600)),
                  ReusableText(
                      text: "Bạn cần nhập thông tin chính xác",
                      style: appStyle(11, kGray, FontWeight.normal)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  CustomTextField(
                      controller: title,
                      hintText: "Tên sản phẩm (VD: Nồi cơm điện)",
                      prefixIcon: const Icon(Icons.kitchen)),
                  SizedBox(
                    height: 15.h,
                  ),
                  CustomTextField(
                      controller: description,
                      hintText:
                          "Mô tả chi tiết sản phẩm (chất liệu, tính năng...)",
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      prefixIcon: const Icon(Icons.description)),
                  SizedBox(
                    height: 15.h,
                  ),
                  CustomTextField(
                      controller: preparation,
                      hintText: "Thời gian giao hàng (VD: 1-2 ngày, 3-5 ngày)",
                      prefixIcon: const Icon(Icons.local_shipping)),
                  SizedBox(
                    height: 15.h,
                  ),
                  CustomTextField(
                      controller: price,
                      hintText: "Giá sản phẩm (VD: 500000)",
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.attach_money)),
                  SizedBox(
                    height: 15.h,
                  ),
                  CustomTextField(
                      controller: stock,
                      hintText: "Số lượng tồn kho (VD: 100)",
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.inventory)),
                  SizedBox(
                    height: 15.h,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 12.h, bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableText(
                      text: "Thêm loại sản phẩm",
                      style: appStyle(16, kGray, FontWeight.w600)),
                  ReusableText(
                      text: "Thêm ít nhất 1 loại để phân loại sản phẩm",
                      style: appStyle(11, kGray, FontWeight.normal)),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(12.0),
                child: Obx(
                  () => Column(
                    children: [
                      CustomTextField(
                          controller: types,
                          hintText:
                              "Nhập loại (VD: Nồi, Chảo, Bếp, Lò vi sóng)",
                          prefixIcon: const Icon(Icons.category)),
                      SizedBox(
                        height: 15.h,
                      ),
                      controller.types.isNotEmpty
                          ? Row(
                              children:
                                  List.generate(controller.types.length, (i) {
                                return Container(
                                  margin: EdgeInsets.only(right: 5.w),
                                  decoration: BoxDecoration(
                                      color: kPrimary,
                                      borderRadius: BorderRadius.circular(8.r)),
                                  child: Center(
                                    child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 5.h),
                                        child: ReusableText(
                                            text: controller.types[i],
                                            style: appStyle(9, kLightWhite,
                                                FontWeight.normal))),
                                  ),
                                );
                              }),
                            )
                          : const SizedBox.shrink(),
                      SizedBox(
                        height: 15.h,
                      ),
                      CustomButton(
                        text: "Thêm loại sản phẩm",
                        btnColor: kSecondary,
                        onTap: () {
                          controller.setTypes = types.text;
                          types.text = "";
                        },
                        btnRadius: 6,
                      )
                    ],
                  ),
                )),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomButton(
                    text: "Quay lại",
                    btnWidth: width / 2.3,
                    btnRadius: 6,
                    onTap: () {
                      back();
                    },
                  ),
                  CustomButton(
                    text: "Tiếp theo",
                    btnWidth: width / 2.3,
                    btnRadius: 6,
                    onTap: () {
                      next();
                    },
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
