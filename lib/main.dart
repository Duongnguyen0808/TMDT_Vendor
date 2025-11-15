import 'package:appliances_flutter/firebase_options.dart';
import 'package:appliances_flutter/views/auth/login_page.dart';
import 'package:appliances_flutter/views/auth/verification_page.dart';
import 'package:appliances_flutter/views/auth/waiting_page.dart';
import 'package:appliances_flutter/views/home/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vietmap_flutter_plugin/vietmap_flutter_plugin.dart';
import 'package:appliances_flutter/constants/constants.dart';

Widget defaultHome = const Login();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GetStorage.init();
  const envKey = String.fromEnvironment('VIETMAP_API_KEY', defaultValue: '');
  final key = envKey.isNotEmpty ? envKey : vietmapApiKey;
  if (key.isNotEmpty) {
    Vietmap.getInstance(key);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    String? accessToken = box.read('accessToken');
    String? storeId = box.read('storeId');
    String? verification = box.read('verification');
    bool everification = box.read('e-verification') ?? false;

    if (accessToken == null) {
      defaultHome = const Login();
    } else if (everification == false) {
      defaultHome = const VerificationPage();
    } else if (storeId != null && verification == "Đã xác minh") {
      defaultHome = const HomePage();
    } else if (storeId != null && verification != null) {
      defaultHome = const WaitingPage();
    }

    return ScreenUtilInit(
        useInheritedMediaQuery: true,
        designSize: const Size(428, 926),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return GetMaterialApp(
            title: 'Flutter Demo',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: defaultHome,
          );
        });
  }
}
