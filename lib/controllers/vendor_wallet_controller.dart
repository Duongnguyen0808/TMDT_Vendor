import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/vendor_wallet_model.dart';

class VendorWalletController extends GetxController {
  final box = GetStorage();

  final Rxn<VendorWalletSummary> summary = Rxn<VendorWalletSummary>();
  final RxBool loading = false.obs;
  final RxBool processing = false.obs;
  final RxnString summaryError = RxnString();
  final RxnString actionError = RxnString();

  String? get _token => box.read('accessToken');

  Future<void> fetchWallet() async {
    final token = _token;
    if (token == null) {
      summaryError.value = 'Không tìm thấy token đăng nhập';
      return;
    }
    loading.value = true;
    try {
      final url = Uri.parse('$appBaseUrl/api/vendor-wallet');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        summary.value = VendorWalletSummary.fromJson(
            Map<String, dynamic>.from(data['data'] as Map));
        summaryError.value = null;
      } else {
        summaryError.value = data['message']?.toString() ?? 'Không tải được ví';
      }
    } catch (e) {
      summaryError.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<bool> deposit(int amount, {String? note}) async {
    return _mutateWallet('deposit', amount, note: note);
  }

  Future<bool> withdraw(int amount, {String? note}) async {
    return _mutateWallet('withdraw', amount, note: note);
  }

  Future<bool> _mutateWallet(String endpoint, int amount,
      {String? note}) async {
    final token = _token;
    if (token == null) {
      actionError.value = 'Không tìm thấy token đăng nhập';
      return false;
    }
    processing.value = true;
    try {
      final url = Uri.parse('$appBaseUrl/api/vendor-wallet/$endpoint');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }),
      );
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        summary.value = VendorWalletSummary.fromJson(
            Map<String, dynamic>.from(data['data'] as Map));
        actionError.value = null;
        return true;
      }
      actionError.value =
          data['message']?.toString() ?? 'Không thể thực hiện thao tác';
      return false;
    } catch (e) {
      actionError.value = e.toString();
      return false;
    } finally {
      processing.value = false;
    }
  }
}
