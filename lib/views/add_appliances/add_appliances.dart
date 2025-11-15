import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/appliances_controller.dart';
import 'package:appliances_flutter/controllers/store_controller.dart';
import 'package:appliances_flutter/controllers/uploader_controller.dart';
import 'package:appliances_flutter/models/add_appliances_models.dart';
import 'package:appliances_flutter/views/add_appliances/widgets/additives_info.dart';
import 'package:appliances_flutter/views/add_appliances/widgets/all_categories.dart';
import 'package:appliances_flutter/views/add_appliances/widgets/appliances_info.dart';
import 'package:appliances_flutter/views/add_appliances/widgets/image_uploads.dart';

class AddAppliancess extends StatefulWidget {
  const AddAppliancess({super.key});

  @override
  State<AddAppliancess> createState() => _AddAppliancesState();
}

class _AddAppliancesState extends State<AddAppliancess> {
  final PageController _pageController = PageController();
  final TextEditingController title = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController preparation = TextEditingController();
  final TextEditingController types = TextEditingController();
  final TextEditingController additivePrice = TextEditingController();
  final TextEditingController additiveTitle = TextEditingController();
  final TextEditingController appliancesTags = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    preparation.dispose();
    types.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building AddAppliancess page');
    final controller = Get.put(AppliancesController());
    final images = Get.put(UploaderController());
    final store = Get.put(StoreController());
    print('📦 Controllers initialized');
    print('Store: ${store.store?.id}, Code: ${store.store?.code}');
    return Scaffold(
      backgroundColor: kSecondary,
      appBar: AppBar(
        backgroundColor: kSecondary,
        centerTitle: false,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableText(
                text: "Chào mừng đến bảng điều khiển cửa hàng",
                style: appStyle(14, kLightWhite, FontWeight.w600)),
            ReusableText(
                text: "Điền đầy đủ thông tin để thêm sản phẩm vào ứng dụng",
                style: appStyle(12, kLightWhite, FontWeight.normal)),
          ],
        ),
      ),
      body: BackGroundContainer(
        child: ListView(
          children: [
            SizedBox(
              width: width,
              height: hieght,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                pageSnapping: false,
                children: [
                  ChooseCategory(
                    next: () {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    },
                  ),
                  ImageUploads(
                    back: () {
                      _pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    },
                    next: () {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    },
                  ),
                  AppliancesInfo(
                    back: () {
                      _pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    },
                    next: () {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    },
                    title: title,
                    description: description,
                    price: price,
                    preparation: preparation,
                    types: types,
                  ),
                  AdditivesInfo(
                    additivePrice: additivePrice,
                    additiveTitle: additiveTitle,
                    appliancesTags: appliancesTags,
                    back: () {
                      _pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    },
                    submit: () {
                      // Kiểm tra từng trường và hiển thị lỗi cụ thể
                      List<String> missingFields = [];

                      if (title.text.isEmpty) missingFields.add("Tiêu đề");
                      if (description.text.isEmpty) missingFields.add("Mô tả");
                      if (price.text.isEmpty) missingFields.add("Giá");
                      if (preparation.text.isEmpty)
                        missingFields.add("Thời gian giao hàng");
                      if (controller.types.isEmpty)
                        missingFields.add("Loại sản phẩm");
                      if (controller.tags.isEmpty)
                        missingFields.add("Thẻ sản phẩm");
                      if (images.images.isEmpty)
                        missingFields.add("Hình ảnh sản phẩm");

                      if (missingFields.isNotEmpty) {
                        Get.snackbar(
                            colorText: kLightWhite,
                            backgroundColor: kRed,
                            "Thiếu thông tin",
                            "Các trường còn thiếu: ${missingFields.join(', ')}",
                            duration: const Duration(seconds: 5));
                      } else {
                        try {
                          print('📝 Creating AddAppliancessModel...');
                          print('Title: ${title.text}');
                          print('Tags: ${controller.tags}');
                          print('Types: ${controller.types}');
                          print('Code: ${store.store!.code}');
                          print('Category: ${controller.category}');
                          print('Time: ${preparation.text}');
                          print('Store: ${store.store!.id}');
                          print('Description: ${description.text}');
                          print('Price: ${price.text}');
                          print(
                              'Additives: ${controller.additivesList.length} items');
                          controller.additivesList.forEach((additive) {
                            print(
                                '  - Additive: id=${additive.id} (${additive.id.runtimeType}), title=${additive.title}, price=${additive.price} (${additive.price.runtimeType})');
                          });
                          print('Images: ${images.images}');

                          AddAppliancessModel appliancesItem =
                              AddAppliancessModel(
                                  title: title.text,
                                  appliancesTags: controller.tags,
                                  appliancesType: controller.types,
                                  code: store.store!.code,
                                  category: controller.category,
                                  time: preparation.text,
                                  isAvailable: true,
                                  store: store.store!.id,
                                  description: description.text,
                                  price: double.parse(price.text),
                                  additives: controller.additivesList,
                                  imageUrl: images.images);

                          String data =
                              addAppliancessModelToJson(appliancesItem);
                          print('✅ JSON created successfully: $data');
                          controller.addappliancessFunction(data);
                          images.resetList();
                          controller.additivesList.clear();
                          controller.tags.clear();
                          controller.types.clear();
                        } catch (e, stackTrace) {
                          print('💥 ERROR creating model: $e');
                          print('Stack trace: $stackTrace');
                          Get.snackbar(
                              colorText: kLightWhite,
                              backgroundColor: kRed,
                              "Lỗi dữ liệu",
                              "Chi tiết lỗi: $e",
                              duration: const Duration(seconds: 10));
                        }
                      }
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
