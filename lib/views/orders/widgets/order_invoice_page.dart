import 'dart:convert';

import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/utils/invoice_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';

class OrderInvoicePage extends StatefulWidget {
  const OrderInvoicePage({super.key, required this.order});

  final OrdersModel order;

  @override
  State<OrderInvoicePage> createState() => _OrderInvoicePageState();
}

class _OrderInvoicePageState extends State<OrderInvoicePage> {
  bool _processing = false;

  OrdersModel get order => widget.order;
  String get _shortId => _shortCode(order.id);

  @override
  Widget build(BuildContext context) {
    final createdAt = _formatDate(order.createdAt);
    return Scaffold(
      appBar: AppBar(
        title: Text('Phiếu đóng gói #$_shortId'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _buildHeader(createdAt),
              SizedBox(height: 16.h),
              _buildSection('Thông tin giao nhận', [
                _infoRow('Khách hàng', _customerName),
                SizedBox(height: 6.h),
                _infoRow('Số điện thoại', _customerPhone),
                SizedBox(height: 6.h),
                _infoRow(
                  'Địa chỉ giao',
                  order.deliveryAddress.addressLine1.isEmpty
                      ? '--'
                      : order.deliveryAddress.addressLine1,
                ),
              ]),
              SizedBox(height: 16.h),
              _buildSection('Thông tin đơn hàng', [
                _infoRow('Mã đơn', '#$_shortId'),
                SizedBox(height: 6.h),
                _infoRow('Phương thức thanh toán',
                    _paymentMethodLabel(order.paymentMethod)),
                SizedBox(height: 6.h),
                _infoRow('Trạng thái thanh toán',
                    _paymentStatusLabel(order.paymentStatus)),
                if (order.paymentMethod != null &&
                    order.paymentMethod!.toUpperCase() == 'COD') ...[
                  SizedBox(height: 6.h),
                  _infoRow(
                      'Khách trả khi nhận', '${formatVND(order.grandTotal)} đ'),
                ],
                if ((order.pickupCode ?? '').isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  _infoRow('Mã giao cho shipper', order.pickupCode!),
                ],
                if (order.pickupReadyAt != null) ...[
                  SizedBox(height: 6.h),
                  _infoRow('Sẵn sàng lúc', _formatDate(order.pickupReadyAt!)),
                ],
              ]),
              SizedBox(height: 16.h),
              _buildSection('Chi tiết sản phẩm', [
                ...order.orderItems.map(_buildItemRow),
                Divider(height: 24.h),
                _totalRow('Tạm tính', order.orderTotal),
                SizedBox(height: 4.h),
                _totalRow('Phí giao hàng', order.deliveryFee),
                SizedBox(height: 6.h),
                Divider(height: 24.h),
                _totalRow('Tổng cộng', order.grandTotal, highlight: true),
              ]),
              if ((order.pickupNotes ?? '').isNotEmpty ||
                  (order.deliveryProofNote ?? '').isNotEmpty) ...[
                SizedBox(height: 16.h),
                _buildSection('Ghi chú', [
                  if ((order.pickupNotes ?? '').isNotEmpty)
                    _infoRow('Cửa hàng', order.pickupNotes!),
                  if ((order.deliveryProofNote ?? '').isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _infoRow('Giao hàng', order.deliveryProofNote!),
                  ],
                ]),
              ],
              SizedBox(height: 24.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  FilledButton.icon(
                    onPressed: _processing ? null : _handleSharePdf,
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('Chia sẻ PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _processing ? null : _handlePrintPdf,
                    icon: const Icon(Icons.print),
                    label: const Text('In phiếu ngay'),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Mẹo: Chia sẻ file PDF cho shipper hoặc tự in ra để dán lên kiện hàng.',
                style: appStyle(12, kGray, FontWeight.w500),
              ),
            ],
          ),
          if (_processing)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String createdAt) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: kOffWhite,
        border: Border.all(color: kGrayLight.withOpacity(.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReusableText(
            text: order.storeId.title.isEmpty
                ? 'Phiếu đóng gói'
                : order.storeId.title,
            style: appStyle(16, kDark, FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          ReusableText(
            text: 'Ngày tạo: $createdAt',
            style: appStyle(12, kGray, FontWeight.w500),
          ),
          if ((order.deliveryIssueStatus ?? '').isNotEmpty) ...[
            SizedBox(height: 4.h),
            ReusableText(
              text: 'Ghi chú trạng thái: ${order.deliveryIssueStatus}',
              style: appStyle(11, Colors.orange.shade700, FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: kGrayLight.withOpacity(.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReusableText(
            text: title,
            style: appStyle(14, kDark, FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130.w,
          child: Text(
            label,
            style: appStyle(12, kGray, FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '--' : value,
            style: appStyle(13, kDark, FontWeight.w600),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: item.appliancesId.title,
                  style: appStyle(13, kDark, FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                ReusableText(
                  text: 'SL: ${item.quantity}',
                  style: appStyle(12, kGray, FontWeight.w500),
                ),
              ],
            ),
          ),
          ReusableText(
            text: '${formatVND(item.price)} đ',
            style: appStyle(13, kDark, FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ReusableText(
          text: label,
          style: appStyle(13, highlight ? kDark : kGray, FontWeight.w600),
        ),
        ReusableText(
          text: '${formatVND(amount)} đ',
          style: appStyle(14, highlight ? kPrimary : kDark, FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _handleSharePdf() async {
    await _processInvoice(() async {
      final bytes = await buildInvoicePdf([order]);
      await Printing.sharePdf(bytes: bytes, filename: 'packing_$_shortId.pdf');
    });
  }

  Future<void> _handlePrintPdf() async {
    await _processInvoice(() async {
      final bytes = await buildInvoicePdf([order]);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    });
  }

  Future<void> _processInvoice(Future<void> Function() action) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await action();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xuất phiếu: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String get _customerName {
    const nameKeys = [
      'fullName',
      'fullname',
      'name',
      'displayName',
      'username'
    ];
    final profile = _profileMap;
    final metadata = _metadataMap;
    final sources = [
      order.userId.name,
      order.userId.displayName,
      _stringValue(order.userId.raw['username']),
      _stringValue(order.userId.raw['email']),
      _valueFromMap(order.userId.raw, nameKeys),
      _valueFromMap(profile, nameKeys),
      _valueFromMap(metadata, nameKeys),
      order.deliveryProofRecipient,
    ];
    for (final value in sources) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return 'Không có';
  }

  String get _customerPhone {
    const phoneKeys = [
      'phone',
      'phoneNumber',
      'mobile',
      'contactPhone',
      'recipientPhone'
    ];
    final profile = _profileMap;
    final metadata = _metadataMap;
    final sources = [
      order.userId.phone,
      _stringValue(order.userId.raw['phone']),
      _valueFromMap(order.userId.raw, phoneKeys),
      _valueFromMap(profile, phoneKeys),
      _valueFromMap(metadata, phoneKeys),
    ];
    for (final value in sources) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return 'Không có';
  }

  Map<String, dynamic> get _profileMap {
    final direct = _mapFromDynamic(order.userId.raw['profile']);
    if (direct.isNotEmpty) return direct;
    return _decodeStringMap(order.userId.profile);
  }

  Map<String, dynamic> get _metadataMap {
    return _mapFromDynamic(order.userId.raw['metadata']);
  }

  Map<String, dynamic>? _tryDecodeJson(String source) {
    try {
      final parsed = jsonDecode(source);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _mapFromDynamic(dynamic source) {
    if (source is Map<String, dynamic>) {
      return Map<String, dynamic>.from(source);
    }
    if (source is Map) {
      final map = <String, dynamic>{};
      source.forEach((key, value) {
        map[key.toString()] = value;
      });
      return map;
    }
    if (source is String) {
      return _decodeStringMap(source);
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _decodeStringMap(String? raw) {
    final normalized = raw?.trim() ?? '';
    if (normalized.isEmpty) return const <String, dynamic>{};
    final decoded = _tryDecodeJson(normalized);
    if (decoded != null) return decoded;
    try {
      final base64Decoded = utf8.decode(base64.decode(normalized));
      final base64Map = _tryDecodeJson(base64Decoded);
      if (base64Map != null) return base64Map;
    } catch (_) {}
    return const <String, dynamic>{};
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  String? _valueFromMap(Map<String, dynamic> map, List<String> keys,
      {int depth = 0}) {
    if (map.isEmpty || depth > 2) return null;
    for (final key in keys) {
      final value = _stringValue(map[key]);
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    for (final entry in map.entries) {
      final nested = entry.value;
      if (nested is Map) {
        final result =
            _valueFromMap(_mapFromDynamic(nested), keys, depth: depth + 1);
        if (result != null) return result;
      } else if (nested is List) {
        for (final item in nested) {
          if (item is Map) {
            final result =
                _valueFromMap(_mapFromDynamic(item), keys, depth: depth + 1);
            if (result != null) return result;
          }
        }
      }
    }
    return null;
  }

  String _paymentMethodLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'cod':
        return 'COD - Thu hộ';
      case 'cash':
        return 'Tiền mặt';
      case 'wallet':
        return 'Ví khách';
      case 'banktransfer':
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      case 'card':
      case 'credit':
      case 'debit':
        return 'Thẻ ngân hàng';
      default:
        return raw == null || raw.isEmpty ? '--' : raw;
    }
  }

  String _paymentStatusLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'paid':
      case 'succeeded':
      case 'completed':
        return 'Đã thanh toán';
      case 'pending':
      case 'processing':
      case 'awaiting_payment':
        return 'Chờ thanh toán';
      case 'refunded':
      case 'partially_refunded':
        return 'Đã hoàn tiền';
      case 'failed':
      case 'canceled':
      case 'cancelled':
        return 'Thanh toán thất bại';
      default:
        return raw == null || raw.isEmpty ? 'Không xác định' : raw;
    }
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  String _shortCode(String id) {
    if (id.isEmpty) return '---';
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(id.length - 8).toUpperCase();
  }
}
