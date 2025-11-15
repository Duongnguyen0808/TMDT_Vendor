import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeTile extends StatelessWidget {
  const HomeTile(
      {super.key, this.onTap, required this.text, required this.icon});

  final void Function()? onTap;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: kPrimary,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 4.h),
          ReusableText(text: text, style: appStyle(11, kGray, FontWeight.w500))
        ],
      ),
    );
  }
}
