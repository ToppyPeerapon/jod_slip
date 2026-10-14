import 'package:flutter/material.dart';

import '../../../../core/formatting/thai_format.dart';
import '../../../../core/institution/institution.dart';
import '../../../../core/institution/institution_avatar.dart';
import '../../../../core/theme/money_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/money_transaction.dart';
import '../category_presentation.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, required this.format, this.onTap});

  final MoneyTransaction transaction;
  final AppFormat format;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final color = colors.forType(transaction.type);
    final subtitle = [
      format.time(transaction.occurredAt),
      if (transaction.counterparty case final name? when name.isNotEmpty) name,
      if (transaction.note.isNotEmpty) transaction.note,
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      leading: switch (transaction.counterpartyInstitution) {
        final institution? => _InstitutionIcon(institution: institution, type: transaction.type),
        null => CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(transaction.category.icon, size: 20),
        ),
      },
      title: Text(transaction.category.label(l10n)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (transaction.slipImage != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.receipt, size: 16, color: colors.outline),
            ),
          Text(
            format.baht(transaction.signedSatang, signed: true),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// The other party's institution, with a small in/out arrow badge.
class _InstitutionIcon extends StatelessWidget {
  const _InstitutionIcon({required this.institution, required this.type});

  final Institution institution;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 44,
      child: Stack(
        children: [
          InstitutionAvatar(institution: institution, size: 40),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colors.forType(type),
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 1.5),
              ),
              child: Icon(
                type == TransactionType.income ? Icons.south_west : Icons.north_east,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
