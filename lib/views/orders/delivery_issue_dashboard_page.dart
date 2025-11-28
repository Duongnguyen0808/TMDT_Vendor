import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:appliances_flutter/controllers/vendor_order_controller.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/models/orders_model.dart';
import 'package:appliances_flutter/views/orders/order_detail_page.dart';

class DeliveryIssueDashboardPage extends HookWidget {
  const DeliveryIssueDashboardPage({super.key});

  static const _timeRanges = [
    _TimeFilterOption('Tất cả thời gian', 0),
    _TimeFilterOption('3 ngày', 3),
    _TimeFilterOption('7 ngày', 7),
    _TimeFilterOption('14 ngày', 14),
    _TimeFilterOption('30 ngày', 30),
    _TimeFilterOption('90 ngày', 90),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<VendorOrderController>()
        ? Get.find<VendorOrderController>()
        : Get.put(VendorOrderController());
    final storeFilter = useState<String>('all');
    final driverFilter = useState<String>('all');
    final rangeFilter = useState<int>(_timeRanges[2].days); // default 7 ngày
    final driverDirectory = useState<Map<String, String>>({});
    final driverLoading = useState<bool>(false);

    Future<void> _reloadDrivers() async {
      driverLoading.value = true;
      driverDirectory.value = await _fetchDriverDirectory();
      driverLoading.value = false;
    }

    final summaryFuture = useMemoized(_fetchBackendIssueSummary, const []);
    final summarySnapshot = useFuture(summaryFuture);

    useEffect(() {
      ctrl.fetchAllOrders();
      _reloadDrivers();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển giao hàng'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await Future.wait([ctrl.fetchAllOrders(), _reloadDrivers()]);
            },
          ),
        ],
      ),
      body: Obx(() {
        final snapshot = ctrl.allOrdersSnapshot();
        final storeOptions = _buildStoreOptions(snapshot);
        final driverOptions =
            _buildDriverOptions(snapshot, driverDirectory.value);
        final safeStore = _coerceSelection(storeFilter.value, storeOptions);
        final safeDriver = _coerceSelection(driverFilter.value, driverOptions);
        if (safeStore != storeFilter.value) storeFilter.value = safeStore;
        if (safeDriver != driverFilter.value) driverFilter.value = safeDriver;

        final baseIssues = snapshot.where(_hasIssue).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final filteredIssues = _applyFilters(
          baseIssues,
          storeFilter.value,
          driverFilter.value,
          rangeFilter.value,
        );
        final summary = _IssueSummary.fromOrders(filteredIssues);
        final breakdown = _IssueBreakdown.fromOrders(
          filteredIssues,
          driverDirectory.value,
        );
        final trendPoints = _buildTrendSeries(
          filteredIssues,
          backendSummary: summarySnapshot.data,
        );
        final trendMeta = _TrendMeta.fromPoints(trendPoints);

        if (ctrl.isLoading.value && filteredIssues.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([ctrl.fetchAllOrders(), _reloadDrivers()]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _FilterPanel(
                storeOptions: storeOptions,
                driverOptions: driverOptions,
                timeOptions: _timeRanges,
                selectedStore: storeFilter.value,
                selectedDriver: driverFilter.value,
                selectedRange: rangeFilter.value,
                onStoreChanged: (value) => storeFilter.value = value,
                onDriverChanged: (value) => driverFilter.value = value,
                onRangeChanged: (value) => rangeFilter.value = value,
                onReset: () {
                  storeFilter.value = 'all';
                  driverFilter.value = 'all';
                  rangeFilter.value = _timeRanges[2].days;
                },
                driversLoading: driverLoading.value,
              ),
              const SizedBox(height: 16),
              const _IssueInfoBanner(),
              const SizedBox(height: 16),
              _SummaryGrid(summary: summary),
              const SizedBox(height: 16),
              if (breakdown.hasData) ...[
                _TopSourcesCard(breakdown: breakdown),
                const SizedBox(height: 16),
              ],
              _TrendCard(
                points: trendPoints,
                meta: trendMeta,
                dataSourceLabel: summarySnapshot.data != null
                    ? 'Nguồn: API tóm tắt'
                    : 'Nguồn: dữ liệu hiện có',
              ),
              const SizedBox(height: 16),
              if (filteredIssues.isEmpty)
                _emptyView(
                  rangeFilter.value == 0
                      ? 'Không có cảnh báo phù hợp với bộ lọc hiện tại.'
                      : 'Không có cảnh báo trong ${rangeFilter.value} ngày gần đây cho bộ lọc này.',
                )
              else
                _IssueList(
                  orders: filteredIssues,
                  controller: ctrl,
                  driverDirectory: driverDirectory.value,
                ),
            ],
          ),
        );
      }),
    );
  }
}

