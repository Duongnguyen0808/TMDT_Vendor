import 'dart:convert';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/api_error.dart';
import 'package:appliances_flutter/models/orders_model.dart';

class MultiOrdersResult {
  final List<OrdersModel>? data;
  final bool isLoading;
  final ApiError? error;
  final int page;
  final int total;
  final bool hasMore;
  final void Function() refetch;
  final void Function() loadMore;
  MultiOrdersResult({
    required this.data,
    required this.isLoading,
    required this.error,
    required this.page,
    required this.total,
    required this.hasMore,
    required this.refetch,
    required this.loadMore,
  });
}

MultiOrdersResult useMultiOrders({
  required List<String> statuses,
  int initialLimit = 20,
  bool includeAllPayments = true,
  String? storeIdOverride,
}) {
  final box = GetStorage();
  final ordersState = useState<List<OrdersModel>>([]);
  final isLoading = useState<bool>(false);
  final errorState = useState<ApiError?>(null);
  final pageState = useState<int>(1);
  final totalState = useState<int>(0);
  final limitState = useState<int>(initialLimit);

  Future<void> fetch({bool append = false}) async {
    final storeId = (storeIdOverride != null && storeIdOverride.isNotEmpty)
        ? storeIdOverride
        : box.read('storeId');
    final accessToken = box.read('accessToken');
    if (storeId == null || (storeId is String && storeId.isEmpty)) {
      // chờ storeId được lưu sau login
      // ignore: avoid_print
      print('[multi_orders_hook] storeId chưa sẵn sàng, tạm bỏ qua fetch');
      return;
    }
    if (accessToken == null) {
      errorState.value = ApiError(status: false, message: 'Thiếu accessToken');
      return;
    }
    isLoading.value = true;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    final statusesParam = statuses.join(',');
    final payment = includeAllPayments ? 'all' : 'completed';
    final url = Uri.parse(
        '$appBaseUrl/api/orders/store/$storeId?statuses=$statusesParam&payment=$payment&page=${pageState.value}&limit=${limitState.value}');
    try {
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        final list = ordersModelFromJson(json.encode(decoded));
        final total = decoded['total'] is int ? decoded['total'] : 0;
        totalState.value = total;
        if (append) {
          ordersState.value = [...ordersState.value, ...list];
        } else {
          ordersState.value = list;
        }
        errorState.value = null;
        // ignore: avoid_print
        print(
            '[multi_orders_hook] page=${pageState.value} loaded=${list.length} total=$total statuses=$statusesParam');
      } else {
        errorState.value = apiErrorFromJson(resp.body);
        // ignore: avoid_print
        print(
            '[multi_orders_hook][ERROR] code=${resp.statusCode} body=${resp.body.substring(0, resp.body.length > 300 ? 300 : resp.body.length)}');
      }
    } catch (e) {
      errorState.value = apiErrorFromJson(e.toString());
      // ignore: avoid_print
      print('[multi_orders_hook][EXCEPTION] ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void refetch() {
    pageState.value = 1;
    fetch(append: false);
  }

  void loadMore() {
    if (isLoading.value) return;
    final currentTotal = ordersState.value.length;
    if (currentTotal >= totalState.value) return; // no more
    pageState.value = pageState.value + 1;
    fetch(append: true);
  }

  useEffect(() {
    fetch(append: false);
    return null;
  }, [statuses.join(','), includeAllPayments, initialLimit, storeIdOverride]);

  final hasMore = ordersState.value.length < totalState.value;
  return MultiOrdersResult(
    data: ordersState.value,
    isLoading: isLoading.value,
    error: errorState.value,
    page: pageState.value,
    total: totalState.value,
    hasMore: hasMore,
    refetch: refetch,
    loadMore: loadMore,
  );
}
