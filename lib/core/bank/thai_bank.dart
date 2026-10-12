/// Thai banks commonly seen on transfer slips.
///
/// [code] is the 3-digit Bank of Thailand institution code, which is also
/// what the slip mini-QR carries as the sending bank.
enum ThaiBank {
  kbank('004', 'กสิกรไทย', ['กสิกร', 'kasikorn', 'k plus', 'kbank', 'make by kbank']),
  scb('014', 'ไทยพาณิชย์', ['ไทยพาณิชย์', 'scb', 'siam commercial']),
  bbl('002', 'กรุงเทพ', ['ธนาคารกรุงเทพ', 'ธ.กรุงเทพ', 'bangkok bank', 'bualuang']),
  ktb('006', 'กรุงไทย', ['กรุงไทย', 'krungthai', 'krung thai', 'ktb']),
  bay('025', 'กรุงศรีอยุธยา', ['กรุงศรี', 'krungsri', 'ayudhya']),
  ttb('011', 'ทหารไทยธนชาต', ['ทหารไทยธนชาต', 'ทีทีบี', 'ttb']),
  gsb('030', 'ออมสิน', ['ออมสิน', 'gsb', 'mymo']),
  baac('034', 'ธ.ก.ส.', ['ธ.ก.ส', 'baac']),
  ghb('033', 'อาคารสงเคราะห์', ['อาคารสงเคราะห์', 'ghbank', 'ghb']),
  kkp('069', 'เกียรตินาคินภัทร', ['เกียรตินาคิน', 'kiatnakin', 'kkp']),
  cimb('022', 'ซีไอเอ็มบี ไทย', ['ซีไอเอ็มบี', 'cimb']),
  uob('024', 'ยูโอบี', ['ยูโอบี', 'uob']),
  tisco('067', 'ทิสโก้', ['ทิสโก้', 'tisco']),
  lhb('073', 'แลนด์ แอนด์ เฮ้าส์', ['แลนด์ แอนด์ เฮ้าส์', 'lh bank', 'lhbank']);

  const ThaiBank(this.code, this.thaiName, this.keywords);

  final String code;
  final String thaiName;

  /// Lower-case substrings that identify the bank in OCR text.
  final List<String> keywords;

  static ThaiBank? fromCode(String? code) {
    if (code == null) return null;
    for (final bank in values) {
      if (bank.code == code) return bank;
    }
    return null;
  }

  /// Returns the bank whose keyword appears earliest in [text].
  ///
  /// The issuing bank's branding is normally printed at the top of a slip,
  /// so the earliest match is the best guess for the sending bank.
  static ThaiBank? detect(String text) {
    final haystack = text.toLowerCase();
    ThaiBank? best;
    var bestIndex = -1;
    for (final bank in values) {
      for (final keyword in bank.keywords) {
        final index = haystack.indexOf(keyword);
        if (index >= 0 && (bestIndex < 0 || index < bestIndex)) {
          best = bank;
          bestIndex = index;
        }
      }
    }
    return best;
  }
}
