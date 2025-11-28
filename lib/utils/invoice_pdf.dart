import 'dart:convert';
import 'dart:typed_data';

import 'package:appliances_flutter/models/orders_model.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildInvoicePdf(List<OrdersModel> orders) async {
  final baseFont = await _loadFont('assets/fonts/Roboto-Regular.ttf');
  final boldFont =
      await _loadFont('assets/fonts/Roboto-Bold.ttf', fallback: baseFont);
  final italicFont =
      await _loadFont('assets/fonts/Roboto-Italic.ttf', fallback: baseFont);
  final boldItalicFont =
      await _loadFont('assets/fonts/Roboto-BoldItalic.ttf', fallback: boldFont);

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      italic: italicFont,
      boldItalic: boldItalicFont,
    ),
  );
  if (orders.isEmpty) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Center(
          child: pw.Text('Không có đơn hàng để in',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
      ),
    );
    return doc.save();
  }

  for (final order in orders) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _invoiceHeader(order),
          pw.SizedBox(height: 12),
          _section('Thông tin giao nhận', [
            _row('Khách hàng', _customerName(order)),
            _row('Số điện thoại', _customerPhone(order)),
            _row('Địa chỉ giao', _safe(order.deliveryAddress.addressLine1)),
            _row('Thời gian tạo', _formatDate(order.createdAt)),
          ]),
          pw.SizedBox(height: 12),
          _section('Thông tin đơn hàng', [
            _row('Mã đơn', _shortCode(order.id)),
            _row('Phương thức thanh toán', _paymentMethod(order.paymentMethod)),
            _row('Trạng thái thanh toán', _paymentStatus(order.paymentStatus)),
            if ((order.pickupCode ?? '').isNotEmpty)
              _row('Mã giao cho shipper', order.pickupCode!),
            if (order.pickupReadyAt != null)
              _row('Sẵn sàng lúc', _formatDate(order.pickupReadyAt!)),
            _row('Tổng cộng', '${_formatCurrency(order.grandTotal)} đ'),
          ]),
          pw.SizedBox(height: 12),
          _section('Danh sách sản phẩm', [
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(2),
              },
              border: pw.TableBorder.all(width: 0.2),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _tableCell('Sản phẩm', bold: true),
                    _tableCell('SL', bold: true, align: pw.TextAlign.center),
                    _tableCell('Thành tiền',
                        bold: true, align: pw.TextAlign.right),
                  ],
                ),
                ...order.orderItems.map(
                  (item) => pw.TableRow(
                    children: [
                      _tableCell(item.appliancesId.title),
                      _tableCell('${item.quantity}',
                          align: pw.TextAlign.center),
                      _tableCell('${_formatCurrency(item.price)} đ',
                          align: pw.TextAlign.right),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            _row('Tạm tính', '${_formatCurrency(order.orderTotal)} đ'),
            _row('Phí giao hàng', '${_formatCurrency(order.deliveryFee)} đ'),
            pw.Divider(),
            _row('Tổng cộng', '${_formatCurrency(order.grandTotal)} đ',
                bold: true),
          ]),
          if ((order.pickupNotes ?? '').isNotEmpty ||
              (order.deliveryProofNote ?? '').isNotEmpty)
            pw.SizedBox(height: 12),
          if ((order.pickupNotes ?? '').isNotEmpty)
            _section('Ghi chú cửa hàng', [
              pw.Text(order.pickupNotes!),
            ]),
          if ((order.deliveryProofNote ?? '').isNotEmpty)
            pw.SizedBox(height: 12),
          if ((order.deliveryProofNote ?? '').isNotEmpty)
            _section('Ghi chú giao hàng', [
              pw.Text(order.deliveryProofNote!),
            ]),
          pw.SizedBox(height: 12),
          pw.Text('Ký nhận: ________________________________'),
        ],
      ),
    );
  }

  return doc.save();
}

pw.Widget _invoiceHeader(OrdersModel order) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400, width: 0.4),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          order.storeId.title.isEmpty ? 'Phiếu đóng gói' : order.storeId.title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text('Mã đơn: ${_shortCode(order.id)}'),
        pw.Text('Ngày tạo: ${_formatDate(order.createdAt)}'),
      ],
    ),
  );
}

pw.Widget _section(String title, List<pw.Widget> children) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400, width: 0.3),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

pw.Widget _row(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 155,
          child: pw.Text(label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              )),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value.isEmpty ? '--' : value,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        )
      ],
    ),
  );
}

pw.Widget _tableCell(String text,
    {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null),
    ),
  );
}

String _shortCode(String id) {
  if (id.isEmpty) return '---';
  if (id.length <= 8) return id.toUpperCase();
  return id.substring(id.length - 8).toUpperCase();
}

String _safe(String value) => value.isEmpty ? '--' : value;

String _formatCurrency(num value) {
  final intVal = value.round();
  final sign = intVal < 0 ? '-' : '';
  final digits = intVal.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final idxFromEnd = digits.length - i - 1;
    if (idxFromEnd % 3 == 0 && i != digits.length - 1) {
      buffer.write('.');
    }
  }
  return sign + buffer.toString();
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

String _paymentMethod(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'cod':
      return 'COD - Thu hộ';
    case 'cash':
      return 'Tiền mặt';
    case 'wallet':
      return 'Ví khách';
    case 'banktransfer':
    case 'bank_transfer':
      return 'Chuyển khoản';
    case 'card':
    case 'credit':
    case 'debit':
      return 'Thẻ ngân hàng';
    default:
      return raw == null || raw.isEmpty ? '--' : raw;
  }
}

String _paymentStatus(String? raw) {
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

String _customerName(OrdersModel order) {
  const nameKeys = ['fullName', 'fullname', 'name', 'displayName', 'username'];
  final profile = _profileMap(order);
  final metadata = _metadataMap(order);
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
  for (final source in sources) {
    final normalized = source?.trim() ?? '';
    if (normalized.isNotEmpty) return normalized;
  }
  return 'Không có';
}

String _customerPhone(OrdersModel order) {
  const phoneKeys = [
    'phone',
    'phoneNumber',
    'mobile',
    'contactPhone',
    'recipientPhone'
  ];
  final profile = _profileMap(order);
  final metadata = _metadataMap(order);
  final sources = [
    order.userId.phone,
    _stringValue(order.userId.raw['phone']),
    _valueFromMap(order.userId.raw, phoneKeys),
    _valueFromMap(profile, phoneKeys),
    _valueFromMap(metadata, phoneKeys),
  ];
  for (final source in sources) {
    final normalized = source?.trim() ?? '';
    if (normalized.isNotEmpty) return normalized;
  }
  return 'Không có';
}

Map<String, dynamic> _profileMap(OrdersModel order) {
  final direct = _mapFromDynamic(order.userId.raw['profile']);
  if (direct.isNotEmpty) return direct;
  return _decodeStringMap(order.userId.profile);
}

Map<String, dynamic> _metadataMap(OrdersModel order) {
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

Future<pw.Font> _loadFont(String assetPath, {pw.Font? fallback}) async {
  try {
    final data = await rootBundle.load(assetPath);
    return pw.Font.ttf(data);
  } catch (_) {
    return fallback ?? pw.Font.helvetica();
  }
}
