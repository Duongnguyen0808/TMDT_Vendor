import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/appliancess_model.dart';
import 'package:appliances_flutter/views/appliances/edit_appliances.dart';
import 'package:appliances_flutter/controllers/appliances_controller.dart';

class AppliancesTile extends StatefulWidget {
  AppliancesTile({
    super.key,
    required this.appliances,
    this.onUpdate,
    this.onDelete,
  });

  final AppliancessModel appliances;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;

  @override
  State<AppliancesTile> createState() => _AppliancesTileState();
}

class _AppliancesTileState extends State<AppliancesTile> {
  late bool isAvailable;

  @override
  void initState() {
    super.initState();
    isAvailable = widget.appliances.isAvailable;
  }

  Future<void> _toggleAvailability() async {
    final controller = Get.put(AppliancesController());

    setState(() {
      isAvailable = !isAvailable;
    });

    Map<String, dynamic> updateData = {'isAvailable': isAvailable};
    String data = jsonEncode(updateData);

    bool success = await controller.updateAppliancesFunction(
      widget.appliances.id,
      data,
    );

    if (!success) {
      // Revert if failed
      setState(() {
        isAvailable = !isAvailable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.appliances.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: kRed,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: kLightWhite, size: 32.sp),
            SizedBox(height: 4.h),
            ReusableText(
              text: "Xóa",
              style: appStyle(12, kLightWhite, FontWeight.bold),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Xác nhận xóa',
                style: appStyle(16, kDark, FontWeight.bold)),
            content: Text(
              'Bạn có chắc muốn xóa "${widget.appliances.title}"?',
              style: appStyle(14, kGray, FontWeight.normal),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Hủy', style: appStyle(14, kGray, FontWeight.w500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  foregroundColor: kLightWhite,
                ),
                onPressed: () async {
                  Navigator.pop(context, false); // Đóng dialog trước

                  final controller = Get.put(AppliancesController());
                  bool success = await controller
                      .deleteAppliancesFunction(widget.appliances.id);

                  if (success && widget.onDelete != null) {
                    widget.onDelete!(); // Refresh danh sách
                  }
                },
                child: Text('Xóa',
                    style: appStyle(14, kLightWhite, FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      child: GestureDetector(
        onTap: () async {
          final result = await Get.to(
            () => EditAppliances(appliances: widget.appliances),
            transition: Transition.rightToLeft,
            duration: Duration(milliseconds: 300),
          );

          // Nếu có callback và update thành công
          if (result == true && widget.onUpdate != null) {
            widget.onUpdate!();
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Container(
            height: 100.h,
            decoration: BoxDecoration(
              color: isAvailable ? kOffWhite : kGrayLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: kGray.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: kGray.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  isAvailable
                                      ? Colors.transparent
                                      : Colors.grey,
                                  isAvailable
                                      ? BlendMode.dst
                                      : BlendMode.saturation,
                                ),
                                child: Image.network(
                                  widget.appliances.imageUrl[0],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: kGrayLight,
                                      child: Icon(Icons.image_not_supported,
                                          size: 30.w, color: kGray),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (!isAvailable)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.visibility_off,
                                    color: kLightWhite,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ReusableText(
                              text: widget.appliances.title,
                              style: appStyle(
                                13,
                                isAvailable ? kDark : kGray,
                                FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 12.sp, color: kGray),
                                SizedBox(width: 4.w),
                                ReusableText(
                                  text: widget.appliances.time,
                                  style: appStyle(10, kGray, FontWeight.w400),
                                ),
                              ],
                            ),
                            if (widget.appliances.additives.isNotEmpty)
                              SizedBox(
                                height: 22.h,
                                child: ListView.builder(
                                  itemCount:
                                      widget.appliances.additives.length > 3
                                          ? 3
                                          : widget.appliances.additives.length,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, i) {
                                    String title =
                                        widget.appliances.additives[i].title;
                                    return Container(
                                      margin: EdgeInsets.only(right: 6.w),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: kSecondaryLight,
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                        border: Border.all(
                                            color: kGray.withOpacity(0.3),
                                            width: 0.5),
                                      ),
                                      child: Center(
                                        child: ReusableText(
                                          text: title,
                                          style: appStyle(
                                              9, kDark, FontWeight.w500),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 70.w), // Space for price badge
                  ],
                ),
                Positioned(
                  right: 10.w,
                  top: 10.h,
                  child: Column(
                    children: [
                      Container(
                        height: 28.h,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimary, kPrimary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: ReusableText(
                            text:
                                "${widget.appliances.price.toStringAsFixed(0)}đ",
                            style: appStyle(13, kLightWhite, FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Toggle availability switch
                      Container(
                        height: 24.h,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: isAvailable ? kPrimary : kGray,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _toggleAvailability,
                              child: Icon(
                                isAvailable
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: kLightWhite,
                                size: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
