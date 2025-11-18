import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/chat_controller.dart';
import 'package:appliances_flutter/views/chat/chat_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class VendorChatListPage extends StatefulWidget {
  const VendorChatListPage({super.key});

  @override
  State<VendorChatListPage> createState() => _VendorChatListPageState();
}

class _VendorChatListPageState extends State<VendorChatListPage> {
  final ctrl = Get.put(VendorChatController());

  @override
  void initState() {
    super.initState();
    ctrl.loadVendorConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kOffWhite,
        elevation: 0,
        title: Text('Tin nhắn', style: appStyle(16, kDark, FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (ctrl.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.conversations.isEmpty) {
          return Center(
            child: ReusableText(
              text: 'Chưa có hội thoại',
              style: appStyle(14, kGray, FontWeight.w400),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(12.w),
          itemBuilder: (_, i) {
            final c = ctrl.conversations[i];
            final peer = c['peer'];
            final name = (peer != null
                ? (peer['username'] ?? peer['name'])
                : 'Khách hàng');
            final last = c['lastMessage'] ?? '';
            final unread = (c['unread'] ?? 0) as int;
            return ListTile(
              title: Text(name.toString(),
                  style: appStyle(15, kDark, FontWeight.w600)),
              subtitle: Text(last.toString(),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unread > 0)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        style: appStyle(11, kLightWhite, FontWeight.bold),
                      ),
                    ),
                  SizedBox(width: 8.w),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Get.to(() => VendorChatDetailPage(
                    conversationId: c['id'].toString(),
                    title: name.toString()));
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: ctrl.conversations.length,
        );
      }),
    );
  }
}
