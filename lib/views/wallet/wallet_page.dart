import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/background_container.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/vendor_wallet_controller.dart';
import 'package:appliances_flutter/models/vendor_wallet_model.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final VendorWalletController controller;
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    controller = Get.put(VendorWalletController());
    controller.fetchWallet();
  }

  @override
  Widget build(BuildContext context) {
    final storeFallback = GetStorage().read('storeName') ?? 'Cửa hàng';
    return Scaffold(
      backgroundColor: kSecondary,
      appBar: AppBar(
        backgroundColor: kSecondary,
        title: ReusableText(
          text: 'Ví của tôi',
          style: appStyle(18, kLightWhite, FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchWallet(),
          ),
        ],
      ),
      body: BackGroundContainer(
        child: Obx(
          () {
            final summary = controller.summary.value;
            final storeName = summary?.storeTitle ?? storeFallback;
            return Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBalanceCard(storeName, summary),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.add_circle_outline,
                        label: 'Nạp tiền',
                        enabled: !controller.processing.value,
                        onTap: () => _handleAction(true),
                      ),
                      _buildActionButton(
                        icon: Icons.remove_circle_outline,
                        label: 'Rút tiền',
                        enabled: !controller.processing.value,
                        onTap: () => _handleAction(false),
                      ),
                      _buildActionButton(
                        icon: Icons.history,
                        label: 'Lịch sử',
                        onTap: () => _openHistorySheet(
                          summary?.transactions ??
                              const <VendorWalletTransaction>[],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ReusableText(
                      text: 'Lịch sử giao dịch',
                      style: appStyle(16, kDark, FontWeight.w600),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (controller.summaryError.value != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Text(
                        controller.summaryError.value!,
                        style: appStyle(12, kRed, FontWeight.w500),
                      ),
                    ),
                  Expanded(child: _buildHistoryList(summary)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String storeName, VendorWalletSummary? summary) {
    final balanceText = summary?.formattedBalance ?? _currency.format(0);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ReusableText(
                text: 'Số dư khả dụng',
                style: appStyle(14, kLightWhite, FontWeight.normal),
              ),
              if (controller.processing.value)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          ReusableText(
            text: balanceText,
            style: appStyle(32, kLightWhite, FontWeight.bold),
          ),
          SizedBox(height: 10.h),
          ReusableText(
            text: storeName,
            style:
                appStyle(12, kLightWhite.withOpacity(0.85), FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(VendorWalletSummary? summary) {
    final transactions =
        summary?.transactions ?? const <VendorWalletTransaction>[];
    if (controller.loading.value && transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: controller.fetchWallet,
      child: transactions.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 80.h),
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80.sp,
                  color: kGrayLight,
                ),
                SizedBox(height: 16.h),
                Center(
                  child: ReusableText(
                    text: 'Chưa có giao dịch nào',
                    style: appStyle(14, kGray, FontWeight.normal),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (_, index) => _transactionTile(transactions[index]),
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemCount: transactions.length,
            ),
    );
  }

  Widget _transactionTile(VendorWalletTransaction tx) {
    final isCredit = tx.isCredit;
    final color = isCredit ? Colors.green : Colors.red;
    final prefix = isCredit ? '+' : '-';
    final amountText = '$prefix${tx.formattedAmount}';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: kGrayLight.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.15),
            child: Icon(isCredit ? Icons.trending_up : Icons.trending_down,
                color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty
                      ? tx.description
                      : _labelForType(tx.type),
                  style: appStyle(13, kDark, FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Text(
                  tx.formattedDate(),
                  style: appStyle(11, kGray, FontWeight.w400),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: appStyle(14, color, FontWeight.w700),
              ),
              SizedBox(height: 2.h),
              Text(
                'Còn lại: ${_currency.format(tx.balanceAfter)}',
                style: appStyle(11, kGray, FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: kOffWhite,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: kGrayLight.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: kPrimary, size: 28.sp),
              SizedBox(height: 8.h),
              ReusableText(
                text: label,
                style: appStyle(11, kDark, FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(bool isDeposit) async {
    final amount = await _promptAmount(
      title: isDeposit ? 'Nhập số tiền muốn nạp' : 'Nhập số tiền muốn rút',
      confirmLabel: isDeposit ? 'Xác nhận nạp' : 'Xác nhận rút',
    );
    if (amount == null) return;

    final success = isDeposit
        ? await controller.deposit(amount)
        : await controller.withdraw(amount);
    if (success) {
      final color = isDeposit ? Colors.green : Colors.orange;
      Get.snackbar(
        'Thành công',
        '${isDeposit ? 'Đã nạp' : 'Đã rút'} ${_currency.format(amount)}',
        backgroundColor: color,
        colorText: kLightWhite,
      );
    } else {
      final msg =
          controller.actionError.value ?? 'Không thể thực hiện thao tác';
      Get.snackbar('Lỗi', msg, backgroundColor: kRed, colorText: kLightWhite);
    }
  }

  Future<int?> _promptAmount({
    required String title,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController(text: '200000');
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Ví dụ: 200000'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () {
                final raw = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
                final value = int.tryParse(raw);
                if (value == null || value <= 0) {
                  Get.snackbar(
                    'Thiếu dữ liệu',
                    'Vui lòng nhập số tiền hợp lệ',
                    backgroundColor: kRed,
                    colorText: kLightWhite,
                  );
                  return;
                }
                Navigator.of(ctx).pop(value);
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return amount;
  }

  void _openHistorySheet(List<VendorWalletTransaction> transactions) {
    if (transactions.isEmpty) {
      Get.snackbar('Thông báo', 'Chưa có giao dịch nào',
          backgroundColor: kPrimary, colorText: kLightWhite);
      return;
    }
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Lịch sử giao dịch',
                style: appStyle(16, kDark, FontWeight.w700)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (_, index) =>
                    _transactionTile(transactions[index]),
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemCount: transactions.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForType(String type) {
    switch (type) {
      case 'deposit':
        return 'Nạp ví';
      case 'withdraw':
        return 'Rút ví';
      case 'payout':
        return 'Thanh toán đơn hàng';
      case 'adjustment':
        return 'Điều chỉnh';
      default:
        return type;
    }
  }
}
