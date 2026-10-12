import 'package:flutter/material.dart';

import '../../features/transactions/domain/money_transaction.dart';

/// Income is green and expense is red, adjusted for light/dark themes.
extension MoneyColors on ColorScheme {
  Color get income => brightness == Brightness.light ? const Color(0xFF1B8A5A) : const Color(0xFF6FD6A0);

  Color get expense => brightness == Brightness.light ? const Color(0xFFC62828) : const Color(0xFFFF8A80);

  Color forType(TransactionType type) => type == TransactionType.income ? income : expense;
}
