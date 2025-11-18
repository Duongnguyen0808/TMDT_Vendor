import 'dart:convert';

import 'package:appliances_flutter/constants/constants.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class VendorChatController extends GetxController {
  final box = GetStorage();
  IO.Socket? socket;

  RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  RxString currentConversationId = ''.obs;
  RxBool loading = false.obs;
  RxMap<String, int> unreadByUser =
      <String, int>{}.obs; // userId -> unread count

  // Vendors seem to store their auth under 'accessToken' while customer side uses 'token'.
  // Fallback to either to avoid missing Authorization header (causing 401 + null conversation).
  String? get token => box.read('accessToken') ?? box.read('token');

  void connectSocket() {
    if (socket != null) return;
    socket = IO.io(
      appBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    socket!.on('message:new', (data) {
      final cid = data['conversation']?.toString();
      if (cid != null && cid == currentConversationId.value) {
        messages.add(Map<String, dynamic>.from(data));
      }
    });
  }

  Future<void> loadVendorConversations() async {
    loading.value = true;
    final url = Uri.parse('$appBaseUrl/api/chat/vendor/conversations');
    final res = await http.get(url, headers: _headers());
    loading.value = false;
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      conversations.assignAll(data.map((e) => Map<String, dynamic>.from(e)));
    }
  }

  Future<void> loadMessages(String conversationId) async {
    final url = Uri.parse(
        '$appBaseUrl/api/chat/conversations/$conversationId/messages?limit=50');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body)['data'] ?? [];
      messages.assignAll(data.map((e) => Map<String, dynamic>.from(e)));
      currentConversationId.value = conversationId;
      connectSocket();
      socket?.emit('join', {'conversationId': conversationId});
    }
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    final url = Uri.parse(
        '$appBaseUrl/api/chat/conversations/$conversationId/messages');
    final res = await http.post(url,
        headers: _headers(), body: jsonEncode({'content': content}));
    return res.statusCode == 201;
  }

  Future<Map<String, dynamic>?> getOrCreateWithUser(String userId) async {
    final url = Uri.parse('$appBaseUrl/api/chat/vendor/conversation');
    final res = await http.post(url,
        headers: _headers(), body: jsonEncode({'userId': userId}));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'];
      return Map<String, dynamic>.from(data);
    }
    // Helpful debug log (avoid print spam in production; leave minimal)
    // (Optional) could parse body for message; omitted to avoid unused var lint.
    return null;
  }

  Future<void> loadUnreadSummary() async {
    final url = Uri.parse('$appBaseUrl/api/chat/vendor/unread-summary');
    final res = await http.get(url, headers: _headers());
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body)['data'] ?? [];
      final map = <String, int>{};
      for (final item in data) {
        final m = Map<String, dynamic>.from(item);
        final uid = (m['userId'] ?? '').toString();
        final unread = int.tryParse((m['unread'] ?? '0').toString()) ?? 0;
        map[uid] = unread;
      }
      unreadByUser.assignAll(map);
    }
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
}
