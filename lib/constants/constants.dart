import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

String vietmapApiKey = '2b80a3786959d7a6f08f3d3a9ec4f35d471f93ea4fe39f40';
bool hasRealVietmapKey([String? apiKey]) {
  final key = (apiKey ?? vietmapApiKey).trim();
  return key.isNotEmpty && key.length > 20;
}

String vietmapStyleUrl([String? apiKey]) {
  final key = (apiKey ?? vietmapApiKey).trim();
  if (key.isNotEmpty && key.length > 20) {
    return 'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=' + key;
  }
  return 'https://demotiles.maplibre.org/style.json';
}

const kPrimary = Color(0xFF30b9b2);
const kPrimaryLight = Color(0xFF40F3EA);
const kSecondary = Color(0xffffa44f);
const kSecondaryLight = Color(0xFFffe5db);
const kTertiary = Color(0xff0078a6);
const kGray = Color(0xff83829A);
const kGrayLight = Color(0xffC1C0C8);
const kLightWhite = Color(0xffFAFAFC);
const kWhite = Color(0xfffFFFFF);
const kDark = Color(0xff000000);
const kRed = Color(0xffe81e4d);
const kOffWhite = Color(0xffF3F4F8);

double hieght = 926.h;
double width = 428.w;

// final String appBaseUrl =
//     Platform.isAndroid ? "http://10.0.2.2:6013" : "http://localhost:6013";
final String appBaseUrl = "http://192.168.1.4:6013";

List<String> orderList = [
  "Đơn mới",
  "Đang chuẩn bị",
  "Sẵn sàng",
  "Đã lấy",
  "Tự giao hàng",
  "Đã giao",
  "Đã hủy"
];

Transition? kTransition = Transition.fadeIn;
Duration? kDuration = const Duration(milliseconds: 900);

const String cloudinaryCloudName = 'dibkwyg6e';
const String cloudinaryUploadPreset = 'unsigned';
