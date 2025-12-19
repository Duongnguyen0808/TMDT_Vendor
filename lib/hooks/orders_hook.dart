import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/api_error.dart';
import 'package:appliances_flutter/models/hook_models/orders_results.dart';
import 'package:appliances_flutter/models/orders_model.dart';

FetchOrders fetchOrders(String status) {
  final box = GetStorage();
  final applianceslist = useState<List<OrdersModel>?>(null);
  final isLoading = useState<bool>(false);
  final isError = useState<ApiError?>(null);

  Future<void> fetchData() async {
    String id = box.read("storeId");
    String accessToken = box.read('accessToken');
    isLoading.value = true;

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    try {
      // BE route: /api/orders/store/:id/:status?all=1 để thấy cả Pending
      final url = Uri.parse('$appBaseUrl/api/orders/store/$id/$status?all=1');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Response mới dạng { status, count, data: [...] }
        applianceslist.value = ordersModelFromJson(response.body);
        // Debug
        // ignore: avoid_print
        print(
            '[orders_hook] Loaded ${applianceslist.value?.length ?? 0} orders for status=$status');
        isLoading.value = false;
        isError.value = null;
      } else {
        isLoading.value = false;
        // ignore: avoid_print
        print(
            '[orders_hook][ERROR] code=${response.statusCode} body=${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
        isError.value = apiErrorFromJson(response.body);
      }
    } catch (e) {
      isLoading.value = false;
      // e.toString() có thể không phải JSON, apiErrorFromJson đã được harden
      isError.value = apiErrorFromJson(e.toString());
      // ignore: avoid_print
      print('[orders_hook][EXCEPTION] ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  useEffect(() {
    fetchData();
    return null;
  }, []);

  void refetch() {
    isLoading.value = true;
    fetchData();
  }

  return FetchOrders(
    data: applianceslist.value,
    isLoading: isLoading.value,
    error: isError.value,
    refetch: refetch,
  );
}
