// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JodSlip';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get scanSlip => 'Scan slip';

  @override
  String get pickFromPhotos => 'Choose slips from Photos';

  @override
  String get pickFromPhotosHint => 'You can select several at once';

  @override
  String get takePhoto => 'Take a photo of a slip';

  @override
  String get addManually => 'Add manually';

  @override
  String get noTransactions => 'No transactions this month';

  @override
  String get noTransactionsHint =>
      'Tap \"Scan slip\" to start tracking income and expenses from transfer slips';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get settings => 'Settings';

  @override
  String get ownerNames => 'My names';

  @override
  String get ownerNamesHint =>
      'Used to sort slips automatically: if you are the sender it is an expense, if you are the receiver it is income. Thai and English names both work.';

  @override
  String get noOwnerNames => 'No names yet, so every slip counts as an expense';

  @override
  String get addName => 'Add name';

  @override
  String get nameFieldLabel => 'Full name';

  @override
  String get language => 'Language';

  @override
  String get reviewSlips => 'Review slips';

  @override
  String scanningProgress(int current, int total) {
    return 'Reading slip $current/$total';
  }

  @override
  String saveAll(int count) {
    return 'Save $count';
  }

  @override
  String savedCount(int count) {
    return 'Saved $count';
  }

  @override
  String get statusDuplicate => 'This slip is already saved';

  @override
  String get statusNeedsAmount => 'Couldn\'t read the amount, tap to enter it';

  @override
  String get statusFailed => 'Couldn\'t read this slip, tap to fill it in';

  @override
  String get removeFromList => 'Remove';

  @override
  String get noDrafts => 'No slips to review';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get paidTo => 'Paid to';

  @override
  String get receivedFrom => 'Received from';

  @override
  String get note => 'Note';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteConfirm => 'Delete this transaction?';

  @override
  String get newTransaction => 'New transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get amountRequired => 'Enter an amount greater than 0';

  @override
  String get slipImage => 'Slip image';

  @override
  String get errorGeneric => 'Something went wrong, please try again';

  @override
  String get pickImageFailed =>
      'Couldn\'t open Photos. Please allow photo access in Settings.';

  @override
  String get categoryFood => 'Food & drink';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryBills => 'Bills & utilities';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryTransferOut => 'Transfer out';

  @override
  String get categoryOtherExpense => 'Other';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryTransferIn => 'Transfer in';

  @override
  String get categorySales => 'Sales';

  @override
  String get categoryInvestment => 'Investment';

  @override
  String get categoryOtherIncome => 'Other';
}
