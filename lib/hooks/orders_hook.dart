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
      final url = Uri.parse('$appBaseUrl/api/orders/rest-orders/$id/$status');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        applianceslist.value = ordersModelFromJson(response.body);
        isLoading.value = false;
        isError.value = null;
      } else {
        isLoading.value = false;
        isError.value = apiErrorFromJson(response.body);
      }
    } catch (e) {
      isLoading.value = false;
      isError.value = apiErrorFromJson(e.toString());
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