const bool _issueSummaryApiEnabled =
    bool.fromEnvironment('VENDOR_ISSUE_SUMMARY_API', defaultValue: false);

List<OrdersModel> _applyFilters(
  List<OrdersModel> source,
  String storeId,
  String driverId,
  int rangeDays,
) {
  var result = source;
  if (storeId != 'all') {
    result = result.where((o) => o.storeId.id == storeId).toList();
  }
  if (driverId != 'all') {
    result = result
        .where((o) => (o.driverId ?? '').isNotEmpty && o.driverId == driverId)
        .toList();
  }
  if (rangeDays > 0) {
    final cutoff = DateTime.now().subtract(Duration(days: rangeDays));
    result = result.where((o) => o.updatedAt.isAfter(cutoff)).toList();
  }
  return result;
}

class _DropdownOption {
  final String id;
  final String label;
  const _DropdownOption(this.id, this.label);
}

List<_DropdownOption> _buildStoreOptions(List<OrdersModel> orders) {
  final entries = <String, String>{'all': 'Tất cả chi nhánh'};
  for (final o in orders) {
    if (o.storeId.id.isNotEmpty) {
      entries[o.storeId.id] = o.storeId.title.isNotEmpty
          ? o.storeId.title
          : 'Cửa hàng ${o.storeId.id.substring(0, min(4, o.storeId.id.length))}';
    }
  }
  return entries.entries
      .map((e) => _DropdownOption(e.key, e.value))
      .toList(growable: false);
}

List<_DropdownOption> _buildDriverOptions(
  List<OrdersModel> orders,
  Map<String, String> driverDirectory,
) {
  final entries = <String, String>{'all': 'Tất cả tài xế'};
  for (final o in orders) {
    final id = o.driverId;
    if (id == null || id.isEmpty) continue;
    entries[id] = driverDirectory[id] ?? _fallbackDriverLabel(id);
  }
  return entries.entries
      .map((e) => _DropdownOption(e.key, e.value))
      .toList(growable: false);
}

