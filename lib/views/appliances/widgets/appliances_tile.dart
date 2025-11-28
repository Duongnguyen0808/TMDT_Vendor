import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/appliancess_model.dart';
import 'package:appliances_flutter/services/vendor_rating_service.dart';
import 'package:appliances_flutter/views/appliances/edit_appliances.dart';
import 'package:appliances_flutter/controllers/appliances_controller.dart';

class AppliancesTile extends StatefulWidget {
  AppliancesTile({
    super.key,
    required this.appliances,
    this.onUpdate,
    this.onDelete,
  });

  final AppliancessModel appliances;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;

  @override
  State<AppliancesTile> createState() => _AppliancesTileState();
}

class _AppliancesTileState extends State<AppliancesTile> {
  late bool isAvailable;
  bool _ratingsOpen = false;

  @override
  void initState() {
    super.initState();
    isAvailable = widget.appliances.isAvailable;
  }

  Future<void> _showProductRatings() async {
    if (_ratingsOpen) return;
    setState(() => _ratingsOpen = true);
    try {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _ProductRatingsSheet(
          productId: widget.appliances.id,
          productName: widget.appliances.title,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _ratingsOpen = false);
      }
    }
  }

  Future<void> _toggleAvailability() async {
    final controller = Get.put(AppliancesController());

    setState(() {
      isAvailable = !isAvailable;
    });

    Map<String, dynamic> updateData = {'isAvailable': isAvailable};
    String data = jsonEncode(updateData);

    bool success = await controller.updateAppliancesFunction(
      widget.appliances.id,
      data,
    );

    if (!success) {
      // Revert if failed
      setState(() {
        isAvailable = !isAvailable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.appliances.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: kRed,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: kLightWhite, size: 32.sp),
            SizedBox(height: 4.h),
            ReusableText(
              text: "Xóa",
              style: appStyle(12, kLightWhite, FontWeight.bold),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Xác nhận xóa',
                style: appStyle(16, kDark, FontWeight.bold)),
            content: Text(
              'Bạn có chắc muốn xóa "${widget.appliances.title}"?',
              style: appStyle(14, kGray, FontWeight.normal),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Hủy', style: appStyle(14, kGray, FontWeight.w500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  foregroundColor: kLightWhite,
                ),
                onPressed: () async {
                  Navigator.pop(context, false); // Đóng dialog trước

                  final controller = Get.put(AppliancesController());
                  bool success = await controller
                      .deleteAppliancesFunction(widget.appliances.id);

                  if (success && widget.onDelete != null) {
                    widget.onDelete!(); // Refresh danh sách
                  }
                },
                child: Text('Xóa',
                    style: appStyle(14, kLightWhite, FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      child: GestureDetector(
        onTap: () async {
          final result = await Get.to(
            () => EditAppliances(appliances: widget.appliances),
            transition: Transition.rightToLeft,
            duration: Duration(milliseconds: 300),
          );

          // Nếu có callback và update thành công
          if (result == true && widget.onUpdate != null) {
            widget.onUpdate!();
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Container(
            height: 100.h,
            decoration: BoxDecoration(
              color: isAvailable ? kOffWhite : kGrayLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: kGray.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: kGray.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  isAvailable
                                      ? Colors.transparent
                                      : Colors.grey,
                                  isAvailable
                                      ? BlendMode.dst
                                      : BlendMode.saturation,
                                ),
                                child: Image.network(
                                  widget.appliances.imageUrl[0],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: kGrayLight,
                                      child: Icon(Icons.image_not_supported,
                                          size: 30.w, color: kGray),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (!isAvailable)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.visibility_off,
                                    color: kLightWhite,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ReusableText(
                              text: widget.appliances.title,
                              style: appStyle(
                                13,
                                isAvailable ? kDark : kGray,
                                FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 12.sp, color: kGray),
                                SizedBox(width: 4.w),
                                ReusableText(
                                  text: widget.appliances.time,
                                  style: appStyle(10, kGray, FontWeight.w400),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.inventory_2,
                                    size: 12.sp,
                                    color: widget.appliances.stock > 0
                                        ? kGray
                                        : kRed),
                                SizedBox(width: 4.w),
                                ReusableText(
                                  text:
                                      "Tồn: ${widget.appliances.stock.toString()}",
                                  style: appStyle(
                                      10,
                                      widget.appliances.stock > 0
                                          ? kGray
                                          : kRed,
                                      FontWeight.w500),
                                ),
                              ],
                            ),
                            _ProductRatingSnippet(
                              rating: widget.appliances.rating,
                              ratingCount: widget.appliances.ratingCount,
                              onViewAll: _showProductRatings,
                            ),
                            if (widget.appliances.additives.isNotEmpty)
                              SizedBox(
                                height: 22.h,
                                child: ListView.builder(
                                  itemCount:
                                      widget.appliances.additives.length > 3
                                          ? 3
                                          : widget.appliances.additives.length,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, i) {
                                    String title =
                                        widget.appliances.additives[i].title;
                                    return Container(
                                      margin: EdgeInsets.only(right: 6.w),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: kSecondaryLight,
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                        border: Border.all(
                                            color: kGray.withOpacity(0.3),
                                            width: 0.5),
                                      ),
                                      child: Center(
                                        child: ReusableText(
                                          text: title,
                                          style: appStyle(
                                              9, kDark, FontWeight.w500),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 70.w), // Space for price badge
                  ],
                ),
                Positioned(
                  right: 10.w,
                  top: 10.h,
                  child: Column(
                    children: [
                      Container(
                        height: 28.h,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimary, kPrimary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: ReusableText(
                            text:
                                "${widget.appliances.price.toStringAsFixed(0)}đ",
                            style: appStyle(13, kLightWhite, FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextButton(
                        onPressed: _showProductRatings,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          minimumSize: Size(64.w, 28.h),
                          backgroundColor: kPrimary.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.reviews_outlined,
                                size: 14.sp, color: kPrimary),
                            SizedBox(width: 4.w),
                            Text('Đánh giá',
                                style: appStyle(11, kPrimary, FontWeight.w600)),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Toggle availability switch
                      Container(
                        height: 24.h,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: isAvailable ? kPrimary : kGray,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _toggleAvailability,
                              child: Icon(
                                isAvailable
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: kLightWhite,
                                size: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductRatingSnippet extends StatelessWidget {
  const _ProductRatingSnippet({
    required this.rating,
    required this.ratingCount,
    required this.onViewAll,
  });

  final double rating;
  final String ratingCount;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final parsedCount = int.tryParse(ratingCount) ?? 0;
    final displayCount = parsedCount.clamp(0, 9999).toInt();
    final showStats = rating > 0 || parsedCount > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showStats) ...[
          Row(
            children: [
              const Icon(Icons.star_rate_rounded,
                  color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: appStyle(12, kDark, FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Text(
                '($displayCount đánh giá)',
                style: appStyle(11, kGray, FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ] else ...[
          Text('Chưa có đánh giá', style: appStyle(11, kGray, FontWeight.w400)),
          const SizedBox(height: 4),
        ],
        TextButton.icon(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onViewAll,
          icon: const Icon(Icons.reviews_outlined, size: 16),
          label: const Text('Xem đánh giá'),
        ),
      ],
    );
  }
}

class _ProductRatingsSheet extends StatefulWidget {
  const _ProductRatingsSheet({
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;

  @override
  State<_ProductRatingsSheet> createState() => _ProductRatingsSheetState();
}

class _ProductRatingsSheetState extends State<_ProductRatingsSheet> {
  late Future<VendorRatingFeed> _future;

  @override
  void initState() {
    super.initState();
    _future = VendorRatingService.instance
        .fetchProductRatings(productId: widget.productId, limit: 24);
  }

  void _reload() {
    setState(() {
      _future = VendorRatingService.instance
          .fetchProductRatings(productId: widget.productId, limit: 24);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
        child: FutureBuilder<VendorRatingFeed>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return SizedBox(
                height: 240,
                child: Column(
                  children: const [
                    _SheetHandle(),
                    Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetHandle(),
                  Text('Không thể tải đánh giá',
                      style: appStyle(16, kDark, FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(),
                      style: appStyle(13, kGray, FontWeight.w400)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final feed = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetHandle(),
                  Text('Đánh giá cho ${widget.productName}',
                      style: appStyle(16, kDark, FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        feed.summary.average.toStringAsFixed(1),
                        style: appStyle(34, kDark, FontWeight.w800),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRatingStars(feed.summary.average, size: 18),
                          const SizedBox(height: 4),
                          Text('${feed.summary.total} lượt đánh giá',
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
                        _ProductRatingBreakdownChip(
                          star: star,
                          count: feed.summary.breakdown[star] ?? 0,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (feed.entries.isEmpty)
                    Text('Chưa có nhận xét nào',
                        style: appStyle(13, kGray, FontWeight.w500))
                  else ...[
                    for (final entry in feed.entries)
                      _ProductRatingTile(entry: entry),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductRatingTile extends StatelessWidget {
  const _ProductRatingTile({required this.entry});
  final VendorRatingEntry entry;

  @override
  Widget build(BuildContext context) {
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
              Text(
                _formatRatingDate(entry.createdAt),
                style: appStyle(11, kGray, FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildRatingStars(entry.rating, size: 16),
          if (entry.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(entry.comment, style: appStyle(13, kDark, FontWeight.w400)),
          ],
        ],
      ),
    );
  }
}

class _ProductRatingBreakdownChip extends StatelessWidget {
  const _ProductRatingBreakdownChip({required this.star, required this.count});
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kGrayLight,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

Row _buildRatingStars(double rating, {double size = 18}) {
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
      return Icon(icon, color: Colors.amber, size: size);
    }),
  );
}

String _formatRatingDate(DateTime date) {
  final formatter = DateFormat('dd/MM/yyyy HH:mm');
  return formatter.format(date.toLocal());
}
