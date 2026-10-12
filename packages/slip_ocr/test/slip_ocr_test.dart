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
}
