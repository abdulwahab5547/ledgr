import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/components/ledgr_icon_button.dart';
import '../../../../core/design/components/ledgr_screen_header.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/privacy/privacy_provider.dart';
import '../../../../core/time/clock.dart';

/// Greeting + privacy/analytics/settings controls. Consumes privacy and
/// clock providers so the header reflects live state.
class VaultHeader extends ConsumerWidget {
  const VaultHeader({required this.userName, super.key});

  final String userName;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).now();
    final dateLabel =
        '${_weekdays[now.weekday - 1]} · ${now.day.toString().padLeft(2, '0')} ${_months[now.month - 1]}';
    final masked = ref.watch(privacyModeProvider);

    return LedgrScreenHeader(
      eyebrow: dateLabel,
      titleItalic: _greeting(now.hour),
      titleRegular: ' $userName',
      trailing: Row(
        children: [
          LedgrIconButton(
            onTap: () => ref.read(privacyModeProvider.notifier).toggle(),
            child: Icon(
              masked
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: LedgrColors.text,
            ),
          ),
          const SizedBox(width: 10),
          LedgrIconButton(
            onTap: () => context.push('/analytics'),
            child: const Icon(
              Icons.insights_outlined,
              size: 18,
              color: LedgrColors.text,
            ),
          ),
          const SizedBox(width: 10),
          LedgrIconButton(
            onTap: () => context.push('/settings'),
            child: const Icon(
              Icons.settings_outlined,
              size: 18,
              color: LedgrColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
