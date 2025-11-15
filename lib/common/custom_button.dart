import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  const CustomButton(
      {super.key,
      this.onTap,
      this.btnWidth,
      this.btnHieght,
      this.btnColor,
      this.btnRadius,
      required this.text});

  final void Function()? onTap;
  final double? btnWidth;
  final double? btnHieght;
  final double? btnRadius;
  final Color? btnColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          width: btnWidth ?? width,
          height: btnHieght ?? 28.h,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(btnRadius ?? 12.r),
              color: btnColor ?? kPrimary),
          child: Center(
            child: ReusableText(
                text: text, style: appStyle(12, kLightWhite, FontWeight.w500)),
          ),
        ));
  }
}
