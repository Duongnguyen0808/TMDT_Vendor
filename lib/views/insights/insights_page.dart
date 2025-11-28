import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/insights_controller.dart';
import 'package:appliances_flutter/models/insights_models.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InsightsController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích & gợi ý'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshAll,
          ),
        ],
      ),
      body: Obx(() {
        final analytics = controller.analytics.value;
        final recs = controller.recommendations.value;
        if (controller.analyticsLoading.value && analytics == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty && analytics == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: appStyle(14, kDark, FontWeight.w500),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (analytics != null) ...[
                _SummarySection(analytics: analytics),
                const SizedBox(height: 16),
                _StatusSection(statuses: analytics.statuses),
                if (analytics.sources.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _OrderSourceSection(sources: analytics.sources),
                ],
                const SizedBox(height: 16),
                _TimelineSection(points: analytics.timeline),
                const SizedBox(height: 16),
                _TopProductsSection(products: analytics.topProducts),
                const SizedBox(height: 16),
                _CustomerSection(customers: analytics.customers),
              ],
              const SizedBox(height: 24),
              if (recs != null)
                _RecommendationSection(recommendations: recs)
              else if (controller.recommendationsLoading.value)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      }),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.analytics});
  final VendorAnalyticsOverview analytics;

  @override
  Widget build(BuildContext context) {
    final cards = <_MetricCardData>[
      _MetricCardData(
        label: 'Đơn hoàn tất',
        value: analytics.totals.delivered.toString(),
        icon: Icons.verified,
        color: Colors.green.shade600,
      ),
      _MetricCardData(
        label: 'Doanh thu đã thu',
        value: '${formatVND(analytics.totals.revenueDelivered)} đ',
        icon: Icons.payments,
        color: kPrimary,
      ),
      _MetricCardData(
        label: 'Giá trị đơn TB',
        value: '${formatVND(analytics.totals.avgOrderValue)} đ',
        icon: Icons.attach_money,
        color: Colors.blueGrey,
      ),
      _MetricCardData(
        label: 'Tỷ lệ hoàn trả',
        value: '${(analytics.totals.returnRate * 100).toStringAsFixed(1)} %',
        icon: Icons.assignment_return,
        color: Colors.deepOrange,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng quan ${analytics.rangeDays} ngày',
                style: appStyle(15, kDark, FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map((data) => _MetricCard(
                        data: data,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final targetWidth =
        mediaWidth > 520 ? (mediaWidth - 64) / 2 : mediaWidth - 64;
    return SizedBox(
      width: targetWidth.clamp(180, mediaWidth).toDouble(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: data.color.withOpacity(.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: data.color),
            const SizedBox(height: 8),
            Text(
              data.value,
              style: appStyle(18, data.color, FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(data.label, style: appStyle(12, kDark, FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.statuses});
  final Map<String, int> statuses;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return const SizedBox.shrink();
    }
    final entries = statuses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trạng thái đơn', style: appStyle(15, kDark, FontWeight.w600)),
            const SizedBox(height: 12),
            ...entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(_localizeStatus(entry.key))),
                      Text('${entry.value} đơn'),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _OrderSourceSection extends StatelessWidget {
  const _OrderSourceSection({required this.sources});
  final Map<String, int> sources;

  @override
  Widget build(BuildContext context) {
    final total = sources.values.fold<int>(0, (sum, value) => sum + value);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nguồn đơn hàng', style: appStyle(15, kDark, FontWeight.w600)),
            const SizedBox(height: 12),
            if (sources.isEmpty)
              const Text('Chưa có dữ liệu nguồn đơn hàng')
            else
              ...sources.entries.map((entry) {
                final percent = total == 0
                    ? 0.0
                    : (entry.value / total).clamp(0, 1).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_localizeSource(entry.key)),
                          Text('${entry.value} đơn'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        backgroundColor: kGrayLight.withOpacity(.4),
                        color: kPrimary,
                      ),
                    ],
                  ),
                );
              }),
            if (total > 0)
              Text(
                'Tổng: $total đơn (${sources.length} nguồn)',
                style: appStyle(12, kGray, FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}

String _localizeStatus(String status) {
  final key = status.toLowerCase();
  switch (key) {
    case 'pending':
    case 'created':
      return 'Chờ xử lý';
    case 'processing':
    case 'accepted':
      return 'Đang chuẩn bị';
    case 'ready':
    case 'pickup_ready':
      return 'Sẵn sàng giao';
    case 'delivering':
    case 'assigned':
      return 'Đang giao';
    case 'delivered':
      return 'Đã giao';
    case 'cancelled':
    case 'canceled':
      return 'Đã huỷ';
    case 'returned':
      return 'Hoàn hàng';
    default:
      return status;
  }
}

String _localizeSource(String source) {
  final key = source.toLowerCase();
  switch (key) {
    case 'app':
    case 'mobile':
      return 'App khách hàng';
    case 'web':
      return 'Website';
    case 'callcenter':
    case 'call_center':
      return 'Tổng đài hỗ trợ';
    case 'pos':
    case 'walkin':
      return 'Bán tại quầy';
    case 'partner':
      return 'Đối tác bên ngoài';
    default:
      return source.isEmpty ? 'Khác' : source;
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.points});
  final List<AnalyticsPoint> points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xu hướng theo ngày',
                style: appStyle(15, kDark, FontWeight.w600)),
            const SizedBox(height: 12),
            if (points.isEmpty)
              const Text('Chưa có dữ liệu trong khoảng thời gian này')
            else
              Column(
                children: points
                    .take(14)
                    .map((point) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(point.date),
                          subtitle: Text(
                              'Đơn: ${point.orders} • Doanh thu: ${formatVND(point.revenue)} đ'),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsSection extends StatelessWidget {
  const _TopProductsSection({required this.products});
  final List<TopProductInsight> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sản phẩm nổi bật',
                style: appStyle(15, kDark, FontWeight.w600)),
            const SizedBox(height: 12),
            ...products.map((product) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _ProductImage(url: product.image),
                  title: Text(product.title,
                      style: appStyle(13, kDark, FontWeight.w600)),
                  subtitle: Text(
                      'Đã bán: ${product.sold} • Doanh thu: ${formatVND(product.revenue)} đ'),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${formatVND(product.price)} đ',
                          style: appStyle(12, kDark, FontWeight.w600)),
                      Text('Kho: ${product.stock}',
                          style: appStyle(11, kGray, FontWeight.w500)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url.isEmpty
          ? Container(
              width: 48,
              height: 48,
              color: kGrayLight.withOpacity(.3),
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported, size: 20),
            )
          : CachedNetworkImage(
              imageUrl: url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.customers});
  final CustomerInsight customers;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Khách hàng', style: appStyle(15, kDark, FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CustomerBadge(
                  label: 'Khách mới',
                  value: customers.newCustomers.toString(),
                  color: kPrimary,
                ),
                _CustomerBadge(
                  label: 'Khách quay lại',
                  value: customers.repeatCustomers.toString(),
                  color: Colors.indigo,
                ),
                _CustomerBadge(
                  label: 'Tỷ lệ quay lại',
                  value: '${(customers.repeatRate * 100).toStringAsFixed(1)}%',
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (customers.topCustomers.isEmpty)
              const Text('Chưa có khách hàng nổi bật')
            else ...[
              const Text('Top khách hàng'),
              const SizedBox(height: 8),
              ...customers.topCustomers.map((customer) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(customer.name),
                    subtitle: Text(
                        '${customer.email} • ${customer.orders} đơn • ${formatVND(customer.spend)} đ'),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerBadge extends StatelessWidget {
  const _CustomerBadge({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: appStyle(16, color, FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: appStyle(12, kGray, FontWeight.w500)),
      ],
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.recommendations});
  final StoreRecommendations recommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gợi ý hành động', style: appStyle(16, kDark, FontWeight.w700)),
        const SizedBox(height: 12),
        if (recommendations.trending.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đang bán chạy',
                      style: appStyle(15, kDark, FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...recommendations.trending.map((product) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _ProductImage(url: product.image),
                        title: Text(product.title),
                        subtitle: Text(
                            'Đã bán: ${product.sold} • Doanh thu: ${formatVND(product.revenue)} đ'),
                        trailing: Text('${formatVND(product.price)} đ'),
                      )),
                ],
              ),
            ),
          ),
        if (recommendations.restockAlerts.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cảnh báo tồn kho',
                      style: appStyle(15, kDark, FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...recommendations.restockAlerts.map((alert) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(alert.title,
                            style: appStyle(13, kDark, FontWeight.w600)),
                        subtitle: Text(
                            'Kho: ${alert.stock} • Bán ${alert.sold} trong kỳ'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Nên nhập: ${alert.suggestedOrder}'),
                            Text(alert.urgency.toUpperCase(),
                                style: appStyle(
                                    11, Colors.deepOrange, FontWeight.w600)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        if (recommendations.bundleIdeas.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Combo nên đẩy mạnh',
                      style: appStyle(15, kDark, FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...recommendations.bundleIdeas.map((idea) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Xuất hiện cùng nhau ${idea.ordersTogether} lần'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: idea.products
                                .map((product) => Chip(
                                      avatar: CircleAvatar(
                                        backgroundImage: product.image.isEmpty
                                            ? null
                                            : NetworkImage(product.image),
                                        child: product.image.isEmpty
                                            ? const Icon(Icons.local_offer,
                                                size: 14)
                                            : null,
                                      ),
                                      label: Text(product.title),
                                    ))
                                .toList(),
                          ),
                          const Divider(height: 24),
                        ],
                      )),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
