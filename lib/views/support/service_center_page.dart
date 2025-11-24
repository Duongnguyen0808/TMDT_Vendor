import 'package:appliances_flutter/constants/constants.dart';
import 'package:appliances_flutter/controllers/service_center_controller.dart';
import 'package:appliances_flutter/models/service_ticket.dart';
import 'package:appliances_flutter/views/support/service_ticket_detail_page.dart';
import 'package:appliances_flutter/views/support/service_ticket_form_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceCenterPage extends StatefulWidget {
  const ServiceCenterPage({super.key});

  @override
  State<ServiceCenterPage> createState() => _ServiceCenterPageState();
}

class _ServiceCenterPageState extends State<ServiceCenterPage> {
  late final ServiceCenterController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ServiceCenterController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Trung tâm dịch vụ',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.fetchTickets(
              status: controller.selectedStatus.value.isEmpty
                  ? null
                  : controller.selectedStatus.value,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async => Get.to(() => const ServiceTicketFormPage()),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo yêu cầu', style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimary,
      ),
      body: Column(
        children: [
          _StatusStrip(controller: controller),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.tickets.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => controller.fetchTickets(
                    status: controller.selectedStatus.value.isEmpty
                        ? null
                        : controller.selectedStatus.value,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    children: const [
                      Icon(Icons.support_agent, size: 64, color: kGray),
                      SizedBox(height: 12),
                      Text(
                        'Bạn chưa có yêu cầu nào. Nhấn "Tạo yêu cầu" để bắt đầu.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => controller.fetchTickets(
                  status: controller.selectedStatus.value.isEmpty
                      ? null
                      : controller.selectedStatus.value,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final ticket = controller.tickets[index];
                    return _TicketCard(controller: controller, ticket: ticket);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final ServiceCenterController controller;
  const _StatusStrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final metaStatuses = controller.metadata['statuses'];
      final List<String> statuses =
          (metaStatuses != null && metaStatuses.isNotEmpty)
              ? metaStatuses
              : ServiceTicket.defaultStatuses;
      final selected = controller.selectedStatus.value;
      return SizedBox(
        height: 56,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, idx) {
            final normalized = idx == 0 ? '' : statuses[idx - 1];
            final active = selected == normalized;
            return ChoiceChip(
              label: Text(idx == 0
                  ? 'Tất cả'
                  : ServiceTicket.labelForStatus(normalized)),
              selected: active,
              onSelected: (_) {
                controller.selectedStatus.value = normalized;
                controller.fetchTickets(
                    status: normalized.isEmpty ? null : normalized);
              },
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: statuses.length + 1,
        ),
      );
    });
  }
}

class _TicketCard extends StatelessWidget {
  final ServiceTicket ticket;
  final ServiceCenterController controller;
  const _TicketCard({required this.controller, required this.ticket});

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
      case 'Closed':
        return Colors.green.shade600;
      case 'WaitingRequester':
        return Colors.orange.shade600;
      case 'In Progress':
        return Colors.blue.shade600;
      default:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final detail = await controller.fetchTicketDetail(ticket.id);
        if (detail != null) {
          Get.to(() => ServiceTicketDetailPage(ticketId: detail.id));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(ticket.status).withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ticket.readableStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(ticket.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '#${ticket.code} • Ưu tiên ${ticket.readablePriority}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: kGray),
                const SizedBox(width: 4),
                Text(
                  ticket.timeAgo(),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: kGray),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
