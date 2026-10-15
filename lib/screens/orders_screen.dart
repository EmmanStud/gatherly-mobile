import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class OrdersPanel extends StatefulWidget {
  const OrdersPanel({super.key});

  @override
  State<OrdersPanel> createState() => _OrdersPanelState();
}

class _OrdersPanelState extends State<OrdersPanel> {
  String? _eventFilter;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final orders = state.orders;
    final selectedEvent = _eventFilter == null
        ? null
        : state.events.where((event) => event.id == _eventFilter).firstOrNull;
    final filtered = selectedEvent == null
        ? orders
        : orders
              .where(
                (order) =>
                    order.eventId == selectedEvent.id ||
                    (selectedEvent.eventCode.isNotEmpty &&
                        order.eventCode == selectedEvent.eventCode),
              )
              .toList();
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: PanelTitle(
              'Recent orders',
              'Review payments and order status.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DropdownButtonFormField<String?>(
              initialValue: _eventFilter,
              decoration: const InputDecoration(labelText: 'Filter by event'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All events'),
                ),
                for (final event in state.events)
                  DropdownMenuItem<String?>(
                    value: event.id,
                    child: Text(event.name),
                  ),
              ],
              onChanged: (value) => setState(() => _eventFilter = value),
            ),
          ),
          if (state.dataError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.dataError!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  TextButton(
                    onPressed: state.loadOrganizerData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (state.isLoadingData && orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!state.isLoadingData &&
              state.dataError == null &&
              filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Center(child: Text('No orders found.')),
            ),
          for (final order in filtered) _OrderRow(order: order),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE7E6F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.confirmation_number_outlined,
        size: 20,
        color: AppColors.primary,
      ),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.buyer,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${order.number} · ${order.eventName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          order.ticket,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
    final amount = Text(
      formatPeso(order.amountCentavos),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    );
    final pill = StatusPill(
      order.statusLabel,
      background: order.refunded ? AppColors.refundBg : AppColors.successBg,
      foreground: order.refunded ? AppColors.refundText : AppColors.success,
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth >= 560) {
            return Row(
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(child: info),
                amount,
                const SizedBox(width: 20),
                pill,
              ],
            );
          }
          return Column(
            children: [
              Row(
                children: [
                  avatar,
                  const SizedBox(width: 14),
                  Expanded(child: info),
                  const SizedBox(width: 8),
                  amount,
                ],
              ),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: pill),
            ],
          );
        },
      ),
    );
  }
}
