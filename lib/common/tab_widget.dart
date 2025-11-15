import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TabWidget extends StatelessWidget {
  const TabWidget({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.h),
      width: MediaQuery.of(context).size.width / 5,
      height: 25.h,
      child: Center(
        child: Text(text),
      ),
    );
  }
}
