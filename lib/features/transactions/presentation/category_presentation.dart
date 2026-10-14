import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/transaction_category.dart';

extension CategoryPresentation on TransactionCategory {
  String label(AppLocalizations l10n) => switch (this) {
    TransactionCategory.food => l10n.categoryFood,
    TransactionCategory.transport => l10n.categoryTransport,
    TransactionCategory.shopping => l10n.categoryShopping,
    TransactionCategory.bills => l10n.categoryBills,
    TransactionCategory.housing => l10n.categoryHousing,
    TransactionCategory.health => l10n.categoryHealth,
    TransactionCategory.entertainment => l10n.categoryEntertainment,
    TransactionCategory.education => l10n.categoryEducation,
    TransactionCategory.transferOut => l10n.categoryTransferOut,
    TransactionCategory.otherExpense => l10n.categoryOtherExpense,
    TransactionCategory.salary => l10n.categorySalary,
    TransactionCategory.transferIn => l10n.categoryTransferIn,
    TransactionCategory.sales => l10n.categorySales,
    TransactionCategory.investment => l10n.categoryInvestment,
    TransactionCategory.otherIncome => l10n.categoryOtherIncome,
  };

  IconData get icon => switch (this) {
    TransactionCategory.food => Icons.restaurant,
    TransactionCategory.transport => Icons.directions_bus,
    TransactionCategory.shopping => Icons.shopping_bag,
    TransactionCategory.bills => Icons.receipt_long,
    TransactionCategory.housing => Icons.home,
    TransactionCategory.health => Icons.medical_services,
    TransactionCategory.entertainment => Icons.movie,
    TransactionCategory.education => Icons.school,
    TransactionCategory.transferOut => Icons.north_east,
    TransactionCategory.otherExpense => Icons.more_horiz,
    TransactionCategory.salary => Icons.work,
    TransactionCategory.transferIn => Icons.south_west,
    TransactionCategory.sales => Icons.storefront,
    TransactionCategory.investment => Icons.trending_up,
    TransactionCategory.otherIncome => Icons.more_horiz,
  };
}
