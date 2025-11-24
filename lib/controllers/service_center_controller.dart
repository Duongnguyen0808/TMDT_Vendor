import 'dart:convert';

import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/service_ticket.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ServiceCenterController extends GetxController {
  final tickets = <ServiceTicket>[].obs;
  final loading = false.obs;
  final submitting = false.obs;
  final detailLoading = false.obs;
  final selectedStatus = ''.obs;
  final metadata = <String, List<String>>{}.obs;

  final _box = GetStorage();

  String? get _token => _box.read('accessToken');

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    final token = _token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  void onInit() {
    super.onInit();
    fetchMetaOptions();
    fetchTickets();
  }

  Future<void> fetchMetaOptions() async {
    try {
      final uri = Uri.parse('$appBaseUrl/api/service-center/meta/options');
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json is Map && json['data'] is Map) {
          final data = Map<String, dynamic>.from(json['data']);
          metadata.assignAll(data.map((key, value) {
            final list = (value as List?)
                    ?.map((e) => e?.toString() ?? '')
                    .where((e) => e.isNotEmpty)
                    .toList() ??
                <String>[];
            return MapEntry(key, list);
          }));
        }
      }
    } catch (_) {
      // ignore meta errors
    }
  }

  Future<void> fetchTickets({String? status}) async {
    loading(true);
    try {
      final query =
          status != null && status.isNotEmpty ? '?status=$status' : '';
      final uri = Uri.parse('$appBaseUrl/api/service-center/tickets$query');
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List data;
        if (json is Map && json['data'] is List) {
          data = List.from(json['data']);
        } else if (json is List) {
          data = json;
        } else {
          data = [];
        }
        tickets.assignAll(data
            .map((e) => ServiceTicket.fromJson(Map<String, dynamic>.from(e)))
            .toList());
      } else {
        _showError(res.body);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      loading(false);
    }
  }

  Future<ServiceTicket?> fetchTicketDetail(String id) async {
    detailLoading(true);
    try {
      final uri = Uri.parse('$appBaseUrl/api/service-center/tickets/$id');
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = json is Map && json['data'] is Map
            ? Map<String, dynamic>.from(json['data'])
            : Map<String, dynamic>.from(json);
        final ticket = ServiceTicket.fromJson(data);
        _upsert(ticket);
        return ticket;
      }
      _showError(res.body);
    } catch (e) {
      _showError(e.toString());
    } finally {
      detailLoading(false);
    }
    return null;
  }

  Future<bool> createTicket({
    required String subject,
    required String description,
    String? category,
    String? priority,
    String? orderId,
    String? storeId,
  }) async {
    submitting(true);
    try {
      final uri = Uri.parse('$appBaseUrl/api/service-center/tickets');
      final payload = {
        'subject': subject.trim(),
        'description': description.trim(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
        if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
      };
      final res = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201) {
        final json = jsonDecode(res.body);
        final data = json is Map && json['data'] is Map
            ? Map<String, dynamic>.from(json['data'])
            : Map<String, dynamic>.from(json);
        final ticket = ServiceTicket.fromJson(data);
        tickets.insert(0, ticket);
        return true;
      }
      _showError(res.body);
      return false;
    } catch (e) {
      _showError(e.toString());
      return false;
    } finally {
      submitting(false);
    }
  }

  Future<bool> replyTicket({
    required String ticketId,
    required String body,
  }) async {
    detailLoading(true);
    try {
      final uri =
          Uri.parse('$appBaseUrl/api/service-center/tickets/$ticketId/reply');
      final res = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({'message': body.trim()}),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = json is Map && json['data'] is Map
            ? Map<String, dynamic>.from(json['data'])
            : Map<String, dynamic>.from(json);
        final ticket = ServiceTicket.fromJson(data);
        _upsert(ticket);
        return true;
      }
      _showError(res.body);
      return false;
    } catch (e) {
      _showError(e.toString());
      return false;
    } finally {
      detailLoading(false);
    }
  }

  void _upsert(ServiceTicket ticket) {
    final idx = tickets.indexWhere((t) => t.id == ticket.id);
    if (idx >= 0) {
      tickets[idx] = ticket;
      tickets.refresh();
    } else {
      tickets.insert(0, ticket);
    }
  }

  void _showError(String raw) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      'Trung tâm dịch vụ',
      raw.length > 120 ? raw.substring(0, 120) : raw,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade500,
      colorText: Colors.white,
    );
  }
}
