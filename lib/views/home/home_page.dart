import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/custom_appbar.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/views/home/widget/home_tiles.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/views/chat/chat_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimary,
        flexibleSpace: const CustomAppBar(),
      ),
      body: BackGroundContainer(
          child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 15.h,
          ),
          const HomeTiles(),
          SizedBox(
            height: 15.h,
          ),
          // Removed order status tabs & list per request
        ],
      )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        onPressed: () {
          Get.to(() => const VendorChatListPage(),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 600));
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
