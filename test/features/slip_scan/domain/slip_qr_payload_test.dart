import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/features/slip_scan/domain/slip_qr_payload.dart';

void main() {
  test('parses sending bank and transaction ref', () {
    final payload = SlipQrPayload.tryParse('0041000600000101030040220014242082547BPM049885102TH9104ABCD');

    expect(payload, isNotNull);
    expect(payload!.sendingBankCode, '004');
    expect(payload.transactionRef, '014242082547BPM04988');
  });

  test('returns null for a PromptPay payment QR', () {
    expect(
      SlipQrPayload.tryParse('00020101021129370016A000000677010111011300668123456785802TH530376463041234'),
      isNull,
    );
  });

  test('returns null for malformed input', () {
    expect(SlipQrPayload.tryParse('0099abc'), isNull);
    expect(SlipQrPayload.tryParse(''), isNull);
    expect(SlipQrPayload.tryParse('https://example.com'), isNull);
  });
}
