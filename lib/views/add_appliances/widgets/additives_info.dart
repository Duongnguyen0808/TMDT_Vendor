import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/custom_button.dart';
import 'package:appliances_flutter/common/custom_textfield.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/appliances_controller.dart';
import 'package:appliances_flutter/models/add_appliances_models.dart';

class AdditivesInfo extends StatelessWidget {
  const AdditivesInfo(
      {super.key,
      required this.additivePrice,
      required this.additiveTitle,
      required this.appliancesTags,
      required this.back,
      required this.submit});

  final TextEditingController additivePrice;
  final TextEditingController additiveTitle;
  final TextEditingController appliancesTags;
  final Function back;
  final Function submit;

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
                      text: "Thêm phụ kiện tùy chọn (không bắt buộc)",
                      style: appStyle(16, kGray, FontWeight.w600)),
                  ReusableText(
                      text:
                          "Ví dụ: Bảo hành mở rộng, Phụ kiện đi kèm, Dịch vụ lắp đặt",
                      style: appStyle(11, kGray, FontWeight.normal)),
                ],
              ),
            ),
            SizedBox(
              height: hieght * 0.3,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Column(
                  children: [
                    SizedBox(
                      height: 15.h,
                    ),
                    CustomTextField(
                        controller: additiveTitle,
                        hintText: "Tên phụ kiện (VD: Bảo hành 2 năm)",
                        prefixIcon: const Icon(Icons.add_box)),
                    SizedBox(
                      height: 15.h,
                    ),
                    CustomTextField(
                        controller: additivePrice,
                        hintText: "Giá phụ kiện (VD: 50000)",
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.attach_money)),
                    SizedBox(
                      height: 15.h,
                    ),
                    Obx(
                      () => controller.additivesList.isNotEmpty
                          ? Column(
                              children: List.generate(
                                  controller.additivesList.length, (i) {
                                final additive = controller.additivesList[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5.w),
                                      decoration: BoxDecoration(
                                          color: kGrayLight.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8.r)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ReusableText(
                                              text: additive.title,
                                              style: appStyle(11, kDark,
                                                  FontWeight.normal)),
                                          ReusableText(
                                              text:
                                                  "\$ ${additive.price.toString()}",
                                              style: appStyle(11, kDark,
                                                  FontWeight.normal)),
                                        ],
                                      )),
                                );
                              }),
                            )
                          : const SizedBox.shrink(),
                    ),
                    CustomButton(
                        text: "THÊM PHỤ KIỆN",
                        btnWidth: width,
                        btnColor: kSecondary,
                        btnHieght: 35,
                        btnRadius: 9,
                        onTap: () {
                          if (additivePrice.text.isNotEmpty &&
                              additiveTitle.text.isNotEmpty) {
                            Additive additive = Additive(
                                id: controller.generateId(),
                                title: additiveTitle.text,
                                price: additivePrice.text);

                            controller.addAdditive = additive;
                            additivePrice.text = '';
                            additiveTitle.text = '';
                          } else {
                            Get.snackbar(
                                colorText: kLightWhite,
                                backgroundColor: kRed,
                                "Thiếu thông tin phụ kiện",
                                "Vui lòng điền cả tên và giá phụ kiện");
                          }
                        }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 12.h, bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableText(
                      text: "Thêm thẻ cho sản phẩm",
                      style: appStyle(16, kGray, FontWeight.w600)),
                  ReusableText(
                      text: "VD: Chống dính, Inox 304, Tiết kiệm điện, An toàn",
                      style: appStyle(11, kGray, FontWeight.normal)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.h),
              child: Column(
                children: [
                  CustomTextField(
                      controller: appliancesTags,
                      hintText: "Nhập thẻ (VD: Chất lượng cao)",
                      prefixIcon: const Icon(Icons.label)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Obx(
                () => controller.tags.isNotEmpty
                    ? Row(
                        children: List.generate(controller.tags.length, (i) {
                          return Container(
                            margin: EdgeInsets.only(right: 5.w),
                            decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(8.r)),
                            child: Center(
                              child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 5.h),
                                  child: ReusableText(
                                      text: controller.tags[i],
                                      style: appStyle(
                                          9, kLightWhite, FontWeight.normal))),
                            ),
                          );
                        }),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            SizedBox(
              height: 15.h,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CustomButton(
                text: "THÊM THẺ SẢN PHẨM",
                btnRadius: 6,
                btnHieght: 35,
                btnColor: kSecondary,
                onTap: () {
                  controller.setTags = appliancesTags.text;
                  appliancesTags.text = '';
                },
              ),
            ),
            SizedBox(
              height: 15.h,
            ),
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
                    text: "Gửi",
                    btnWidth: width / 2.3,
                    btnRadius: 6,
                    onTap: () {
                      submit();
                    },
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
