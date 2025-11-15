import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/api_error.dart';
import 'package:appliances_flutter/models/categories_model.dart';
import 'package:appliances_flutter/models/hook_models/categories_results.dart';
import 'package:http/http.dart' as http;

FetchCategories fetchCategories() {
  final categoriesList = useState<List<Categories>?>(null);
  final isLoading = useState<bool>(false);
  final isError = useState<ApiError?>(null);

  Future<void> fetchData() async {
    isLoading.value = true;

    try {
      final url = Uri.parse('$appBaseUrl/api/category');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        categoriesList.value = categoriesFromJson(response.body);
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

  return FetchCategories(
    data: categoriesList.value,
    isLoading: isLoading.value,
    error: isError.value,
    refetch: refetch,
  );
}
