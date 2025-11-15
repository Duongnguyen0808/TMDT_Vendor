import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/custom_button.dart';
import 'package:appliances_flutter/common/custom_textfield.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/appliancess_model.dart';
import 'package:appliances_flutter/controllers/appliances_controller.dart';

class EditAppliances extends StatefulWidget {
  final AppliancessModel appliances;

  const EditAppliances({super.key, required this.appliances});

  @override
  State<EditAppliances> createState() => _EditAppliancesState();
}

class _EditAppliancesState extends State<EditAppliances> {
  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController timeController;
  bool isUpdating = false; // Prevent double submission

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.appliances.title);
    priceController =
        TextEditingController(text: widget.appliances.price.toString());
    descriptionController =
        TextEditingController(text: widget.appliances.description);
    timeController = TextEditingController(text: widget.appliances.time);
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AppliancesController());

    return Scaffold(
      backgroundColor: kSecondary,
      appBar: AppBar(
        backgroundColor: kSecondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: kLightWhite),
          onPressed: () => Get.back(),
        ),
        title: ReusableText(
          text: "Chỉnh sửa sản phẩm",
          style: appStyle(18, kLightWhite, FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          BackGroundContainer(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              children: [
                // Ảnh sản phẩm
                Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: kGray.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.network(
                      widget.appliances.imageUrl[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: kGrayLight,
                          child: Icon(Icons.image_not_supported,
                              size: 60.sp, color: kGray),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Form fields
                ReusableText(
                  text: "Thông tin sản phẩm",
                  style: appStyle(16, kDark, FontWeight.w600),
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  controller: titleController,
                  hintText: "Tên sản phẩm",
                  prefixIcon: Icon(Icons.shopping_bag, color: kGray),
                ),

                SizedBox(height: 16.h),

                CustomTextField(
                  controller: priceController,
                  hintText: "Giá (đ)",
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(Icons.attach_money, color: kGray),
                ),

                SizedBox(height: 16.h),

                CustomTextField(
                  controller: timeController,
                  hintText: "Thời gian giao hàng (VD: Ship 2-5 ngày)",
                  prefixIcon: Icon(Icons.access_time, color: kGray),
                ),

                SizedBox(height: 16.h),

                CustomTextField(
                  controller: descriptionController,
                  hintText: "Mô tả sản phẩm",
                  maxLines: 5,
                  prefixIcon: Icon(Icons.description, color: kGray),
                ),

                SizedBox(height: 32.h),

                // Buttons
                CustomButton(
                  text: "CẬP NHẬT SẢN PHẨM",
                  btnWidth: width,
                  btnColor: kPrimary,
                  btnHieght: 45,
                  btnRadius: 12,
                  onTap: () async {
                    // Prevent double submission
                    if (isUpdating) return;

                    if (titleController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        timeController.text.isEmpty ||
                        descriptionController.text.isEmpty) {
                      Get.snackbar(
                        "Thiếu thông tin",
                        "Vui lòng điền đầy đủ thông tin",
                        backgroundColor: kRed,
                        colorText: kLightWhite,
                      );
                      return;
                    }

                    setState(() {
                      isUpdating = true;
                    });

                    Map<String, dynamic> updateData = {
                      'title': titleController.text,
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'time': timeController.text,
                      'description': descriptionController.text,
                    };

                    String data = jsonEncode(updateData);

                    print('Cập nhật sản phẩm ${widget.appliances.id}');
                    print('Dữ liệu: $data');

                    bool success = await controller.updateAppliancesFunction(
                        widget.appliances.id, data);

                    // Chỉ reset isUpdating nếu update thất bại (vì nếu thành công thì đã Get.back() rồi)
                    if (!success && mounted) {
                      setState(() {
                        isUpdating = false;
                      });
                    }
                  },
                ),

                SizedBox(height: 12.h),

                CustomButton(
                  text: "HỦY",
                  btnWidth: width,
                  btnColor: kGrayLight,
                  btnHieght: 45,
                  btnRadius: 12,
                  onTap: () => Get.back(),
                ),
              ],
            ),
          ),

          // Loading overlay
          Obx(() => controller.isLoading
              ? Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  ),
                )
              : SizedBox.shrink()),
        ],
      ),
    );
  }
}
