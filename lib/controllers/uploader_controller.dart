// ignore_for_file: prefer_final_fields

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:appliances_flutter/constants/constants.dart';

class UploaderController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final box = GetStorage();
  RxBool _busy = false.obs;
  bool get isBusy => _busy.value;

  var imageOne = Rxn<File>();
  var imageTwo = Rxn<File>();
  var imageThree = Rxn<File>();
  var imageFour = Rxn<File>();
  var logo = Rxn<File>();
  var cover = Rxn<File>();

  RxList<String> _images = <String>[].obs;

  List<String> get images => _images;

  set setImages(String newValue) {
    _images.add(newValue);
  }

  void resetList() {
    _images.clear();
  }

  RxString _imageOneUrl = ''.obs;
  RxString _imageTwoUrl = ''.obs;
  RxString _imageThreeUrl = ''.obs;
  RxString _imageFourUrl = ''.obs;
  RxString _logoUrl = ''.obs;
  RxString _coverUrl = ''.obs;

  String get imageOneUrl => _imageOneUrl.value;

  String get imageTwoUrl => _imageTwoUrl.value;

  String get imageThreeUrl => _imageThreeUrl.value;

  String get imageFourUrl => _imageFourUrl.value;

  String get logoUrl => _logoUrl.value;

  String get coverUrl => _coverUrl.value;

  set setLogoUrl(String newValue) {
    _logoUrl.value = newValue;
  }

  set setCoverUrl(String newValue) {
    _coverUrl.value = newValue;
  }

  set setImageOneUrl(String newValue) {
    _imageOneUrl.value = newValue;
    images.add(newValue);
  }

  set setImageTwoUrl(String newValue) {
    _imageTwoUrl.value = newValue;
    images.add(newValue);
  }

  set setImageThreeUrl(String newValue) {
    _imageThreeUrl.value = newValue;
    images.add(newValue);
  }

  set setImageFourUrl(String newValue) {
    _imageFourUrl.value = newValue;
    images.add(newValue);
  }
  // pick image

  Future<void> pickImage(String type) async {
    if (_busy.value) return;
    _busy.value = true;
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      if (type == 'one') {
        imageOne.value = File(pickedImage.path);
        await uploadImageToCloudinary('one');
        return;
      } else if (type == 'two') {
        imageTwo.value = File(pickedImage.path);
        await uploadImageToCloudinary('two');
        return;
      } else if (type == 'three') {
        imageThree.value = File(pickedImage.path);
        await uploadImageToCloudinary('three');
        return;
      } else if (type == 'four') {
        imageFour.value = File(pickedImage.path);
        await uploadImageToCloudinary('four');
        return;
      } else if (type == 'logo') {
        logo.value = File(pickedImage.path);
        await uploadImageToCloudinary('logo');
        return;
      } else if (type == 'cover') {
        cover.value = File(pickedImage.path);
        await uploadImageToCloudinary('cover');
        return;
      }
    }
  }

  Future<void> uploadImageToCloudinary(String type) async {
    try {
      File? file;
      if (type == 'one') file = imageOne.value;
      if (type == 'two') file = imageTwo.value;
      if (type == 'three') file = imageThree.value;
      if (type == 'four') file = imageFour.value;
      if (type == 'logo') file = logo.value;
      if (type == 'cover') file = cover.value;
      if (file == null) {
        _busy.value = false;
        return;
      }

      final uri = Uri.parse(appBaseUrl + '/api/upload/image');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] =
          'Bearer ' + (box.read('accessToken') ?? '');

      request.fields['folder'] = 'tmdt';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200) {
        final jsonResp = json.decode(resp.body);
        final imageUrl =
            (jsonResp['secure_url'] ?? jsonResp['url'] ?? '') as String;
        if (imageUrl.isEmpty) {
          Get.snackbar(
            'Lỗi',
            'Không thể lấy URL ảnh từ server',
            backgroundColor: kRed,
            colorText: kLightWhite,
          );
          _busy.value = false;
          return;
        }
        if (type == 'one') setImageOneUrl = imageUrl;
        if (type == 'two') setImageTwoUrl = imageUrl;
        if (type == 'three') setImageThreeUrl = imageUrl;
        if (type == 'four') setImageFourUrl = imageUrl;
        if (type == 'logo') setLogoUrl = imageUrl;
        if (type == 'cover') setCoverUrl = imageUrl;

        Get.snackbar(
          'Thành công',
          'Tải ảnh lên thành công',
          backgroundColor: kPrimary,
          colorText: kLightWhite,
        );
        _busy.value = false;
      } else {
        debugPrint(
            'Upload failed ' + resp.statusCode.toString() + ' ' + resp.body);
        Get.snackbar(
          'Lỗi',
          'Tải ảnh lên thất bại: ${resp.statusCode}',
          backgroundColor: kRed,
          colorText: kLightWhite,
        );
        _busy.value = false;
      }
    } catch (e) {
      debugPrint(e.toString());
      Get.snackbar(
        'Lỗi',
        'Lỗi khi tải ảnh: ${e.toString()}',
        backgroundColor: kRed,
        colorText: kLightWhite,
      );
      _busy.value = false;
    }
  }
}
