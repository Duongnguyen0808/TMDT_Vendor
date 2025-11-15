// ignore_for_file: prefer_collection_literals

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';

class MapBtn extends StatelessWidget {
  const MapBtn({
    super.key,
    this.onTap,
    required this.text,
  });

  final void Function()? onTap;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 25,
        width: 70,
        decoration: BoxDecoration(
          border: Border.all(color: kLightWhite, width: 0.5),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Center(
          child: ReusableText(
              text: text, style: appStyle(13, kLightWhite, FontWeight.w600)),
        ),
      ),
    );
  }
}
