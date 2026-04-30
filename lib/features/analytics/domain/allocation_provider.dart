import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/charts/ledgr_donut.dart';
import '../../../core/design/ledgr_colors.dart';
import '../../vault/data/account_model.dart';
import '../../vault/domain/vault_providers.dart';

const _palette = <Color>[
  LedgrColors.lime,
  LedgrColors.tintBlue,
  LedgrColors.tintTeal,
  LedgrColors.tintAmber,
  LedgrColors.tintViolet,
  LedgrColors.pos,
];

/// Donut segments showing how liquid wealth is split across active accounts.
/// Empty when no accounts exist.
final allocationSegmentsProvider = Provider<List<DonutSegment>>((ref) {
  final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? const [];
  return computeAllocationSegments(accounts);
});

List<DonutSegment> computeAllocationSegments(List<Account> accounts) {
  final positives = accounts.where((a) => a.balanceMinorUnits > 0).toList()
    ..sort((a, b) => b.balanceMinorUnits.compareTo(a.balanceMinorUnits));
  if (positives.isEmpty) return const [];
  return [
    for (var i = 0; i < positives.length; i++)
      DonutSegment(
        label: positives[i].label,
        value: positives[i].balanceMinorUnits,
        color: _palette[i % _palette.length],
      ),
  ];
}
