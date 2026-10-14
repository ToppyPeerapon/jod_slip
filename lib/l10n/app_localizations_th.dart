// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'จดสลิป';

  @override
  String get income => 'รายรับ';

  @override
  String get expense => 'รายจ่าย';

  @override
  String get balance => 'คงเหลือ';

  @override
  String get scanSlip => 'สแกนสลิป';

  @override
  String get pickFromPhotos => 'เลือกสลิปจากรูปภาพ';

  @override
  String get pickFromPhotosHint => 'เลือกได้หลายรูปพร้อมกัน';

  @override
  String get takePhoto => 'ถ่ายรูปสลิป';

  @override
  String get addManually => 'เพิ่มรายการเอง';

  @override
  String get noTransactions => 'ยังไม่มีรายการในเดือนนี้';

  @override
  String get noTransactionsHint =>
      'กด \"สแกนสลิป\" เพื่อเริ่มจดรายรับรายจ่ายจากสลิปโอนเงิน';

  @override
  String get previousMonth => 'เดือนก่อน';

  @override
  String get nextMonth => 'เดือนถัดไป';

  @override
  String get settings => 'ตั้งค่า';

  @override
  String get ownerNames => 'ชื่อของฉัน';

  @override
  String get ownerNamesHint =>
      'ใช้แยกรายรับ/รายจ่ายอัตโนมัติ ถ้าผู้โอนในสลิปเป็นชื่อคุณจะเป็นรายจ่าย ถ้าผู้รับเป็นชื่อคุณจะเป็นรายรับ ใส่ได้ทั้งชื่อไทยและอังกฤษ';

  @override
  String get noOwnerNames => 'ยังไม่ได้ใส่ชื่อ สลิปทั้งหมดจะถูกนับเป็นรายจ่าย';

  @override
  String get addName => 'เพิ่มชื่อ';

  @override
  String get nameFieldLabel => 'ชื่อ-นามสกุล';

  @override
  String get language => 'ภาษา';

  @override
  String get reviewSlips => 'ตรวจสอบสลิป';

  @override
  String scanningProgress(int current, int total) {
    return 'กำลังอ่านสลิป $current/$total';
  }

  @override
  String saveAll(int count) {
    return 'บันทึก $count รายการ';
  }

  @override
  String savedCount(int count) {
    return 'บันทึกแล้ว $count รายการ';
  }

  @override
  String get statusDuplicate => 'สลิปนี้ถูกบันทึกไว้แล้ว';

  @override
  String get statusNeedsAmount => 'อ่านจำนวนเงินไม่ได้ แตะเพื่อกรอก';

  @override
  String get statusFailed => 'อ่านสลิปไม่สำเร็จ แตะเพื่อกรอกเอง';

  @override
  String get removeFromList => 'เอาออก';

  @override
  String get noDrafts => 'ไม่มีสลิปที่ต้องตรวจสอบ';

  @override
  String get amount => 'จำนวนเงิน';

  @override
  String get category => 'หมวดหมู่';

  @override
  String get date => 'วันที่';

  @override
  String get time => 'เวลา';

  @override
  String get paidTo => 'จ่ายให้';

  @override
  String get receivedFrom => 'รับจาก';

  @override
  String get note => 'บันทึกช่วยจำ';

  @override
  String get save => 'บันทึก';

  @override
  String get delete => 'ลบ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get deleteConfirm => 'ลบรายการนี้ใช่ไหม?';

  @override
  String get newTransaction => 'เพิ่มรายการ';

  @override
  String get editTransaction => 'แก้ไขรายการ';

  @override
  String get amountRequired => 'กรุณากรอกจำนวนเงินที่มากกว่า 0';

  @override
  String get slipImage => 'รูปสลิป';

  @override
  String get errorGeneric => 'เกิดข้อผิดพลาด กรุณาลองใหม่';

  @override
  String get pickImageFailed =>
      'เปิดรูปภาพไม่ได้ กรุณาอนุญาตการเข้าถึงรูปภาพในการตั้งค่า';

  @override
  String get categoryFood => 'อาหาร/เครื่องดื่ม';

  @override
  String get categoryTransport => 'เดินทาง';

  @override
  String get categoryShopping => 'ช้อปปิ้ง';

  @override
  String get categoryBills => 'บิล/ค่าน้ำค่าไฟ';

  @override
  String get categoryHousing => 'ที่พัก';

  @override
  String get categoryHealth => 'สุขภาพ';

  @override
  String get categoryEntertainment => 'บันเทิง';

  @override
  String get categoryEducation => 'การศึกษา';

  @override
  String get categoryTransferOut => 'โอนให้ผู้อื่น';

  @override
  String get categoryOtherExpense => 'อื่นๆ';

  @override
  String get categorySalary => 'เงินเดือน';

  @override
  String get categoryTransferIn => 'รับโอน';

  @override
  String get categorySales => 'ขายของ';

  @override
  String get categoryInvestment => 'การลงทุน';

  @override
  String get categoryOtherIncome => 'อื่นๆ';

  @override
  String get scanLibrary => 'ค้นหาสลิปจากรูปทั้งหมด';

  @override
  String get scanLibraryHint =>
      'ให้แอปไล่ดูรูปในเครื่อง แล้วเลือกเฉพาะสลิปมาให้';

  @override
  String get libraryRangeTitle => 'ค้นหาจากรูปช่วงไหน';

  @override
  String rangeSinceLast(String date) {
    return 'ตั้งแต่ค้นหาครั้งล่าสุด ($date)';
  }

  @override
  String get rangeLastMonth => '1 เดือนล่าสุด';

  @override
  String get rangeLast3Months => '3 เดือนล่าสุด';

  @override
  String get rangeAll => 'รูปทั้งหมด (อาจใช้เวลานาน)';

  @override
  String searchingProgress(int current, int total, int found) {
    return 'กำลังค้นหาสลิป $current/$total รูป · เจอ $found ใบ';
  }

  @override
  String skippedSaved(int count) {
    return 'ข้ามสลิปที่บันทึกไว้แล้ว $count ใบ';
  }

  @override
  String get noNewSlips => 'ไม่เจอสลิปใหม่';

  @override
  String get photoAccessTitle => 'ยังไม่ได้รับอนุญาตให้เข้าถึงรูปภาพ';

  @override
  String get photoAccessBody =>
      'เปิดการตั้งค่า แล้วอนุญาตให้จดสลิปเข้าถึงรูปภาพทั้งหมด เพื่อค้นหาสลิปในเครื่อง';

  @override
  String get openSettings => 'เปิดการตั้งค่า';

  @override
  String get photoAccessLimited => 'อนุญาตไว้บางรูป จะค้นหาเฉพาะรูปที่อนุญาต';
}
