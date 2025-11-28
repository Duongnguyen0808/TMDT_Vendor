import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/hooks/multi_orders_hook.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/services/vendor_rating_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class VendorRatingCenterPage extends HookWidget {
  const VendorRatingCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deliveredHook = useMultiOrders(
      statuses: const ['Delivered'],
      initialLimit: 40,
      includeAllPayments: true,
    );
    final ratingReload = useState(0);
    final orders = deliveredHook.data ?? <OrdersModel>[];
    final storedStoreId = VendorRatingService.instance.currentStoreId ?? '';
    final storeId =
        storedStoreId.isNotEmpty ? storedStoreId : _inferStoreId(orders);

    void refreshRatings() {
      ratingReload.value = ratingReload.value + 1;
    }

    void refreshAll() {
      deliveredHook.refetch();
      refreshRatings();
    }

    final isBusy = deliveredHook.isLoading && orders.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá đối tác'),
        actions: [
          IconButton(
            tooltip: 'Làm mới danh sách',
            onPressed: refreshAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isBusy
          ? const Center(child: CircularProgressIndicator())
          : deliveredHook.error != null
              ? _VendorRatingErrorView(
                  message: deliveredHook.error!.message.isEmpty
                      ? 'Không thể tải danh sách'
                      : deliveredHook.error!.message,
                  onRetry: deliveredHook.refetch,
                )
              : orders.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () async {
                        refreshAll();
                        await Future.delayed(const Duration(milliseconds: 600));
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _StoreRatingPanel(
                            storeId: storeId,
                            reloadToken: ratingReload.value,
                            onRefresh: refreshRatings,
                          ),
                          const SizedBox(height: 16),
                          _VendorRatingEmptyView(
                            onRefresh: refreshAll,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        refreshAll();
                        await Future.delayed(const Duration(milliseconds: 600));
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _StoreRatingPanel(
                            storeId: storeId,
                            reloadToken: ratingReload.value,
                            onRefresh: refreshRatings,
                          ),
                          const SizedBox(height: 16),
                          ..._buildOrderCards(orders),
                        ],
                      ),
                    ),
    );
  }
}

List<Widget> _buildOrderCards(List<OrdersModel> orders) {
  if (orders.isEmpty) return const [];
  final widgets = <Widget>[];
  for (final order in orders) {
    widgets.add(_VendorRatingCard(order: order));
    widgets.add(const SizedBox(height: 12));
  }
  widgets.removeLast();
  return widgets;
}

String _inferStoreId(List<OrdersModel> orders) {
  for (final order in orders) {
    final candidate = order.storeId.id.trim();
    if (candidate.isNotEmpty) {
      return candidate;
    }
  }
  return '';
}

class _VendorRatingCard extends StatefulWidget {
  const _VendorRatingCard({required this.order});
  final OrdersModel order;

  @override
  State<_VendorRatingCard> createState() => _VendorRatingCardState();
}

class _VendorRatingCardState extends State<_VendorRatingCard> {
  bool driverBusy = false;
  bool driverRated = false;