String _coerceSelection(String current, List<_DropdownOption> options) {
  if (options.any((o) => o.id == current)) return current;
  return options.first.id;
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.storeOptions,
    required this.driverOptions,
    required this.timeOptions,
    required this.selectedStore,
    required this.selectedDriver,
    required this.selectedRange,
    required this.onStoreChanged,
    required this.onDriverChanged,
    required this.onRangeChanged,
    required this.onReset,
    required this.driversLoading,
  });

  final List<_DropdownOption> storeOptions;
  final List<_DropdownOption> driverOptions;
  final List<_TimeFilterOption> timeOptions;
  final String selectedStore;
  final String selectedDriver;
  final int selectedRange;
  final ValueChanged<String> onStoreChanged;
  final ValueChanged<String> onDriverChanged;
  final ValueChanged<int> onRangeChanged;
  final VoidCallback onReset;
  final bool driversLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Bộ lọc', style: appStyle(15, kDark, FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Đặt lại'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FilterDropdown(
              label: 'Chi nhánh cửa hàng',
              value: selectedStore,
              onChanged: onStoreChanged,
              options: storeOptions,
            ),
            const SizedBox(height: 12),
            _FilterDropdown(
              label: 'Tài xế',
              value: selectedDriver,
              onChanged: onDriverChanged,
              options: driverOptions,
              trailing: driversLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            _FilterDropdown(
              label: 'Khoảng thời gian',
              value: selectedRange.toString(),
              onChanged: (value) => onRangeChanged(int.parse(value)),
              options: timeOptions
                  .map((e) => _DropdownOption(e.days.toString(), e.label))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueInfoBanner extends StatelessWidget {
  const _IssueInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kPrimary.withOpacity(.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.local_shipping, color: kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theo dõi vấn đề giao hàng',
                      style: appStyle(14, kDark, FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text(
                    'Bảng này gom tất cả đơn đang gặp sự cố: thiếu bằng chứng giao hàng, hệ thống cảnh báo hoặc khiếu nại của khách. Dùng bộ lọc để khoanh vùng theo chi nhánh, tài xế và mốc thời gian.',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mẹo: chạm "Xem chi tiết" để mở đơn và xử lý trực tiếp.',
                    style: appStyle(12, kGray, FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.options,
    this.trailing,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final List<_DropdownOption> options;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: trailing,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: options
              .map(
                (opt) => DropdownMenuItem<String>(
                  value: opt.id,
                  child: Text(opt.label),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

class _IssueSummary {
  final int pendingProof;
  final int rejectedProof;
  final int escalated;
  final int disputes;
  final int resolved;

  const _IssueSummary({
    required this.pendingProof,
    required this.rejectedProof,
    required this.escalated,
    required this.disputes,
    required this.resolved,
  });

  factory _IssueSummary.fromOrders(List<OrdersModel> orders) {
    int pendingProof = 0;
    int rejectedProof = 0;
    int escalated = 0;
    int disputes = 0;
    int resolved = 0;
    for (final o in orders) {
      final confirm = (o.shopDeliveryConfirmStatus ?? 'None');
      final issue = (o.deliveryIssueStatus ?? 'None');
      final dispute = (o.customerDisputeStatus ?? 'None');
      if (confirm == 'Pending') pendingProof++;
      if (confirm == 'Rejected') rejectedProof++;
      if (issue == 'Warned' || issue == 'Escalated') escalated++;
      if (dispute == 'Pending' || issue == 'Disputed') disputes++;
      if (dispute == 'Resolved' || issue == 'Resolved') resolved++;
    }
    return _IssueSummary(
      pendingProof: pendingProof,
      rejectedProof: rejectedProof,
      escalated: escalated,
      disputes: disputes,
      resolved: resolved,
    );
  }
}

class _IssueBreakdown {
  final List<_IssueSourceStat> storeLeaders;
  final List<_IssueSourceStat> driverLeaders;
  const _IssueBreakdown({
    required this.storeLeaders,
    required this.driverLeaders,
  });

  bool get hasData => storeLeaders.isNotEmpty || driverLeaders.isNotEmpty;

  factory _IssueBreakdown.fromOrders(
    List<OrdersModel> orders,
    Map<String, String> driverDirectory,
  ) {
    final Map<String, _IssueSourceStat> storeMap = {};
    final Map<String, _IssueSourceStat> driverMap = {};

    for (final order in orders) {
      final storeId = order.storeId.id;
      if (storeId.isNotEmpty) {
        final label = order.storeId.title.isNotEmpty
            ? order.storeId.title
            : 'Cửa hàng ${storeId.substring(0, storeId.length.clamp(0, 6))}';
        storeMap.update(
          storeId,
          (existing) => existing.incremented(),
          ifAbsent: () => _IssueSourceStat(id: storeId, label: label),
        );
      }

      final driverId = order.driverId;
      if (driverId != null && driverId.isNotEmpty) {
        final label =
            driverDirectory[driverId] ?? _fallbackDriverLabel(driverId);
        driverMap.update(
          driverId,
          (existing) => existing.incremented(),
          ifAbsent: () => _IssueSourceStat(id: driverId, label: label),
        );
      }
    }

    List<_IssueSourceStat> sortStats(Map<String, _IssueSourceStat> stats) {
      final list = stats.values.toList()
        ..sort((a, b) => b.count.compareTo(a.count));
      return list.take(5).toList();
    }

    return _IssueBreakdown(
      storeLeaders: sortStats(storeMap),
      driverLeaders: sortStats(driverMap),
    );
  }
}

class _IssueSourceStat {
  final String id;
  final String label;
  final int count;
  const _IssueSourceStat({
    required this.id,
    required this.label,
    this.count = 1,
  });

  _IssueSourceStat incremented() =>
      _IssueSourceStat(id: id, label: label, count: count + 1);
}

class _TopSourcesCard extends StatelessWidget {
  const _TopSourcesCard({required this.breakdown});
  final _IssueBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Nguồn cảnh báo nổi bật',
                    style: appStyle(15, kDark, FontWeight.w600)),
                const Spacer(),
                Tooltip(
                  message:
                      'Tổng hợp 5 chi nhánh và tài xế có nhiều cảnh báo nhất theo bộ lọc hiện tại.',
                  child: const Icon(Icons.info_outline, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (breakdown.storeLeaders.isNotEmpty)
              _SourceList(
                title: 'Chi nhánh có nhiều cảnh báo',
                stats: breakdown.storeLeaders,
              ),
            if (breakdown.storeLeaders.isNotEmpty &&
                breakdown.driverLeaders.isNotEmpty)
              const SizedBox(height: 16),
            if (breakdown.driverLeaders.isNotEmpty)
              _SourceList(
                title: 'Tài xế có nhiều cảnh báo',
                stats: breakdown.driverLeaders,
              ),
            if (!breakdown.hasData)
              const Text('Chưa có dữ liệu để phân tích nguồn cảnh báo.'),
          ],
        ),
      ),
    );
  }
}

class _SourceList extends StatelessWidget {
  const _SourceList({required this.title, required this.stats});
  final String title;
  final List<_IssueSourceStat> stats;

  @override
  Widget build(BuildContext context) {
    final maxCount = stats.map((s) => s.count).fold<int>(1, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: appStyle(13, kDark, FontWeight.w600)),
        const SizedBox(height: 8),
        ...stats.map((stat) {
          final ratio = stat.count / maxCount;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(stat.label,
                          style: appStyle(12, kDark, FontWeight.w500)),
                    ),
                    Text('${stat.count}',
                        style: appStyle(12, kGray, FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: kGray.withOpacity(.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(kPrimary.withOpacity(.8)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});
  final _IssueSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(
        label: 'Chờ xác nhận',
        value: summary.pendingProof,
        color: Colors.amber.shade700,
        icon: Icons.hourglass_top,
      ),
      _SummaryCard(
        label: 'Bị từ chối',
        value: summary.rejectedProof,
        color: Colors.redAccent,
        icon: Icons.block,
      ),
      _SummaryCard(
        label: 'Cảnh báo hệ thống',
        value: summary.escalated,
        color: Colors.deepOrange,
        icon: Icons.warning_amber,
      ),
      _SummaryCard(
        label: 'Khiếu nại mở',
        value: summary.disputes,
        color: Colors.purple,
        icon: Icons.report_problem,
      ),
      _SummaryCard(
        label: 'Đã xử lý',
        value: summary.resolved,
        color: Colors.green,
        icon: Icons.verified_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 900
            ? 3
            : maxWidth >= 600
                ? 2
                : 1;
        final spacing = 12.0;
        final totalSpacing = spacing * (columns - 1);
        final itemWidth =
            columns == 1 ? maxWidth : (maxWidth - totalSpacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: appStyle(22, color, FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: appStyle(12, kDark, FontWeight.w500)),
        ],
      ),
    );
  }
}

class _IssueList extends StatelessWidget {
  const _IssueList({
    required this.orders,
    required this.controller,
    required this.driverDirectory,
  });
  final List<OrdersModel> orders;
  final VendorOrderController controller;
  final Map<String, String> driverDirectory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReusableText(
          text: 'Danh sách cảnh báo (${orders.length})',
          style: appStyle(14, kDark, FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _IssueTile(
              order: order,
              controller: controller,
              driverDirectory: driverDirectory,
            );
          },
        ),
      ],
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.order,
    required this.controller,
    required this.driverDirectory,
  });
  final OrdersModel order;
  final VendorOrderController controller;
  final Map<String, String> driverDirectory;

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 6
        ? order.id.substring(order.id.length - 6).toUpperCase()
        : order.id.toUpperCase();
    final confirm = (order.shopDeliveryConfirmStatus ?? 'None');
    final issue = (order.deliveryIssueStatus ?? 'None');
    final dispute = (order.customerDisputeStatus ?? 'None');
    final notes = <String>[];
    if ((order.shopDeliveryRejectReason ?? '').isNotEmpty) {
      notes.add('Shop: ${order.shopDeliveryRejectReason}');
    }
    if ((order.deliveryIssueNote ?? '').isNotEmpty) {
      notes.add('Hệ thống: ${order.deliveryIssueNote}');
    }
    if ((order.customerDisputeNote ?? '').isNotEmpty) {
      notes.add('Khách: ${order.customerDisputeNote}');
    }
    final driverName = _resolveDriverName(order.driverId, driverDirectory);
    final pendingDispute = dispute == 'Pending';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#$shortId · ${order.storeId.title}',
                    style: appStyle(13, kDark, FontWeight.w600),
                  ),
                ),
                Text(
                  _formatDate(order.updatedAt),
                  style: appStyle(11, kGray, FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (confirm != 'None')
                  _statusChip(
                      _shopStatusLabel(confirm), _shopStatusColor(confirm)),
                if (issue != 'None')
                  _statusChip(
                      _issueStatusLabel(issue), _issueStatusColor(issue)),
                if (dispute != 'None')
                  _statusChip(
                    _disputeStatusLabel(dispute),
                    _disputeStatusColor(dispute),
                  ),
              ],
            ),
            if (driverName != null) ...[
              const SizedBox(height: 6),
              Text(
                'Tài xế: $driverName',
                style: appStyle(12, kGray, FontWeight.w500),
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                notes.join('\n'),
                style: appStyle(12, kDark, FontWeight.w400),
              ),
            ],
            const SizedBox(height: 8),
            if (pendingDispute)
              Obx(() {
                final working =
                    controller.disputeActionOrderId.value == order.id;
                if (working) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ));
                }
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDisputeDialog(
                          context,
                          controller,
                          order,
                          resolve: true,
                        ),
                        icon: const Icon(Icons.verified),
                        label: const Text('Giải quyết'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDisputeDialog(
                          context,
                          controller,
                          order,
                          resolve: false,
                        ),
                        icon: const Icon(Icons.gpp_bad),
                        label: const Text('Từ chối'),
                      ),
                    ),
                  ],
                );
              }),
            if (pendingDispute) const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    Get.to(() => OrderDetailPage(orderId: order.id)),
                child: const Text('Xem chi tiết'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: appStyle(11, color, FontWeight.w600),
      ),
    );
  }

  static String _shopStatusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ shop duyệt';
      case 'Rejected':
        return 'Shop từ chối';
      case 'Confirmed':
        return 'Shop đã duyệt';
      default:
        return status;
    }
  }

  static Color _shopStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.amber.shade800;
      case 'Rejected':
        return Colors.redAccent;
      case 'Confirmed':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  static String _issueStatusLabel(String status) {
    switch (status) {
      case 'Warned':
        return 'Hệ thống nhắc nhở';
      case 'Escalated':
        return 'Đang bị escalate';
      case 'Disputed':
        return 'Đang tranh chấp';
      case 'Resolved':
        return 'Đã xử lý';
      default:
        return status;
    }
  }

  static Color _issueStatusColor(String status) {
    switch (status) {
      case 'Warned':
        return Colors.orange;
      case 'Escalated':
        return Colors.deepOrange;
      case 'Disputed':
        return Colors.purple;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  static String _disputeStatusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Khách khiếu nại';
      case 'Resolved':
        return 'Đã giải quyết';
      case 'Rejected':
        return 'Shop từ chối';
      default:
        return status;
    }
  }

  static Color _disputeStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.redAccent;
      case 'Resolved':
        return Colors.green;
      case 'Rejected':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

