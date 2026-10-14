import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slip_ocr/slip_ocr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('slip_ocr');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('recognize decodes blocks and barcodes from the platform', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return {
        'blocks': [
          {'text': 'จำนวน', 'left': 0.1, 'top': 0.5, 'width': 0.2, 'height': 0.03},
        ],
        'barcodes': ['0041000600000101030040220014242082547BPM04988'],
      };
    });

    final result = await const SlipOcr().recognize('/tmp/slip.jpg');

    expect(received?.method, 'recognize');
    expect(received?.arguments, {'path': '/tmp/slip.jpg'});
    expect(result.blocks.single.text, 'จำนวน');
    expect(result.blocks.single.top, 0.5);
    expect(result.barcodes, ['0041000600000101030040220014242082547BPM04988']);
  });

  test('recognize surfaces platform errors', () {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'recognition_failed'),
    );

    expect(() => const SlipOcr().recognize('/missing.jpg'), throwsA(isA<PlatformException>()));
  });

  test('requestPhotoAccess maps the native status', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => 'limited');
    expect(await const SlipOcr().requestPhotoAccess(), PhotoAccess.limited);

    messenger.setMockMethodCallHandler(channel, (call) async => 'something-new');
    expect(await const SlipOcr().requestPhotoAccess(), PhotoAccess.denied);
  });

  test('listImageAssets passes the since date and decodes assets', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return [
        {'id': 'A/L0/001', 'createdMs': DateTime(2026, 10, 12).millisecondsSinceEpoch},
      ];
    });

    final assets = await const SlipOcr().listImageAssets(since: DateTime(2026, 10, 1));

    expect(received?.arguments, {'sinceMs': DateTime(2026, 10, 1).millisecondsSinceEpoch});
    expect(assets.single.id, 'A/L0/001');
    expect(assets.single.createdAt, DateTime(2026, 10, 12));
  });

  test('quickScanAsset and exportAsset send the asset id', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'exportAsset' ? '/tmp/library_1.jpg' : {'blocks': [], 'barcodes': ['QR']};
    });

    final quick = await const SlipOcr().quickScanAsset('A/L0/001');
    final path = await const SlipOcr().exportAsset('A/L0/001');

    expect(quick.barcodes, ['QR']);
    expect(path, '/tmp/library_1.jpg');
    expect(calls.map((c) => c.method), ['quickScanAsset', 'exportAsset']);
    expect(calls.map((c) => c.arguments), everyElement({'id': 'A/L0/001'}));
  });
}
