import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/common/custom_button.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class VendorChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String title;
  const VendorChatDetailPage(
      {super.key, required this.conversationId, required this.title});

  @override
  State<VendorChatDetailPage> createState() => _VendorChatDetailPageState();
}

class _VendorChatDetailPageState extends State<VendorChatDetailPage> {
  final ctrl = Get.find<VendorChatController>();
  final textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ctrl.loadMessages(widget.conversationId);
  }

  @override
  void dispose() {
    textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kOffWhite,
        elevation: 0,
        title: Text(widget.title, style: appStyle(16, kDark, FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return ListView.builder(
                padding: EdgeInsets.all(12.w),
                itemCount: ctrl.messages.length,
                itemBuilder: (_, i) {
                  final m = ctrl.messages[i];
                  final mine = m['senderType'] == 'Vendor';
                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      padding:
                          EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: mine ? kPrimary.withOpacity(0.15) : kOffWhite,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: ReusableText(
                        text: m['content']?.toString() ?? '',
                        style: appStyle(14, kDark, FontWeight.w400),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: const BoxDecoration(color: kWhite),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                CustomButton(
                  text: 'Gửi',
                  btnHieght: 40.h,
                  btnWidth: 80.w,
                  onTap: () async {
                    final content = textCtrl.text.trim();
                    if (content.isEmpty) return;
                    await ctrl.sendMessage(widget.conversationId, content);
                    textCtrl.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
