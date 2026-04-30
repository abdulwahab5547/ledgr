import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/ambient_backdrop.dart';
import '../../../core/design/components/ledgr_back_header.dart';
import '../../../core/design/components/ledgr_buttons.dart';
import '../../../core/design/components/ledgr_card.dart';
import '../../../core/design/ledgr_colors.dart';
import '../../../core/design/ledgr_typography.dart';
import '../../../core/haptics/haptics.dart';
import '../../export/pdf_export_service.dart';
import '../domain/allocation_provider.dart';
import '../domain/category_history_provider.dart';
import '../domain/snapshot_providers.dart';
import 'widgets/allocation_card.dart';
import 'widgets/category_bar_card.dart';
import 'widgets/net_position_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(snapshotsStreamProvider).valueOrNull ?? const [];
    final allocation = ref.watch(allocationSegmentsProvider);
    final categories = ref.watch(categoryHistory30dProvider);

    final allocationTotal =
        allocation.fold<num>(0, (a, b) => a + b.value);

    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            children: [
              const LedgrBackHeader(
                eyebrow: 'Analytics',
                title: 'Insights',
              ),
              const SizedBox(height: 20),
              NetPositionCard(snapshots: snapshots),
              const SizedBox(height: 12),
              AllocationCard(
                segments: allocation,
                totalLabel: _lakhsLabel(allocationTotal.toInt()),
              ),
              const SizedBox(height: 12),
              CategoryBarCard(totals: categories),
              const SizedBox(height: 22),
              _ExportSection(),
            ],
          ),
        ),
      ),
    );
  }

  static String _lakhsLabel(int minor) {
    final lakhs = (minor / 100) / 100000;
    if (lakhs >= 100) return '${(lakhs / 100).toStringAsFixed(1)} Cr';
    return '${lakhs.toStringAsFixed(1)} L';
  }
}

class _ExportSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends ConsumerState<_ExportSection> {
  bool _busy = false;
  String? _error;

  Future<void> _export() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final action = ref.read(exportPdfActionProvider);
    try {
      await action();
      await Haptics.success();
    } on Object catch (e) {
      setState(() => _error = e.toString());
      await Haptics.warn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LedgrCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPORT',
            style: LedgrType.eyebrow(letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Text(
            'Monthly summary as PDF',
            style: LedgrType.serif(fontSize: 22, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          Text(
            'Vault, Social Ledger, Pipeline, and category burn rolled into a printable one-pager.',
            style: LedgrType.sans(fontSize: 13, color: LedgrColors.textDim),
          ),
          const SizedBox(height: 16),
          LedgrPrimaryButton(
            label: _busy ? 'Generating…' : 'Generate PDF',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: _busy ? null : _export,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: LedgrType.sans(fontSize: 12, color: LedgrColors.neg),
            ),
          ],
        ],
      ),
    );
  }
}

