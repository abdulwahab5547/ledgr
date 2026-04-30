import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/ledgr_card.dart';
import '../../../core/design/components/ledgr_dashed_button.dart';
import '../../../core/design/components/ledgr_icon_button.dart';
import '../../../core/design/components/ledgr_screen_header.dart';
import '../../../core/design/components/ledgr_section_label.dart';
import '../../../core/design/components/ledgr_segmented.dart';
import '../../../core/design/ledgr_colors.dart';
import '../../../core/design/ledgr_typography.dart';
import '../data/incoming_payment_repository.dart';
import '../domain/pipeline_providers.dart';
import 'widgets/incoming_form_sheet.dart';
import 'widgets/mark_received_sheet.dart';
import 'widgets/projected_flow_card.dart';
import 'widgets/recurring_donut_card.dart';
import 'widgets/recurring_form_sheet.dart';
import 'widgets/upcoming_events_card.dart';

/// Pipeline & Analytics screen — wired to real providers in Module 4.
class PipelineScreen extends ConsumerWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizon = ref.watch(pipelineHorizonProvider);
    final incomingMinor = ref.watch(incomingInWindowProvider);
    final outgoingMinor = ref.watch(burnInWindowProvider);
    final flowDays = ref.watch(flowDaysProvider);
    final xLabels = ref.watch(flowXLabelsProvider);
    final donutSegments = ref.watch(categoryBreakdownProvider);
    final monthlyBurn = ref.watch(monthlyBurnMinorProvider);
    final upcoming = ref.watch(upcomingItemsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 130),
          children: [
            LedgrScreenHeader(
              eyebrow: 'Pipeline',
              titleItalic: 'Next ',
              titleRegular: '${horizon.days} days',
              trailing: LedgrIconButton(
                onTap: () => _showAddMenu(context),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: LedgrColors.text,
                ),
              ),
            ),
            const SizedBox(height: 18),
            LedgrSegmented<PipelineHorizon>(
              segments: const [
                LedgrSegment(value: PipelineHorizon.d7, label: '7d'),
                LedgrSegment(value: PipelineHorizon.d14, label: '14d'),
                LedgrSegment(value: PipelineHorizon.d30, label: '30d'),
                LedgrSegment(value: PipelineHorizon.d90, label: '90d'),
              ],
              value: horizon,
              useMonoLabel: true,
              onChanged: (v) =>
                  ref.read(pipelineHorizonProvider.notifier).set(v),
            ),
            const SizedBox(height: 16),
            ProjectedFlowCard(
              incomingMinor: incomingMinor,
              outgoingMinor: outgoingMinor,
              days: flowDays,
              xLabels: xLabels,
            ),
            const SizedBox(height: 12),
            if (donutSegments.isEmpty)
              _EmptyDonutPrompt(onAdd: () => RecurringFormSheet.show(context))
            else
              RecurringDonutCard(
                segments: donutSegments,
                totalLabel: _lakhsLabel(monthlyBurn),
              ),
            LedgrSectionLabel(
              label: 'Upcoming',
              trailing:
                  '${upcoming.length} ${upcoming.length == 1 ? 'event' : 'events'}',
            ),
            UpcomingEventsCard(
              items: upcoming,
              onTapInvoice: (item) async {
                final id = item.incomingId;
                if (id == null) return;
                final payment =
                    ref.read(incomingPaymentRepositoryProvider).findById(id);
                if (payment == null || !context.mounted) return;
                await MarkReceivedSheet.show(context, payment: payment);
              },
              onTapExpense: (_) {},
            ),
            const SizedBox(height: 12),
            LedgrDashedButton(
              icon: Icons.add,
              label: 'Add to pipeline',
              onPressed: () => _showAddMenu(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Two-option chooser between adding an incoming payment or a recurring
  /// expense. Implemented with the same sheet style as the rest of the app.
  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C000000),
      builder: (sheetCtx) => Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: Color(0xFF15161A),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: LedgrColors.hairline2, width: 0.5),
            left: BorderSide(color: LedgrColors.hairline2, width: 0.5),
            right: BorderSide(color: LedgrColors.hairline2, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 18),
                  decoration: BoxDecoration(
                    color: LedgrColors.hairline2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'What are you adding?',
                style: LedgrType.serif(fontSize: 24),
              ),
              const SizedBox(height: 14),
              _AddOption(
                icon: Icons.south_west,
                color: LedgrColors.pos,
                title: 'Incoming',
                subtitle: 'Invoice, salary, or expected payment',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  IncomingFormSheet.show(context);
                },
              ),
              const SizedBox(height: 10),
              _AddOption(
                icon: Icons.repeat_rounded,
                color: LedgrColors.neg,
                title: 'Recurring',
                subtitle: 'Subscription, rent, salaries, utilities…',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  RecurringFormSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _lakhsLabel(int minorUnits) {
    final lakhs = (minorUnits / 100) / 100000;
    if (lakhs >= 100) return '${(lakhs / 100).toStringAsFixed(1)} Cr';
    return '${lakhs.toStringAsFixed(1)} L';
  }
}

class _EmptyDonutPrompt extends StatelessWidget {
  const _EmptyDonutPrompt({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LedgrCard(
      padding: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECURRING EXPENSES',
            style: LedgrType.eyebrow(letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a recurring expense to see your monthly burn split by category.',
            style: LedgrType.sans(fontSize: 13, color: LedgrColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            border: Border.all(color: LedgrColors.hairline2, width: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.20),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: LedgrType.listTitle()),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: LedgrType.sans(
                        fontSize: 12,
                        color: LedgrColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: LedgrColors.textDim,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
