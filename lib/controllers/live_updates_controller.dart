import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/vendor_driver_controller.dart';
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LiveUpdatesController extends GetxController {
  final box = GetStorage();
  IO.Socket? socket;

  String? get token => box.read('token');

  @override
  void onInit() {
    super.onInit();
    _connect();
  }

  void _connect() {
    if (socket != null) return;
    socket = IO.io(
      appBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket!.on('connect', (_) {});

    // Order changes
    socket!.on('order:updated', (data) async {
      final oc = Get.isRegistered<VendorOrderController>()
          ? Get.find<VendorOrderController>()
          : null;
      if (oc != null) {
        await oc.fetchAllOrders();
      }
    });

    socket!.on('order:assigned', (data) async {
      final oc = Get.isRegistered<VendorOrderController>()
          ? Get.find<VendorOrderController>()
          : null;
      if (oc != null) {
        await oc.fetchAllOrders();
      }
    });

    socket!.on('order:unassigned', (data) async {
      final oc = Get.isRegistered<VendorOrderController>()
          ? Get.find<VendorOrderController>()
          : null;
      if (oc != null) {
        await oc.fetchAllOrders();
      }
    });

    // Driver status updates
    socket!.on('driver:status', (data) async {
      final dc = Get.isRegistered<VendorDriverController>()
          ? Get.find<VendorDriverController>()
          : null;
      if (dc != null) {
        await dc.fetchDrivers();
      }
    });
  }
}
