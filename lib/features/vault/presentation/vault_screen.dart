import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/ledgr_dashed_button.dart';
import '../../../core/design/components/ledgr_section_label.dart';
import '../../pipeline/domain/pipeline_providers.dart';
import '../../pipeline/domain/true_liquidity_provider.dart';
import '../domain/vault_providers.dart';
import 'account_form_sheet.dart';
import 'quick_adjust_pad.dart';
import 'widgets/accounts_list.dart';
import 'widgets/bento_stats.dart';
import 'widgets/true_liquidity_card.dart';
import 'widgets/vault_header.dart';

/// The Vault dashboard. Composed of:
/// - VaultHeader (greeting, privacy toggle, notifications)
/// - TrueLiquidityCard (hero metric + sparkline)
/// - BentoStats (burn rate / runway)
/// - AccountsList (linked accounts)
/// - "Link account" dashed button
class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  /// Placeholder sparkline shape — replaced by Module 5's snapshot stream.
  static const List<double> _sampleSpark = [
    42, 45, 41, 47, 50, 48, 52, 56, 54, 58,
    62, 60, 65, 68, 72, 70, 74, 78, 76, 82,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final liquidity = ref.watch(trueLiquidityProvider);
    final monthlyBurn = ref.watch(monthlyBurnMinorProvider);
    final runway = ref.watch(runwayMonthsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 130),
          children: [
            const VaultHeader(userName: 'there'),
            const SizedBox(height: 22),
            TrueLiquidityCard(
              total: liquidity.total,
              deltaMinor: 0,
              deltaPct: 0,
              sparkPoints: _sampleSpark,
              horizonDays: liquidity.horizonDays,
              breakdown: liquidity,
            ),
            const SizedBox(height: 12),
            BentoStats(
              burnLakhsPerMonth: _lakhsFromMinor(monthlyBurn),
              burnDeltaPct: 0, // wired by Module 5 (snapshot-based delta)
              runwayMonths: runway ?? 0,
              runwayCap: 12,
              runwayUnknown: runway == null,
            ),
            LedgrSectionLabel(
              label: 'Assets',
              trailing: accountsAsync.maybeWhen(
                data: (a) => '${a.length} ${a.length == 1 ? 'account' : 'accounts'}',
                orElse: () => null,
              ),
            ),
            accountsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (accounts) => AccountsList(
                accounts: accounts,
                onTapAccount: (a) {
                  if (a.id.isEmpty) {
                    AccountFormSheet.show(context);
                  } else {
                    AccountFormSheet.show(context, existing: a);
                  }
                },
                onLongPressAccount: (a) =>
                    QuickAdjustPad.show(context, account: a),
              ),
            ),
            const SizedBox(height: 12),
            LedgrDashedButton(
              icon: Icons.add,
              label: 'Link account',
              onPressed: () => AccountFormSheet.show(context),
            ),
          ],
        ),
      ),
    );
  }

  static double _lakhsFromMinor(int minor) =>
      (minor / 100) / 100000;
}
