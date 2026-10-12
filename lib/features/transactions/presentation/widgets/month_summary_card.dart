import 'package:flutter/material.dart';

import '../../../../core/formatting/thai_format.dart';
import '../../../../core/theme/money_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/month_summary.dart';

class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({super.key, required this.summary, required this.format});

  final MonthSummary summary;
  final AppFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.balance, style: text.labelLarge),
            const SizedBox(height: 4),
            Text(
              format.baht(summary.balanceSatang),
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: l10n.income,
                    value: format.baht(summary.incomeSatang),
                    color: colors.income,
                    icon: Icons.south_west,
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: l10n.expense,
                    value: format.baht(summary.expenseSatang),
                    color: colors.expense,
                    icon: Icons.north_east,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.color, required this.icon});

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelMedium),
              Text(
                value,
                style: text.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