  @override
  void didUpdateWidget(covariant _VendorRatingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      driverBusy = false;
      driverRated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final driverId = (order.driverId ?? '').trim();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ReusableText(
                    text: 'Đơn #${_shortId(order.id)}',
                    style: appStyle(15, kDark, FontWeight.w700),
                  ),
                ),
                Text(
                  _formatDate(order.updatedAt),
                  style: appStyle(12, kGray, FontWeight.w400),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.deliveryAddress.addressLine1.isEmpty
                  ? 'Chưa có địa chỉ nhận'
                  : order.deliveryAddress.addressLine1,
              style: appStyle(13, kDark, FontWeight.w500),
            ),
            const SizedBox(height: 12),
            _TargetSection(
              title: 'Tài xế',
              subtitle: driverId.isEmpty
                  ? 'Đơn này chưa có tài xế'
                  : 'Mã: ${_shortId(driverId)}',
              hint: driverId.isEmpty
                  ? 'Không thể đánh giá khi chưa có tài xế'
                  : 'Đánh giá thái độ & phối hợp của tài xế',
              actionLabel:
                  driverRated ? 'Cập nhật đánh giá tài xế' : 'Đánh giá tài xế',
              icon: Ionicons.car_outline,
              color: Colors.indigo,
              busy: driverBusy,
              enabled: driverId.isNotEmpty,
              onPressed:
                  driverId.isEmpty ? null : () => _handleDriverRating(driverId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDriverRating(String driverId) async {
    setState(() {
      driverBusy = true;
    });
    try {
      final check = await VendorRatingService.instance
          .checkRating(ratingType: 'Driver', productId: driverId);
      if (check.hasRating) {
        setState(() {
          driverRated = true;
        });
      }
      final sheetResult = await _showRatingSheet(
        context,
        title: 'Đánh giá tài xế',
        helper: check.message.isNotEmpty
            ? check.message
            : 'Vui lòng chọn số sao và ghi nhận xét (nếu cần).',
        existing: check.hasRating,
        initialRating: (check.rating ?? 5).clamp(1, 5),
        initialComment: check.comment ?? '',
      );
      if (sheetResult == null) return;
      final submit = await VendorRatingService.instance.submitRating(
        ratingType: 'Driver',
        productId: driverId,
        rating: sheetResult.rating,
        comment: sheetResult.comment,
      );
      if (submit.success) {
        setState(() {
          driverRated = true;
        });
      }
      Get.snackbar(
        submit.success ? 'Thành công' : 'Không thành công',
        submit.message,
        backgroundColor: submit.success ? kPrimary : kRed,
        colorText: kLightWhite,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString(),
        backgroundColor: kRed,
        colorText: kLightWhite,
      );
    } finally {
      setState(() {
        driverBusy = false;
      });
    }
  }
}

class _TargetSection extends StatelessWidget {
  const _TargetSection({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.actionLabel,
    required this.icon,
    required this.color,
    required this.busy,
    required this.enabled,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String hint;
  final String actionLabel;
  final IconData icon;
  final Color color;
  final bool busy;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: appStyle(14, color, FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: appStyle(13, kDark, FontWeight.w600)),
        const SizedBox(height: 4),
        Text(hint, style: appStyle(12, kGray, FontWeight.w400)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: !enabled || busy ? null : onPressed,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.star_rate_rounded),
            label: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}

class _StoreRatingPanel extends HookWidget {
  const _StoreRatingPanel({
    required this.storeId,
    required this.reloadToken,
    required this.onRefresh,
  });

  final String storeId;
  final int reloadToken;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (storeId.isEmpty) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Không tìm thấy cửa hàng',
                  style: appStyle(15, kDark, FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Vui lòng đăng nhập lại hoặc chọn cửa hàng trước khi xem đánh giá.',
                style: appStyle(13, kGray, FontWeight.w400),
              ),
            ],
          ),
        ),
      );
    }

    final future = useMemoized(
      () => VendorRatingService.instance.fetchStoreRatings(storeId: storeId),
      [storeId, reloadToken],
    );
    final snapshot = useFuture(future);

    if (snapshot.connectionState == ConnectionState.waiting &&
        snapshot.data == null) {
      return const _StoreRatingContainer(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError) {
      return _StoreRatingContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Không tải được đánh giá',
                style: appStyle(15, kDark, FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              snapshot.error.toString(),
              style: appStyle(13, kGray, FontWeight.w400),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return const _StoreRatingContainer(
        child: Text('Chưa có dữ liệu đánh giá'),
      );
    }

    final summary = data.summary;
    final entries = data.entries;
    return _StoreRatingContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Đánh giá từ khách hàng',
                    style: appStyle(16, kDark, FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'Làm mới đánh giá',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: appStyle(34, kDark, FontWeight.w800),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStars(summary.average),
                  const SizedBox(height: 4),
                  Text('${summary.total} lượt đánh giá',
                      style: appStyle(13, kGray, FontWeight.w400)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var star = 5; star >= 1; star--)
                _RatingBreakdownChip(
                  star: star,
                  count: summary.breakdown[star] ?? 0,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text('Chưa có đánh giá nào',
                style: appStyle(13, kGray, FontWeight.w500))
          else ...[
            for (final entry in entries.take(3))
              _VendorRatingTile(entry: entry),
            if (entries.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Chỉ hiển thị 3 đánh giá gần nhất',
                  style: appStyle(12, kGray, FontWeight.w400),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StoreRatingContainer extends StatelessWidget {
  const _StoreRatingContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _RatingBreakdownChip extends StatelessWidget {
  const _RatingBreakdownChip({required this.star, required this.count});
  final int star;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(Icons.star, color: Colors.amber.shade700, size: 18),
      label: Text('$star sao · $count'),
    );
  }
}

class _VendorRatingTile extends StatelessWidget {
  const _VendorRatingTile({required this.entry});
  final VendorRatingEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateText = _formatRatingDate(entry.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.author,
                  style: appStyle(14, kDark, FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(dateText, style: appStyle(11, kGray, FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 4),
          _buildStars(entry.rating),
          if (entry.relatedProductTitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Sản phẩm: ${entry.relatedProductTitle}',
              style: appStyle(12, kGray, FontWeight.w500),
            ),
          ],
          if (entry.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(entry.comment, style: appStyle(13, kDark, FontWeight.w400)),
          ],
        ],
      ),
    );
  }
}

Row _buildStars(double rating) {
  return Row(
    children: List.generate(5, (index) {
      final starIndex = index + 1;
      IconData icon;
      if (rating >= starIndex) {
        icon = Icons.star;
      } else if (rating + 0.5 >= starIndex) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      return Icon(icon, color: Colors.amber, size: 18);
    }),
  );
}

String _formatRatingDate(DateTime date) {
  final formatter = DateFormat('dd/MM/yyyy HH:mm');
  return formatter.format(date.toLocal());
}

class _VendorRatingEmptyView extends StatelessWidget {
  const _VendorRatingEmptyView({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.star_outline, size: 72, color: kGrayLight),
            const SizedBox(height: 16),
            Text('Chưa có đơn giao xong để đánh giá',
                textAlign: TextAlign.center,
                style: appStyle(15, kDark, FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Khi đơn hàng hoàn tất, bạn có thể đánh giá tài xế tại đây.',
              textAlign: TextAlign.center,
              style: appStyle(13, kGray, FontWeight.w400),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorRatingErrorView extends StatelessWidget {
  const _VendorRatingErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: kRed),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: appStyle(14, kDark, FontWeight.w500)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            )
          ],
        ),
      ),
    );
  }
}

