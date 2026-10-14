import '../../../core/institution/institution.dart';
import 'transaction_category.dart';

enum TransactionType { income, expense }

/// An income or expense entry. Immutable; use [copyWith] to change it.
class MoneyTransaction {
  const MoneyTransaction({
    this.id,
    required this.type,
    required this.amountSatang,
    required this.category,
    required this.occurredAt,
    required this.createdAt,
    this.note = '',
    this.counterparty,
    this.bankCode,
    this.reference,
    this.slipImage,
    this.counterpartyInstitution,
  });

  final int? id;
  final TransactionType type;

  /// Amount in satang (1 baht = 100 satang), always positive.
  final int amountSatang;
  final TransactionCategory category;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String note;

  /// The other party: receiver for expenses, sender for income.
  final String? counterparty;
  final String? bankCode;

  /// Slip transaction reference; unique, used to block duplicate imports.
  final String? reference;

  /// File name of the saved slip image inside the app's slip directory.
  final String? slipImage;

  /// The other party's bank, PromptPay or wallet; drives the list icon.
  final Institution? counterpartyInstitution;

  int get signedSatang => type == TransactionType.income ? amountSatang : -amountSatang;

  MoneyTransaction copyWith({
    int? id,
    TransactionType? type,
    int? amountSatang,
    TransactionCategory? category,
    DateTime? occurredAt,
    DateTime? createdAt,
    String? note,
    String? Function()? counterparty,
    String? Function()? bankCode,
    String? Function()? reference,
    String? Function()? slipImage,
    Institution? Function()? counterpartyInstitution,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amountSatang: amountSatang ?? this.amountSatang,
      category: category ?? this.category,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      counterparty: counterparty != null ? counterparty() : this.counterparty,
      bankCode: bankCode != null ? bankCode() : this.bankCode,
      reference: reference != null ? reference() : this.reference,
      slipImage: slipImage != null ? slipImage() : this.slipImage,
      counterpartyInstitution:
          counterpartyInstitution != null ? counterpartyInstitution() : this.counterpartyInstitution,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'type': type.name,
        'amount_satang': amountSatang,
        'category': category.key,
        'occurred_at': occurredAt.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'note': note,
        'counterparty': counterparty,
        'bank_code': bankCode,
        'reference': reference,
        'slip_image': slipImage,
        'counterparty_institution': counterpartyInstitution?.key,
      };

  factory MoneyTransaction.fromMap(Map<String, Object?> map) {
    final type = TransactionType.values.byName(map['type']! as String);
    return MoneyTransaction(
      id: map['id'] as int?,
      type: type,
      amountSatang: map['amount_satang']! as int,
      category: TransactionCategory.fromKey(map['category']! as String, type),
      occurredAt: DateTime.fromMillisecondsSinceEpoch(map['occurred_at']! as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      note: (map['note'] as String?) ?? '',
      counterparty: map['counterparty'] as String?,
      bankCode: map['bank_code'] as String?,
      reference: map['reference'] as String?,
      slipImage: map['slip_image'] as String?,
      counterpartyInstitution: Institution.fromKey(map['counterparty_institution'] as String?),
    );
  }
}
