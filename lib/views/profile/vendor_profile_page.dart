import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';

class VendorProfilePage extends StatefulWidget {
  const VendorProfilePage({super.key});
  @override
  State<VendorProfilePage> createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  final box = GetStorage();
  bool _editing = false;
  bool _loading = false;
  String? _errorMessage;
  final List<String> _logs = [];
  String? _logoUrl;
  Uint8List? _newLogoBytes;
  final _storeNameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocal();
    _fetchRemote();
  }

  void _loadLocal() {
    _storeNameCtrl.text = box.read('storeName') ?? '';
    _ownerCtrl.text = box.read('ownerName') ?? '';
    _phoneCtrl.text = box.read('storePhone') ?? '';
    _addressCtrl.text = box.read('storeAddress') ?? '';
    _timeCtrl.text = box.read('storeTime') ?? '';
    _logoUrl = box.read('storeLogo');
  }

  Future<void> _fetchRemote() async {
    final storeId = box.read('storeId');
    final token = box.read('accessToken');
    if (token == null) {
      _log('Token null -> bỏ qua tải');
      return;
    }
    setState(() => _loading = true);
    Map<String, dynamic>? store;
    try {
      _log('Bắt đầu tải store. storeId=${storeId ?? 'null'}');
      // Try byId
      final prefix =
          '$appBaseUrl/api/store'; // backend uses singular '/api/store'
      if (storeId != null && (storeId as String).isNotEmpty) {
        final resp = await http.get(
          Uri.parse('$prefix/byId/$storeId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        _log('GET /api/store/byId status=${resp.statusCode}');
        if (resp.statusCode == 200) {
          store = jsonDecode(resp.body) as Map<String, dynamic>;
        } else {
          final body = _truncate(resp.body);
          _log('byId thất bại body=$body');
          if (body.contains('Cannot GET')) {
            _log(
                'Cảnh báo: Sai path trước đó? Backend mount là /api/store (singular).');
          }
        }
      }
      // Fallback owner profile
      if (store == null) {
        final resp = await http.get(
          Uri.parse('$prefix/owner/profile'),
          headers: {'Authorization': 'Bearer $token'},
        );
        _log('GET /api/store/owner/profile status=${resp.statusCode}');
        if (resp.statusCode == 200) {
          store = jsonDecode(resp.body) as Map<String, dynamic>;
        } else {
          final body = _truncate(resp.body);
          _log('owner/profile thất bại body=$body');
          if (body.contains('Cannot GET')) {
            _log('Cảnh báo: Sai path - đảm bảo dùng /api/store/owner/profile');
          }
        }
      }
      if (store != null) {
        final coords = store['coords'] as Map<String, dynamic>?;
        setState(() {
          final s = store!;
          final title = s['title'];
          if (title != null && title.toString().isNotEmpty) {
            _storeNameCtrl.text = title.toString();
          }
          final addr = coords?['address'] ?? s['address'];
          if (addr != null && addr.toString().isNotEmpty) {
            _addressCtrl.text = addr.toString();
          }
          final timeVal = s['time'];
          if (timeVal != null && timeVal.toString().isNotEmpty) {
            _timeCtrl.text = timeVal.toString();
          }
          final logoVal = s['logoUrl'] ?? s['imageUrl'];
          if (logoVal != null && logoVal.toString().isNotEmpty) {
            _logoUrl = logoVal.toString();
          }
          if (_ownerCtrl.text.isEmpty && s['owner'] != null) {
            _ownerCtrl.text = s['owner'].toString();
          }
        });
        _log('Map store vào UI: name=${_storeNameCtrl.text}');
        final userResp = await http.get(
          Uri.parse('$appBaseUrl/api/users'),
          headers: {'Authorization': 'Bearer $token'},
        );
        _log('GET user status=${userResp.statusCode}');
        if (userResp.statusCode == 200) {
          final u = jsonDecode(userResp.body) as Map<String, dynamic>;
          setState(() {
            if (u['username'] != null && u['username'].toString().isNotEmpty) {
              _ownerCtrl.text = u['username'].toString();
            }
            if (u['phone'] != null && u['phone'].toString().isNotEmpty) {
              _phoneCtrl.text = u['phone'].toString();
            }
          });
          _log('Map user: owner=${_ownerCtrl.text} phone=${_phoneCtrl.text}');
        } else {
          _log('User fetch thất bại body=${_truncate(userResp.body)}');
        }
        // Persist
        box.write('storeName', _storeNameCtrl.text);
        box.write('ownerName', _ownerCtrl.text);
        box.write('storePhone', _phoneCtrl.text);
        box.write('storeAddress', _addressCtrl.text);
        box.write('storeTime', _timeCtrl.text);
        box.write('storeLogo', _logoUrl);
        _log('Đã lưu dữ liệu vào GetStorage');
      } else {
        _errorMessage = 'Không tìm thấy cửa hàng';
        Get.snackbar('Không tìm thấy', 'Không lấy được dữ liệu cửa hàng');
        _log('Store null sau các request');
      }
    } catch (e) {
      _errorMessage = 'Lỗi: $e';
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu: $e');
      _log('Exception: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _saveChanges() async {
    final token = box.read('accessToken');
    if (token == null) {
      Get.snackbar('Lỗi', 'Thiếu access token');
      return;
    }
    // Chuẩn bị payload chỉ với các field chỉnh sửa
    final payload = <String, dynamic>{
      'title': _storeNameCtrl.text.trim(),
      'time': _timeCtrl.text.trim(),
      'coords': {
        'address': _addressCtrl.text.trim(),
      },
      // logoUrl sẽ được gửi nếu đã có URL (upload ảnh riêng nếu cần)
      if (_logoUrl != null && _logoUrl!.isNotEmpty) 'logoUrl': _logoUrl,
    };
    setState(() => _loading = true);
    try {
      _log('PUT cập nhật store payload=${jsonEncode(payload)}');
      final resp = await http.put(
        Uri.parse('$appBaseUrl/api/store/owner/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      _log(
          'PUT /api/store/owner/profile status=${resp.statusCode} body=${_truncate(resp.body, 180)}');
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        Map<String, dynamic>? store;
        if (decoded is Map<String, dynamic>) {
          if (decoded['store'] is Map<String, dynamic>) {
            store = decoded['store'] as Map<String, dynamic>;
          } else if (decoded.containsKey('title') ||
              decoded.containsKey('coords')) {
            store = decoded;
          }
        }
        if (store != null) {
          final coords = store['coords'] as Map<String, dynamic>?;
          _storeNameCtrl.text =
              store['title']?.toString() ?? _storeNameCtrl.text;
          _timeCtrl.text = store['time']?.toString() ?? _timeCtrl.text;
          if (coords != null && coords['address'] != null) {
            _addressCtrl.text = coords['address'].toString();
          }
          if (store['logoUrl'] != null &&
              store['logoUrl'].toString().isNotEmpty) {
            _logoUrl = store['logoUrl'].toString();
          }
          // persist
          box.write('storeName', _storeNameCtrl.text);
          box.write('storeAddress', _addressCtrl.text);
          box.write('storeTime', _timeCtrl.text);
          box.write('storeLogo', _logoUrl);
        }
        Get.snackbar('Thành công', 'Đã lưu thay đổi hồ sơ cửa hàng');
        setState(() => _editing = false);
      } else {
        Get.snackbar('Lỗi', 'Không thể lưu: ${_truncate(resp.body, 120)}');
      }
    } catch (e) {
      _log('Exception PUT: $e');
      Get.snackbar('Lỗi', 'Gặp lỗi khi lưu: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final res =
          await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
      if (res != null) {
        final bytes = await res.readAsBytes();
        setState(() => _newLogoBytes = bytes);
        _log('Chọn logo mới bytes=${bytes.length}');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể chọn ảnh: $e');
      _log('Lỗi chọn ảnh: $e');
    }
  }

  void _log(String message) {
    debugPrint('[VendorProfile] $message');
    _logs.add('${DateTime.now().toIso8601String()} $message');
  }

  String _truncate(String input, [int max = 140]) {
    if (input.length <= max) return input;
    return input.substring(0, max) + '...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cửa hàng'),
        actions: [
          if (!_editing)
            IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _editing = true))
          else
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _editing = false))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _ProfileHeader(
                  storeName: _storeNameCtrl.text.isEmpty
                      ? 'Cửa hàng'
                      : _storeNameCtrl.text,
                  logoUrl: _newLogoBytes != null ? '' : (_logoUrl ?? ''),
                  logoBytes: _newLogoBytes,
                  editing: _editing,
                  onPick: _pickLogo,
                ),
                SizedBox(height: 20.h),
                _editing
                    ? _EditableField(
                        controller: _storeNameCtrl, label: 'Tên cửa hàng')
                    : _InfoRow(
                        label: 'Tên cửa hàng',
                        value: _storeNameCtrl.text.isEmpty
                            ? 'Chưa có'
                            : _storeNameCtrl.text),
                _editing
                    ? _EditableField(
                        controller: _ownerCtrl, label: 'Chủ cửa hàng')
                    : _InfoRow(
                        label: 'Chủ cửa hàng',
                        value: _ownerCtrl.text.isEmpty
                            ? 'Chưa có'
                            : _ownerCtrl.text),
                _editing
                    ? _EditableField(
                        controller: _phoneCtrl,
                        label: 'Số điện thoại',
                        keyboardType: TextInputType.phone)
                    : _InfoRow(
                        label: 'Số điện thoại',
                        value:
                            _phoneCtrl.text.isEmpty ? '---' : _phoneCtrl.text),
                _editing
                    ? _EditableField(controller: _addressCtrl, label: 'Địa chỉ')
                    : _InfoRow(
                        label: 'Địa chỉ',
                        value: _addressCtrl.text.isEmpty
                            ? 'Chưa có'
                            : _addressCtrl.text),
                _editing
                    ? _EditableField(
                        controller: _timeCtrl, label: 'Thời gian hoạt động')
                    : _InfoRow(
                        label: 'Thời gian hoạt động',
                        value: _timeCtrl.text.isEmpty
                            ? 'Chưa có'
                            : _timeCtrl.text),
                SizedBox(height: 24.h),
                if (_errorMessage != null)
                  Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.red.withOpacity(.3)),
                    ),
                    child: Text(_errorMessage!,
                        style:
                            appStyle(12, Colors.red.shade700, FontWeight.w500)),
                  ),
                if (_editing)
                  ElevatedButton.icon(
                      onPressed: _loading ? null : _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu thay đổi'))
              ],
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String storeName;
  final String logoUrl;
  final Uint8List? logoBytes;
  final bool editing;
  final VoidCallback onPick;
  const _ProfileHeader(
      {required this.storeName,
      required this.logoUrl,
      required this.logoBytes,
      required this.editing,
      required this.onPick});
  @override
  Widget build(BuildContext context) {
    Widget avatarChild;
    if (logoBytes != null) {
      avatarChild = ClipRRect(
          borderRadius: BorderRadius.circular(30.r),
          child: Image.memory(logoBytes!,
              fit: BoxFit.cover, width: 60, height: 60));
    } else if (logoUrl.isNotEmpty) {
      avatarChild = ClipRRect(
          borderRadius: BorderRadius.circular(30.r),
          child: Image.network(logoUrl,
              fit: BoxFit.cover,
              width: 60,
              height: 60,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.storefront, color: kPrimary, size: 30.sp)));
    } else {
      avatarChild = Icon(Icons.storefront, color: kPrimary, size: 30.sp);
    }
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient:
            LinearGradient(colors: [kPrimary.withOpacity(.15), kOffWhite]),
        border: Border.all(color: kPrimary.withOpacity(.25)),
      ),
      child: Row(children: [
        Stack(children: [
          CircleAvatar(
              radius: 30.r,
              backgroundColor: kPrimary.withOpacity(.2),
              child: avatarChild),
          if (editing)
            Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                    onTap: onPick,
                    child: Container(
                        decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(14.r)),
                        padding: EdgeInsets.all(4.w),
                        child: Icon(Icons.camera_alt,
                            size: 14.sp, color: kLightWhite))))
        ]),
        SizedBox(width: 16.w),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ReusableText(
              text: storeName, style: appStyle(16, kDark, FontWeight.w700)),
          SizedBox(height: 6.h),
          ReusableText(
              text:
                  'Logo: ${logoUrl.isNotEmpty || logoBytes != null ? 'Đã chọn' : 'Chưa có'}',
              style: appStyle(11, kGray, FontWeight.w400)),
        ]))
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 120.w,
            child: Text(label, style: appStyle(12, kGray, FontWeight.w500))),
        Expanded(
            child: Text(value, style: appStyle(13, kDark, FontWeight.w600))),
      ]),
    );
  }
}

class _EditableField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  const _EditableField(
      {required this.controller, required this.label, this.keyboardType});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: 1,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          filled: true,
          fillColor: kOffWhite,
        ),
      ),
    );
  }
}
