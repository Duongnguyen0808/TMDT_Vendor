import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/api_error.dart';
import 'package:appliances_flutter/models/appliancess_model.dart';
import 'package:appliances_flutter/models/hook_models/applianceslist_results.dart';

FetchAppliancess fetchappliancesList() {
  final box = GetStorage();
  final applianceslist = useState<List<AppliancessModel>?>(null);
  final isLoading = useState<bool>(false);
  final isError = useState<ApiError?>(null);

  Future<void> fetchData() async {
    String id = box.read("storeId");
    isLoading.value = true;

    try {
      final url = Uri.parse('$appBaseUrl/api/appliances/store-appliances/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        applianceslist.value = appliancessModelFromJson(response.body);
        isLoading.value = false;
        isError.value = null;
      } else {
        isLoading.value = false;
        isError.value = apiErrorFromJson(response.body);
      }
    } catch (e) {
      isLoading.value = false;
      isError.value = ApiError(status: false, message: e.toString());
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

  return FetchAppliancess(
    data: applianceslist.value,
    isLoading: isLoading.value,
    error: isError.value,
    refetch: refetch,
  );
}