Widget _emptyView(String message) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Icon(Icons.celebration, size: 48, color: Colors.green),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: appStyle(14, Colors.green.shade900, FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text('Tiếp tục giữ chất lượng phản hồi nhanh nhé!'),
      ],
    ),
  );
}

Future<Map<String, String>> _fetchDriverDirectory() async {
  try {
    final storage = GetStorage();
    final token = storage.read('accessToken');
    if (token == null) return {};
    final url = Uri.parse('$appBaseUrl/api/drivers');
    final resp = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      final data = decoded['data'] as List<dynamic>? ?? const [];
      final map = <String, String>{};
      for (final entry in data) {
        final row = entry is Map ? entry : <String, dynamic>{};
        final user = row['user'];
        if (user is Map && user['_id'] != null) {
          final id = user['_id'].toString();
          final username = (user['username'] ?? '').toString();
          if (id.isNotEmpty) {
            map[id] = username.isNotEmpty ? username : _fallbackDriverLabel(id);
          }
        }
      }
      return map;
    }
  } catch (e) {
    debugPrint('[driverDirectory] $e');
  }
  return {};
}

Future<Map<String, dynamic>?> _fetchBackendIssueSummary() async {
  if (!_issueSummaryApiEnabled) return null;
  try {
    final storage = GetStorage();
    final token = storage.read('accessToken');
    if (token == null) return null;
    final url = Uri.parse('$appBaseUrl/api/orders/issues/summary');
    final resp = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded['data'])
            : decoded;
      }
    }
  } catch (e) {
    debugPrint('[issueSummaryApi] $e');
  }
  return null;
}

