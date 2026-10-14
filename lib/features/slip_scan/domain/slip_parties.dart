import '../../../core/institution/institution.dart';
import 'thai_date_parser.dart';

/// Sender/receiver names and the institution each side used.
class SlipParties {
  const SlipParties({this.senderName, this.receiverName, this.senderInstitution, this.receiverInstitution});

  final String? senderName;
  final String? receiverName;
  final Institution? senderInstitution;
  final Institution? receiverInstitution;

  /// Labelled slips ("จาก" / "ไปยัง") are read directly. Otherwise slips list
  /// the sender then the receiver in the "party zone" between the date and
  /// the amounts, each followed by detail lines (bank, account, wallet ID).
  static SlipParties find(List<String> lines) {
    final zone = _partyZone(lines);
    final candidates = _candidates(lines, zone);

    final sender = _findLabelled(lines, _fromLabel) ?? candidates.elementAtOrNull(0);
    final receiver =
        _findLabelled(lines, _toLabel) ?? candidates.where((c) => sender == null || c.line > sender.line).firstOrNull;

    return SlipParties(
      senderName: sender?.name,
      receiverName: receiver?.name,
      senderInstitution: sender == null ? null : _institutionIn(lines, sender.line, receiver?.line ?? zone.end),
      receiverInstitution: receiver == null ? null : _institutionIn(lines, receiver.line, zone.end),
    );
  }

  static final _fromLabel = RegExp(r'^\s*(จาก|from)\s*:?\s*(.*)$', caseSensitive: false);
  static final _toLabel = RegExp(r'^\s*(ไปยัง|ถึง|ไป|ผู้รับ|to)\s*:?\s*(.*)$', caseSensitive: false);

  /// Name prefixes (titles and company forms). "นางสาว" must precede "นาง".
  static const _titles =
      r'(นางสาว|นาง|นาย|น\.ส\.|ด\.ช\.|ด\.ญ\.|mrs\.?|mr\.?|ms\.?|miss|บจก\.?|บมจ\.?|หจก\.?|บริษัท|ร้าน)';

  /// A title at the start of any word: OCR often joins logo text (e.g. the
  /// PromptPay logo) onto the same row as the name.
  static final _titleAtWordStart = RegExp('(?:^|\\s)$_titles', caseSensitive: false);

  /// Lines that end the party zone: amounts, amount labels and fees.
  static final _zoneEnd = RegExp(
    r'(จำนวน|ยอดเงิน|ยอดโอน|ยอดชำระ|ค่าสินค้า|ค่าธรรมเนียม|amount|fee\b|\d\.\d{2}(?!\d))',
    caseSensitive: false,
  );

  /// Detail lines that are never a party name.
  static final _notAName = RegExp(
    r'(เลขที่รายการ|รหัสอ้างอิง|เลขที่อ้างอิง|รหัสรายการ|reference|ref\s*no|สำเร็จ|successful|\bid\b|wallet)',
    caseSensitive: false,
  );
  static final _accountNumber = RegExp(r'[xX\d*]{3}-[xX\d*]-[xX\d*]{4,5}-[xX\d*]');

  /// Thai consonants or Latin letters other than x (which masks digits).
  static final _letter = RegExp(r'[ก-ฮA-WYZa-wyz]');

  static ({int start, int end}) _partyZone(List<String> lines) {
    final dateLine = ThaiDateParser.lineIndex(lines);
    final start = dateLine == null ? 0 : dateLine + 1;
    var end = lines.length;
    for (var i = start; i < lines.length; i++) {
      if (_zoneEnd.hasMatch(lines[i])) {
        end = i;
        break;
      }
    }
    return (start: start, end: end);
  }

  static List<_Party> _candidates(List<String> lines, ({int start, int end}) zone) {
    return [
      for (var i = zone.start; i < zone.end; i++)
        if (_nameIn(lines[i]) case final name?) _Party(name, i),
    ];
  }

  /// The party name on [line], or null if it is a detail line.
  static String? _nameIn(String line) {
    final titled = _titleAtWordStart.firstMatch(line);
    if (titled != null) return _clean(line.substring(titled.start));
    if (_notAName.hasMatch(line) || Institution.detect(line) != null) return null;

    final cleaned = _clean(line);
    final letters = _letter.allMatches(cleaned).length;
    final digits = cleaned.replaceAll(RegExp(r'\D'), '').length;
    if (letters < 2 || digits * 2 >= cleaned.length) return null;
    return cleaned;
  }

  static _Party? _findLabelled(List<String> lines, RegExp label) {
    for (var i = 0; i < lines.length; i++) {
      final match = label.firstMatch(lines[i]);
      if (match == null) continue;

      if (_nameIn(match[2] ?? '') case final name?) return _Party(name, i);
      for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
        if (_nameIn(lines[j]) case final name?) return _Party(name, j);
      }
    }
    return null;
  }

  /// The institution mentioned in a party's own block of lines.
  static Institution? _institutionIn(List<String> lines, int from, int to) {
    final end = (to > from ? to : from + 3).clamp(from, lines.length);
    return Institution.detect(lines.sublist(from, end).join('\n'));
  }

  static String _clean(String text) => text.replaceAll(_accountNumber, '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _Party {
  const _Party(this.name, this.line);

  final String name;
  final int line;
}
