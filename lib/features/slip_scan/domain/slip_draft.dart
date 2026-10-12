import '../../transactions/domain/money_transaction.dart';
import '../../transactions/domain/transaction_category.dart';
import 'slip_data.dart';
import 'transaction_type_resolver.dart';

enum DraftStatus {
  /// Ready to save.
  ready,

  /// OCR found no amount; the user must enter it.
  needsAmount,

  /// A transaction with the same slip reference already exists.
  duplicate,

  /// Recognition failed entirely.
  failed,
}

/// A scanned slip waiting for the user to confirm it.
class SlipDraft {
  const SlipDraft({
    required this.imagePath,
    required this.transaction,
    required this.status,
    this.errorMessage,
  });

  /// Builds a pre-filled transaction from what the parser found.
  factory SlipDraft.fromSlip({
    required String imagePath,
    required SlipData slip,
    required List<String> ownerNames,
    required bool isDuplicate,
    required DateTime now,
  }) {
    final type = resolveTransactionType(slip, ownerNames);
    final transaction = MoneyTransaction(
      type: type,
      amountSatang: slip.amountSatang ?? 0,
      category: TransactionCategory.defaultFor(type),
      occurredAt: slip.dateTime ?? now,
      createdAt: now,
      counterparty: type == TransactionType.expense ? slip.receiverName : slip.senderName,
      bankCode: slip.bank?.code,
      reference: slip.reference,
    );
    return SlipDraft(
      imagePath: imagePath,
      transaction: transaction,
      status: _statusFor(transaction, isDuplicate: isDuplicate),
    );
  }

  factory SlipDraft.failed({required String imagePath, required String error, required DateTime now}) {
    return SlipDraft(
      imagePath: imagePath,
      transaction: MoneyTransaction(
        type: TransactionType.expense,
        amountSatang: 0,
        category: TransactionCategory.defaultFor(TransactionType.expense),
        occurredAt: now,
        createdAt: now,
      ),
      status: DraftStatus.failed,
      errorMessage: error,
    );
  }

  /// Local path of the picked image (temporary until saved).
  final String imagePath;
  final MoneyTransaction transaction;
  final DraftStatus status;
  final String? errorMessage;

  bool get canSave => status == DraftStatus.ready;

  /// Returns a copy with the user's edits; a valid amount clears
  /// [DraftStatus.needsAmount] / [DraftStatus.failed].
  SlipDraft withTransaction(MoneyTransaction edited) {
    final isDuplicate = status == DraftStatus.duplicate && edited.reference == transaction.reference;
    return SlipDraft(
      imagePath: imagePath,
      transaction: edited,
      status: _statusFor(edited, isDuplicate: isDuplicate),
    );
  }

  static DraftStatus _statusFor(MoneyTransaction tx, {required bool isDuplicate}) {
    if (isDuplicate) return DraftStatus.duplicate;
    if (tx.amountSatang <= 0) return DraftStatus.needsAmount;
    return DraftStatus.ready;
  }
}