class _TimeFilterOption {
  final String label;
  final int days;
  const _TimeFilterOption(this.label, this.days);
}

String? _resolveDriverName(
    String? driverId, Map<String, String> driverDirectory) {
  if (driverId == null || driverId.isEmpty) return null;
  return driverDirectory[driverId] ?? _fallbackDriverLabel(driverId);
}

String _fallbackDriverLabel(String driverId) {
  final short = driverId.length > 6
      ? driverId.substring(driverId.length - 6).toUpperCase()
      : driverId.toUpperCase();
  return 'ID $short';
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.points,
    required this.meta,
    required this.dataSourceLabel,
  });

  final List<_TrendPoint> points;
  final _TrendMeta meta;
  final String dataSourceLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Xu hướng tuần này',
                    style: appStyle(15, kDark, FontWeight.w600)),
                const Spacer(),
                Chip(
                  label: Text(meta.deltaDescription,
                      style: appStyle(11, Colors.white, FontWeight.w600)),
                  backgroundColor: meta.deltaColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            points.length >= 2
                ? _TrendSparkline(points: points)
                : Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: const Text('Chưa đủ dữ liệu để vẽ xu hướng'),
                  ),
            const SizedBox(height: 12),
            Text('Tuần này: ${meta.currentWeek} cảnh báo',
                style: appStyle(13, kDark, FontWeight.w500)),
            Text('Tuần trước: ${meta.previousWeek} cảnh báo',
                style: appStyle(12, kGray, FontWeight.w500)),
            const SizedBox(height: 4),
            Text(dataSourceLabel, style: appStyle(11, kGray, FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _TrendSparkline extends StatelessWidget {
  const _TrendSparkline({required this.points});
  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _TrendSparklinePainter(points),
        child: Container(),
      ),
    );
  }
}

