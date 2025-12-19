import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/vendor_driver_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DriversListPage extends StatefulWidget {
  const DriversListPage({super.key});

  @override
  State<DriversListPage> createState() => _DriversListPageState();
}

class _DriversListPageState extends State<DriversListPage> {
  final ctrl = Get.put(VendorDriverController());

  @override
  void initState() {
    super.initState();
    ctrl.fetchDrivers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kOffWhite,
        title: Text('Tài xế', style: appStyle(16, kDark, FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kDark),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ctrl.fetchDrivers(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDriverDialog(context),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: kLightWhite),
      ),
      body: Obx(() {
        if (ctrl.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.drivers.isEmpty) {
          return Center(
            child: ReusableText(
              text: 'Chưa có tài xế',
              style: appStyle(14, kGray, FontWeight.w400),
            ),
          );
        }
        return ListView.separated(
          itemCount: ctrl.drivers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final d = ctrl.drivers[i];
            final user = d['user'] ?? {};
            final name = user['username'] ?? 'Tài xế';
            final phone = user['phone'] ?? '';
            final status = d['status'] ?? 'offline';
            final vehicle =
                (d['vehicleType'] ?? '') + ' ' + (d['vehiclePlate'] ?? '');
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(name),
              subtitle:
                  Text([phone, vehicle].where((e) => e.isNotEmpty).join(' • ')),
              trailing: Text(status.toString()),
              onTap: () async {
                // toggle status quick demo
                final next = status == 'available' ? 'offline' : 'available';
                await ctrl.updateDriver(d['_id'].toString(), {'status': next});
              },
            );
          },
        );
      }),
    );
  }

  void _showCreateDriverDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    String vehicleType = 'motorbike';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Thêm tài xế'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên')),
                TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email')),
                TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'SĐT')),
                TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true),
                DropdownButtonFormField<String>(
                  value: vehicleType,
                  items: const [
                    DropdownMenuItem(value: 'motorbike', child: Text('Xe máy')),
                    DropdownMenuItem(value: 'car', child: Text('Ô tô')),
                  ],
                  onChanged: (v) => vehicleType = v ?? 'motorbike',
                  decoration: const InputDecoration(labelText: 'Loại xe'),
                ),
                TextField(
                    controller: plateCtrl,
                    decoration: const InputDecoration(labelText: 'Biển số')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final ok = await ctrl.createDriver(
                  username: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  vehicleType: vehicleType,
                  vehiclePlate: plateCtrl.text.trim(),
                );
                if (ok) Get.back();
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }
}
