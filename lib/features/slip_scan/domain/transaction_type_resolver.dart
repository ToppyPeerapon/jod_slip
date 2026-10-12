import '../../transactions/domain/money_transaction.dart';
import 'slip_data.dart';

/// Decides whether a slip is money going out or coming in by matching the
/// user's own names against the slip's sender and receiver.
///
/// Banks often mask names ("นาย พีรพล ช***"), so a slip name matches when it
/// contains any meaningful word from one of the owner's names.
TransactionType resolveTransactionType(SlipData slip, List<String> ownerNames) {
  if (_matchesOwner(slip.senderName, ownerNames)) return TransactionType.expense;
  if (_matchesOwner(slip.receiverName, ownerNames)) return TransactionType.income;
  // Banking apps save slips for transfers the user made, so default to expense.
  return TransactionType.expense;
}

const _minTokenLength = 3;

final _titles = RegExp(
  r'^(นางสาว|นาง|นาย|น\.ส\.|mrs\.?|mr\.?|ms\.?|miss)\s*',
  caseSensitive: false,
);

bool _matchesOwner(String? slipName, List<String> ownerNames) {
  if (slipName == null || slipName.trim().isEmpty) return false;
  final haystack = _compact(slipName.trim().replaceFirst(_titles, ''));

  return ownerNames.any((owner) {
    final tokens = owner
        .trim()
        .replaceFirst(_titles, '')
        .split(RegExp(r'\s+'))
        .map(_compact)
        .where((t) => t.length >= _minTokenLength);
    return tokens.any(haystack.contains);
  });
}

String _compact(String text) => text.toLowerCase().replaceAll(RegExp(r'[\s.*]'), '');