class _TrendSparklinePainter extends CustomPainter {
  final List<_TrendPoint> points;
  _TrendSparklinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxValue =
        points.map((e) => e.value).fold<int>(0, max).clamp(1, 9999);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final y = size.height - (points[i].value / maxValue) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    final lastPoint = points.last;
    final lastOffset = Offset(
      size.width,
      size.height - (lastPoint.value / maxValue) * size.height,
    );
    canvas.drawCircle(lastOffset, 5, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TrendPoint {
  final DateTime weekStart;
  final int value;
  const _TrendPoint(this.weekStart, this.value);
}

List<_TrendPoint> _buildTrendSeries(
  List<OrdersModel> orders, {
  Map<String, dynamic>? backendSummary,
}) {
  final points = <_TrendPoint>[];
  if (backendSummary != null) {
    final weeks = backendSummary['weeks'] as List<dynamic>?;
    if (weeks != null && weeks.isNotEmpty) {
      for (final w in weeks) {
        if (w is Map && w['start'] != null && w['count'] != null) {
          try {
            points.add(_TrendPoint(
              DateTime.parse(w['start'].toString()),
              int.tryParse(w['count'].toString()) ?? 0,
            ));
          } catch (_) {}
        }
      }
      if (points.isNotEmpty)
        return points..sort((a, b) => a.weekStart.compareTo(b.weekStart));
    }
  }

  final Map<DateTime, int> weekBuckets = {};
  for (final order in orders) {
    final weekStart = _startOfWeek(order.updatedAt);
    weekBuckets.update(weekStart, (value) => value + 1, ifAbsent: () => 1);
  }
  final sortedKeys = weekBuckets.keys.toList()..sort();
  for (final key in sortedKeys) {
    points.add(_TrendPoint(key, weekBuckets[key] ?? 0));
  }
  return points;
}

DateTime _startOfWeek(DateTime date) {
  final d = date.toLocal();
  final difference = d.weekday - DateTime.monday;
  final monday = d.subtract(Duration(days: difference < 0 ? 6 : difference));
  return DateTime(monday.year, monday.month, monday.day);
}

class _TrendMeta {
  final int currentWeek;
  final int previousWeek;
  final double delta;
  const _TrendMeta(this.currentWeek, this.previousWeek, this.delta);

  String get deltaDescription {
    if (delta == 0) return 'Không đổi';
    final prefix = delta > 0 ? '+' : '';
    return '$prefix${delta.toStringAsFixed(1)}%';
  }

  Color get deltaColor {
    if (delta == 0) return Colors.blueGrey;
    return delta > 0 ? Colors.deepOrange : Colors.green;
  }

  factory _TrendMeta.fromPoints(List<_TrendPoint> points) {
    if (points.isEmpty) return const _TrendMeta(0, 0, 0);
    final currentWeek = points.isNotEmpty ? points.last.value : 0;
    final prevWeek = points.length >= 2 ? points[points.length - 2].value : 0;
    double delta = 0;
    if (prevWeek == 0) {
      delta = currentWeek == 0 ? 0 : 100;
    } else {
      delta = ((currentWeek - prevWeek) / prevWeek) * 100;
    }
    return _TrendMeta(currentWeek, prevWeek, delta);
  }
}

Future<void> _showDisputeDialog(
  BuildContext context,
  VendorOrderController controller,
  OrdersModel order, {
  required bool resolve,
}) async {
  final noteCtrl = TextEditingController();
  bool submitting = false;
  await showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title:
                Text(resolve ? 'Giải quyết tranh chấp' : 'Từ chối tranh chấp'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: noteCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú cho khách hàng',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    submitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Huỷ'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        setState(() => submitting = true);
                        final success = await controller.reviewDeliveryDispute(
                          order.id,
                          resolve: resolve,
                          note: noteCtrl.text.trim(),
                        );
                        setState(() => submitting = false);
                        if (success && Navigator.of(dialogCtx).canPop()) {
                          Navigator.of(dialogCtx).pop();
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Xác nhận'),
              ),
            ],
          );
        },
      );
    },
  );
  noteCtrl.dispose();
}

bool _hasIssue(OrdersModel order) {
  final confirm = (order.shopDeliveryConfirmStatus ?? 'None');
  final issue = (order.deliveryIssueStatus ?? 'None');
  final dispute = (order.customerDisputeStatus ?? 'None');
  if (confirm == 'Pending' || confirm == 'Rejected') return true;
  if (issue != 'None' && issue != 'Resolved') return true;
  if (dispute != 'None') return true;
  return false;
}
