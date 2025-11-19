// ignore_for_file: prefer_collection_literals

import 'package:appliances_flutter/models/store_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vietmap_flutter_plugin/vietmap_flutter_plugin.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/custom_button.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/store_controller.dart';
import 'package:appliances_flutter/controllers/uploader_controller.dart';
import 'package:appliances_flutter/views/auth/widgets/email_textfield.dart';
import 'package:appliances_flutter/views/auth/widgets/map_btn.dart';
import 'package:appliances_flutter/views/auth/policy_page.dart';

class StoreRegistration extends StatefulWidget {
  const StoreRegistration({super.key});

  @override
  State<StoreRegistration> createState() => _StoreRegistrationState();
}

class _StoreRegistrationState extends State<StoreRegistration> {
  final box = GetStorage();
  late final PageController _pageController = PageController(initialPage: 0);
  VietmapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _time = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _postalCode = TextEditingController();
  List<dynamic> _placeList = [];
  List<dynamic> _selectedPlaceList = [];
  final UploaderController uploader = Get.put(UploaderController());
  final StoreController controller = Get.put(StoreController());
  bool _agreePolicy = false;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return null;
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      _safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _title.dispose();
    _time.dispose();
    _address.dispose();
    _postalCode.dispose();
    _mapController = null;
    super.dispose();
  }

  LatLng? _selectedLocation;

  void _onLocationSelected(LatLng coords) {
    _safeSetState(() {
      _selectedLocation = coords;
      _searchController.text = '${coords.latitude}, ${coords.longitude}';
      _placeList = [];
      moveToSelection();
    });
  }

  void moveToSelection() {
    if (!mounted) return;
    if (_selectedLocation != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _selectedLocation!, zoom: 15)));
    }
  }

  void _onSearchChanged(String searchQuery) async {
    final q = searchQuery.trim();
    if (q.isEmpty) {
      _safeSetState(() {
        _placeList = [];
      });
      return;
    }
    final res =
        await Vietmap.autocompleteV4(VietmapAutocompleteParamsV4(text: q));
    res.fold(
      (l) {
        _safeSetState(() {
          _placeList = [];
        });
      },
      (r) {
        _safeSetState(() {
          _placeList = List<dynamic>.from(r);
        });
      },
    );
  }

  String _displayText(dynamic item) {
    try {
      final v = item.display;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = item.name;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = item['display'];
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = item['name'];
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = item['description'];
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    return '';
  }

  String? _refIdOf(dynamic item) {
    try {
      final v = item.refId;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = item['refId'];
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  Future<void> _selectSuggestion(dynamic item) async {
    final refId = _refIdOf(item);
    if (refId != null) {
      final placeRes = await Vietmap.placeV4(refId);
      placeRes.fold(
        (l) {},
        (place) {
          final lat = _asDouble(place.lat);
          final lng = _asDouble(place.lng);
          if (lat != null && lng != null) {
            _onLocationSelected(LatLng(lat, lng));
          }
          final t = _displayText(place);
          if (t.isNotEmpty) {
            if (mounted) {
              _searchController.text = t;
            }
          }
          if (mounted) {
            _selectedPlaceList.add(item);
          }
        },
      );
    } else {
      final geoRes = await Vietmap.geoCodeV4(
          VietmapAutocompleteParamsV4(text: _displayText(item)));
      geoRes.fold(
        (l) {},
        (list) {
          if (list.isNotEmpty) {
            final first = list.first;
            final lat = _asDouble(first.lat);
            final lng = _asDouble(first.lng);
            if (lat != null && lng != null) {
              _onLocationSelected(LatLng(lat, lng));
            }
            final t = _displayText(first);
            if (t.isNotEmpty) {
              if (mounted) {
                _searchController.text = t;
              }
            }
            if (mounted) {
              _selectedPlaceList.add(item);
            }
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kPrimary,
        appBar: AppBar(
          backgroundColor: kPrimary,
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MapBtn(
                  text: "Quay lại",
                  onTap: () {
                    _pageController.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeIn);
                  }),
              ReusableText(
                  text: "Đăng ký cửa hàng",
                  style: appStyle(13, kLightWhite, FontWeight.w600)),
              MapBtn(
                  text: "Tiếp theo",
                  onTap: () {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeIn);
                  }),
            ],
          ),
        ),
        body: SizedBox(
          height: hieght,
          width: width,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              BackGroundContainer(
                child: Stack(
                  children: [
                    Stack(
                      children: [
                        VietmapGL(
                          styleString: vietmapStyleUrl(),
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation ??
                                const LatLng(10.762317, 106.654551),
                            zoom: 15,
                          ),
                          onMapClick: (point, latLng) {
                            _onLocationSelected(latLng);
                          },
                          onMapLongClick: (point, latLng) {
                            _onLocationSelected(latLng);
                          },
                        ),
                        if (_selectedLocation != null && _mapController != null)
                          MarkerLayer(
                            ignorePointer: true,
                            mapController: _mapController!,
                            markers: [
                              Marker(
                                latLng: _selectedLocation!,
                                width: 40,
                                height: 40,
                                child: Icon(Icons.location_on,
                                    color: Colors.red, size: 32.sp),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          color: Colors.white,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                                hintStyle:
                                    appStyle(13, kGray, FontWeight.normal),
                                hintText: 'Tìm địa chỉ của bạn...'),
                          ),
                        ),
                        _placeList.isEmpty
                            ? const SizedBox.shrink()
                            : Expanded(
                                child: Container(
                                  color: Colors.white,
                                  child: ListView.builder(
                                    itemCount: _placeList.length,
                                    itemBuilder: (context, i) {
                                      final item = _placeList[i];
                                      final text = _displayText(item);
                                      return ListTile(
                                        dense: true,
                                        visualDensity: VisualDensity.compact,
                                        title: Text(
                                          text.isNotEmpty ? text : 'Địa điểm',
                                          style: appStyle(
                                              12, kGray, FontWeight.normal),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () {
                                          _selectSuggestion(item);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                height: hieght,
                child: BackGroundContainer(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    children: [
                      SizedBox(
                        height: 20.h,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //Image One
                          GestureDetector(
                            onTap: () {
                              if (!uploader.isBusy) {
                                uploader.pickImage('logo');
                              }
                            },
                            child: Obx(() => Container(
                                  height: 120.h,
                                  width: width / 2.3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: kGrayLight),
                                  ),
                                  child: uploader.isBusy &&
                                          uploader.logoUrl == ''
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : uploader.logoUrl == ''
                                          ? Center(
                                              child: ReusableText(
                                                  text: "Tải lên Logo",
                                                  style: appStyle(16, kDark,
                                                      FontWeight.w600)),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10.r),
                                              child: Image.network(
                                                uploader.logoUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                )),
                          ),

                          //Image Two

                          GestureDetector(
                            onTap: () {
                              if (!uploader.isBusy) {
                                uploader.pickImage('cover');
                              }
                            },
                            child: Obx(() => Container(
                                  height: 120.h,
                                  width: width / 2.3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: kGrayLight),
                                  ),
                                  child: uploader.isBusy &&
                                          uploader.coverUrl == ''
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : uploader.coverUrl == ''
                                          ? Center(
                                              child: ReusableText(
                                                  text: "Tải lên ảnh bìa",
                                                  style: appStyle(16, kDark,
                                                      FontWeight.w600)),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10.r),
                                              child: Image.network(
                                                uploader.coverUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                )),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      EmailTextField(
                        prefixIcon: Icon(
                          AntDesign.edit,
                          size: 14.sp,
                          color: kGray,
                        ),
                        controller: _title,
                        hintText: 'Tiêu đề cửa hàng',
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      GestureDetector(
                        onTap: () async {
                          TimeOfDay? startTime = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 8, minute: 0),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: kPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (startTime != null) {
                            TimeOfDay? endTime = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 22, minute: 0),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: kPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (endTime != null) {
                              final startStr =
                                  '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                              final endStr =
                                  '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
                              _time.text = '$startStr - $endStr';
                            }
                          }
                        },
                        child: AbsorbPointer(
                          child: EmailTextField(
                            prefixIcon: Icon(
                              Icons.access_time,
                              size: 14.sp,
                              color: kGray,
                            ),
                            controller: _time,
                            hintText: 'Giờ hoạt động (Chọn thời gian)',
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      EmailTextField(
                        prefixIcon: Icon(
                          AntDesign.edit,
                          size: 14.sp,
                          color: kGray,
                        ),
                        controller: _postalCode,
                        hintText: 'Mã bưu chính',
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      EmailTextField(
                        prefixIcon: Icon(
                          AntDesign.edit,
                          size: 14.sp,
                          color: kGray,
                        ),
                        controller: _searchController,
                        hintText: 'Địa chỉ',
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      // Chính sách và đồng ý
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _agreePolicy,
                            onChanged: (v) {
                              setState(() => _agreePolicy = v ?? false);
                            },
                            activeColor: kPrimary,
                          ),
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('Tôi đồng ý với ',
                                    style:
                                        appStyle(12, kDark, FontWeight.w400)),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    Get.to(() => const PolicyPage());
                                  },
                                  child: Text('chính sách',
                                      style: appStyle(
                                          12, kPrimary, FontWeight.w600)),
                                ),
                                Text(' của ứng dụng',
                                    style:
                                        appStyle(12, kDark, FontWeight.w400)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      CustomButton(
                        text: "THÊM CỮA HÀNG",
                        btnHieght: 35.h,
                        onTap: () {
                          if (!_agreePolicy) {
                            Get.snackbar(
                              colorText: kLightWhite,
                              backgroundColor: kPrimary,
                              "Yêu cầu",
                              "Vui lòng đồng ý với chính sách để tiếp tục",
                            );
                            return;
                          }
                          if (_time.text.isEmpty ||
                              _title.text.isEmpty ||
                              _postalCode.text.isEmpty ||
                              _searchController.text.isEmpty ||
                              uploader.logoUrl.isEmpty ||
                              uploader.coverUrl.isEmpty) {
                            Get.snackbar(
                              colorText: kLightWhite,
                              backgroundColor: kPrimary,
                              "Lỗi",
                              "Vui lòng điền đầy đủ tất cả các trường",
                            );
                          } else {
                            String owner = box.read("userId");

                            StoreRequest model = StoreRequest(
                                title: _title.text,
                                time: _time.text,
                                owner: owner,
                                code: _postalCode.text,
                                logoUrl: uploader.logoUrl,
                                imageUrl: uploader.coverUrl,
                                coords: Coords(
                                    id: controller.generateId(),
                                    latitude: _selectedLocation!.latitude,
                                    longitude: _selectedLocation!.longitude,
                                    address: _searchController.text,
                                    title: _title.text));

                            String data = storeRequestToJson(model);

                            controller.storeRegistration(data);
                          }
                        },
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
