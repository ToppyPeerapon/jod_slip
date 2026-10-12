import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In th, this message translates to:
  /// **'จดสลิป'**
  String get appTitle;

  /// No description provided for @income.
  ///
  /// In th, this message translates to:
  /// **'รายรับ'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In th, this message translates to:
  /// **'รายจ่าย'**
  String get expense;

  /// No description provided for @balance.
  ///
  /// In th, this message translates to:
  /// **'คงเหลือ'**
  String get balance;

  /// No description provided for @scanSlip.
  ///
  /// In th, this message translates to:
  /// **'สแกนสลิป'**
  String get scanSlip;

  /// No description provided for @pickFromPhotos.
  ///
  /// In th, this message translates to:
  /// **'เลือกสลิปจากรูปภาพ'**
  String get pickFromPhotos;

  /// No description provided for @pickFromPhotosHint.
  ///
  /// In th, this message translates to:
  /// **'เลือกได้หลายรูปพร้อมกัน'**
  String get pickFromPhotosHint;

  /// No description provided for @takePhoto.
  ///
  /// In th, this message translates to:
  /// **'ถ่ายรูปสลิป'**
  String get takePhoto;

  /// No description provided for @addManually.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มรายการเอง'**
  String get addManually;

  /// No description provided for @noTransactions.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายการในเดือนนี้'**
  String get noTransactions;

  /// No description provided for @noTransactionsHint.
  ///
  /// In th, this message translates to:
  /// **'กด \"สแกนสลิป\" เพื่อเริ่มจดรายรับรายจ่ายจากสลิปโอนเงิน'**
  String get noTransactionsHint;

  /// No description provided for @previousMonth.
  ///
  /// In th, this message translates to:
  /// **'เดือนก่อน'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In th, this message translates to:
  /// **'เดือนถัดไป'**
  String get nextMonth;

  /// No description provided for @settings.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่า'**
  String get settings;

  /// No description provided for @ownerNames.
  ///
  /// In th, this message translates to:
  /// **'ชื่อของฉัน'**
  String get ownerNames;

  /// No description provided for @ownerNamesHint.
  ///
  /// In th, this message translates to:
  /// **'ใช้แยกรายรับ/รายจ่ายอัตโนมัติ ถ้าผู้โอนในสลิปเป็นชื่อคุณจะเป็นรายจ่าย ถ้าผู้รับเป็นชื่อคุณจะเป็นรายรับ ใส่ได้ทั้งชื่อไทยและอังกฤษ'**
  String get ownerNamesHint;

  /// No description provided for @noOwnerNames.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ได้ใส่ชื่อ สลิปทั้งหมดจะถูกนับเป็นรายจ่าย'**
  String get noOwnerNames;

  /// No description provided for @addName.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มชื่อ'**
  String get addName;

  /// No description provided for @nameFieldLabel.
  ///
  /// In th, this message translates to:
  /// **'ชื่อ-นามสกุล'**
  String get nameFieldLabel;

  /// No description provided for @language.
  ///
  /// In th, this message translates to:
  /// **'ภาษา'**
  String get language;

  /// No description provided for @reviewSlips.
  ///
  /// In th, this message translates to:
  /// **'ตรวจสอบสลิป'**
  String get reviewSlips;

  /// No description provided for @scanningProgress.
  ///
  /// In th, this message translates to:
  /// **'กำลังอ่านสลิป {current}/{total}'**
  String scanningProgress(int current, int total);

  /// No description provided for @saveAll.
  ///
  /// In th, this message translates to:
  /// **'บันทึก {count} รายการ'**
  String saveAll(int count);

  /// No description provided for @savedCount.
  ///
  /// In th, this message translates to:
  /// **'บันทึกแล้ว {count} รายการ'**
  String savedCount(int count);

  /// No description provided for @statusDuplicate.
  ///
  /// In th, this message translates to:
  /// **'สลิปนี้ถูกบันทึกไว้แล้ว'**
  String get statusDuplicate;

  /// No description provided for @statusNeedsAmount.
  ///
  /// In th, this message translates to:
  /// **'อ่านจำนวนเงินไม่ได้ แตะเพื่อกรอก'**
  String get statusNeedsAmount;

  /// No description provided for @statusFailed.
  ///
  /// In th, this message translates to:
  /// **'อ่านสลิปไม่สำเร็จ แตะเพื่อกรอกเอง'**
  String get statusFailed;

  /// No description provided for @removeFromList.
  ///
  /// In th, this message translates to:
  /// **'เอาออก'**
  String get removeFromList;

  /// No description provided for @noDrafts.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีสลิปที่ต้องตรวจสอบ'**
  String get noDrafts;

  /// No description provided for @amount.
  ///
  /// In th, this message translates to:
  /// **'จำนวนเงิน'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In th, this message translates to:
  /// **'หมวดหมู่'**
  String get category;

  /// No description provided for @date.
  ///
  /// In th, this message translates to:
  /// **'วันที่'**
  String get date;

  /// No description provided for @time.
  ///
  /// In th, this message translates to:
  /// **'เวลา'**
  String get time;

  /// No description provided for @paidTo.
  ///
  /// In th, this message translates to:
  /// **'จ่ายให้'**
  String get paidTo;

  /// No description provided for @receivedFrom.
  ///
  /// In th, this message translates to:
  /// **'รับจาก'**
  String get receivedFrom;

  /// No description provided for @note.
  ///
  /// In th, this message translates to:
  /// **'บันทึกช่วยจำ'**
  String get note;

  /// No description provided for @save.
  ///
  /// In th, this message translates to:
  /// **'บันทึก'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In th, this message translates to:
  /// **'ลบ'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิก'**
  String get cancel;

  /// No description provided for @deleteConfirm.
  ///
  /// In th, this message translates to:
  /// **'ลบรายการนี้ใช่ไหม?'**
  String get deleteConfirm;

  /// No description provided for @newTransaction.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มรายการ'**
  String get newTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขรายการ'**
  String get editTransaction;

  /// No description provided for @amountRequired.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกจำนวนเงินที่มากกว่า 0'**
  String get amountRequired;

  /// No description provided for @slipImage.
  ///
  /// In th, this message translates to:
  /// **'รูปสลิป'**
  String get slipImage;

  /// No description provided for @errorGeneric.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาด กรุณาลองใหม่'**
  String get errorGeneric;

  /// No description provided for @pickImageFailed.
  ///
  /// In th, this message translates to:
  /// **'เปิดรูปภาพไม่ได้ กรุณาอนุญาตการเข้าถึงรูปภาพในการตั้งค่า'**
  String get pickImageFailed;

  /// No description provided for @categoryFood.
  ///
  /// In th, this message translates to:
  /// **'อาหาร/เครื่องดื่ม'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In th, this message translates to:
  /// **'เดินทาง'**
  String get categoryTransport;

  /// No description provided for @categoryShopping.
  ///
  /// In th, this message translates to:
  /// **'ช้อปปิ้ง'**
  String get categoryShopping;

  /// No description provided for @categoryBills.
  ///
  /// In th, this message translates to:
  /// **'บิล/ค่าน้ำค่าไฟ'**
  String get categoryBills;

  /// No description provided for @categoryHousing.
  ///
  /// In th, this message translates to:
  /// **'ที่พัก'**
  String get categoryHousing;

  /// No description provided for @categoryHealth.
  ///
  /// In th, this message translates to:
  /// **'สุขภาพ'**
  String get categoryHealth;

  /// No description provided for @categoryEntertainment.
  ///
  /// In th, this message translates to:
  /// **'บันเทิง'**
  String get categoryEntertainment;

  /// No description provided for @categoryEducation.
  ///
  /// In th, this message translates to:
  /// **'การศึกษา'**
  String get categoryEducation;

  /// No description provided for @categoryTransferOut.
  ///
  /// In th, this message translates to:
  /// **'โอนให้ผู้อื่น'**
  String get categoryTransferOut;

  /// No description provided for @categoryOtherExpense.
  ///
  /// In th, this message translates to:
  /// **'อื่นๆ'**
  String get categoryOtherExpense;

  /// No description provided for @categorySalary.
  ///
  /// In th, this message translates to:
  /// **'เงินเดือน'**
  String get categorySalary;

  /// No description provided for @categoryTransferIn.
  ///
  /// In th, this message translates to:
  /// **'รับโอน'**
  String get categoryTransferIn;

  /// No description provided for @categorySales.
  ///
  /// In th, this message translates to:
  /// **'ขายของ'**
  String get categorySales;

  /// No description provided for @categoryInvestment.
  ///
  /// In th, this message translates to:
  /// **'การลงทุน'**
  String get categoryInvestment;

  /// No description provided for @categoryOtherIncome.
  ///
  /// In th, this message translates to:
  /// **'อื่นๆ'**
  String get categoryOtherIncome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