Future<_RatingSheetResult?> _showRatingSheet(
  BuildContext context, {
  required String title,
  required String helper,
  required bool existing,
  required double initialRating,
  required String initialComment,
}) async {
  final commentCtrl = TextEditingController(text: initialComment);
  double currentRating = initialRating.clamp(1, 5);
  final result = await showModalBottomSheet<_RatingSheetResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: appStyle(16, kDark, FontWeight.w700)),
                const SizedBox(height: 6),
                Text(helper, style: appStyle(12, kGray, FontWeight.w400)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    final filled = index < currentRating.round();
                    return IconButton(
                      icon: Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed: () {
                        setModalState(() {
                          currentRating = (index + 1).toDouble();
                        });
                      },
                    );
                  }),
                ),
                Slider(
                  value: currentRating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: currentRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setModalState(() {
                      currentRating = value;
                    });
                  },
                ),
                TextField(
                  controller: commentCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét (không bắt buộc)',
                    hintText: 'Chia sẻ trải nghiệm của bạn...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_RatingSheetResult(
                        rating: currentRating.roundToDouble(),
                        comment: commentCtrl.text.trim(),
                      ));
                    },
                    child:
                        Text(existing ? 'Cập nhật đánh giá' : 'Gửi đánh giá'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
  commentCtrl.dispose();
  return result;
}

class _RatingSheetResult {
  final double rating;
  final String comment;
  const _RatingSheetResult({required this.rating, required this.comment});
}

String _shortId(String id) {
  if (id.length <= 6) return id.toUpperCase();
  return id.substring(0, 6).toUpperCase();
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
}

String _formatPhone(String phone) {
  if (phone.isEmpty) return '';
  return '\nSĐT: $phone';
}
