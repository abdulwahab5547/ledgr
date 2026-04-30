import 'package:flutter/material.dart';

import '../../../../core/design/components/ledgr_card.dart';
import '../../../../core/design/ledgr_colors.dart';
import '../../../../core/design/ledgr_radii.dart';
import '../../../../core/design/ledgr_typography.dart';
import '../../../../core/haptics/haptics.dart';
import '../../../../core/money/pkr_format.dart';
import '../../../../core/privacy/private_text.dart';
import '../../data/account_model.dart';

/// Vertical list of account rows inside a single rounded card. Each row
/// shows a tinted icon chip, label + masked hint, and the balance.
class AccountsList extends StatelessWidget {
  const AccountsList({
    required this.accounts,
    required this.onTapAccount,
    required this.onLongPressAccount,
    super.key,
  });

  final List<Account> accounts;
  final ValueChanged<Account> onTapAccount;
  final ValueChanged<Account> onLongPressAccount;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return _Empty(onAdd: () => onTapAccount.call(_dummyForAdd()));
    }
    return LedgrCard.flush(
      child: Column(
        children: [
          for (var i = 0; i < accounts.length; i++) ...[
            _AccountRow(
              account: accounts[i],
              onTap: () => onTapAccount(accounts[i]),
              onLongPress: () {
                Haptics.tap();
                onLongPressAccount(accounts[i]);
              },
            ),
            if (i < accounts.length - 1)
              const Divider(height: 0.5, color: LedgrColors.hairline),
          ],
        ],
      ),
    );
  }

  // _Empty's onAdd reuses the same callback path; we synthesise a noop
  // account just so the type signature lines up. Vault screen ignores the
  // arg when accounts list is empty (it shows the form sheet).
  Account _dummyForAdd() => Account(
        id: '',
        label: '',
        type: AccountType.bank,
        balanceMinorUnits: 0,
        currencyCode: 'PKR',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.onTap,
    required this.onLongPress,
  });

  final Account account;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tint = _tintFor(account.type);
    final balanceText =
        PkrFormat.money(account.balance, includeSymbol: account.currencyCode == 'PKR');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _IconChip(
                icon: _iconFor(account.type),
                tint: tint,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.label,
                      style: LedgrType.listTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _kindLabel(account.type).toUpperCase(),
                          style: LedgrType.sans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: LedgrColors.textMute,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 2,
                          height: 2,
                          decoration: const BoxDecoration(
                            color: LedgrColors.textFaint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          account.currencyCode,
                          style: LedgrType.mono(
                            fontSize: 10.5,
                            color: LedgrColors.textMute,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PrivateText.digits(
                balanceText,
                style: LedgrType.amountMono(),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _kindLabel(AccountType t) => switch (t) {
        AccountType.bank => 'Bank',
        AccountType.wallet => 'Digital',
        AccountType.cash => 'Cash',
        AccountType.other => 'Other',
      };

  IconData _iconFor(AccountType t) => switch (t) {
        AccountType.bank => Icons.account_balance_outlined,
        AccountType.wallet => Icons.smartphone_outlined,
        AccountType.cash => Icons.payments_outlined,
        AccountType.other => Icons.savings_outlined,
      };

  Color _tintFor(AccountType t) => switch (t) {
        AccountType.bank => LedgrColors.tintBlue,
        AccountType.wallet => LedgrColors.lime,
        AccountType.cash => LedgrColors.tintAmber,
        AccountType.other => LedgrColors.tintTeal,
      };
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.tint});
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.13), tint.withValues(alpha: 0.03)],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.20), width: 0.5),
        borderRadius: BorderRadius.circular(LedgrRadii.accountChip),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: tint),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LedgrCard(
      padding: 24,
      child: Column(
        children: [
          Text(
            'No accounts yet',
            style: LedgrType.serif(fontSize: 18, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first storage location to start tracking liquidity.',
            textAlign: TextAlign.center,
            style: LedgrType.sans(
              fontSize: 13,
              color: LedgrColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
