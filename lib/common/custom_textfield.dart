import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField(
      {super.key,
      required this.hintText,
      required this.prefixIcon,
      this.maxLines,
      this.onEditingComplete,
      this.keyboardType,
      this.controller});
  final String hintText;
  final Widget prefixIcon;
  final int? maxLines;
  final void Function()? onEditingComplete;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      cursorColor: kDark,
      maxLines: maxLines ?? 1,
      onEditingComplete: onEditingComplete,
      keyboardType: keyboardType,
      controller: controller,
      style: appStyle(12, kDark, FontWeight.normal),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      },
      decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon,
          isDense: true,
          contentPadding: maxLines == 1 ? EdgeInsets.zero : EdgeInsets.all(6.r),
          hintStyle: appStyle(12, kGray, FontWeight.normal),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: kRed, width: 0.5.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: kPrimary, width: 0.5.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: kRed, width: 0.5.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: kGray, width: 0.5.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: kGray, width: 0.5.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: kGray, width: 0.5.w),
            borderRadius: BorderRadius.circular(12.r),
          )),
    );
  }
}
