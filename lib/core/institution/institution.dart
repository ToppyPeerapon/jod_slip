enum InstitutionKind { bank, promptPay, wallet }

/// Where money comes from or goes to: a Thai bank, PromptPay, or an e-wallet.
///
/// [key] is stored in the database, so never rename an existing key.
/// [code] is the 3-digit Bank of Thailand institution code (banks only),
/// which the slip mini-QR carries as the sending bank.
enum Institution {
  kbank(
    'kbank',
    InstitutionKind.bank,
    'กสิกรไทย',
    'K',
    0xFF138F2D,
    code: '004',
    keywords: ['กสิกร', 'kasikorn', 'k plus', 'kbank', 'make by kbank'],
  ),
  scb(
    'scb',
    InstitutionKind.bank,
    'ไทยพาณิชย์',
    'SCB',
    0xFF4E2E7F,
    code: '014',
    keywords: ['ไทยพาณิชย์', 'scb', 'siam commercial'],
  ),
  bbl(
    'bbl',
    InstitutionKind.bank,
    'กรุงเทพ',
    'BBL',
    0xFF1E4598,
    code: '002',
    keywords: ['ธนาคารกรุงเทพ', 'ธ.กรุงเทพ', 'bangkok bank', 'bualuang'],
  ),
  ktb(
    'ktb',
    InstitutionKind.bank,
    'กรุงไทย',
    'KTB',
    0xFF1BA5E1,
    code: '006',
    keywords: ['กรุงไทย', 'krungthai', 'krung thai', 'ktb'],
  ),
  bay(
    'bay',
    InstitutionKind.bank,
    'กรุงศรีอยุธยา',
    'BAY',
    0xFFFEC43B,
    code: '025',
    keywords: ['กรุงศรี', 'krungsri', 'ayudhya'],
    darkLabel: true,
  ),
  ttb(
    'ttb',
    InstitutionKind.bank,
    'ทหารไทยธนชาต',
    'ttb',
    0xFF0050F0,
    code: '011',
    keywords: ['ทหารไทยธนชาต', 'ทีทีบี', 'ttb'],
  ),
  gsb('gsb', InstitutionKind.bank, 'ออมสิน', 'GSB', 0xFFEB198D, code: '030', keywords: ['ออมสิน', 'gsb', 'mymo']),
  baac('baac', InstitutionKind.bank, 'ธ.ก.ส.', 'ธกส', 0xFF4B7F32, code: '034', keywords: ['ธ.ก.ส', 'baac']),
  ghb(
    'ghb',
    InstitutionKind.bank,
    'อาคารสงเคราะห์',
    'GHB',
    0xFFF57D23,
    code: '033',
    keywords: ['อาคารสงเคราะห์', 'ghbank', 'ghb'],
  ),
  kkp(
    'kkp',
    InstitutionKind.bank,
    'เกียรตินาคินภัทร',
    'KKP',
    0xFF6F5BA7,
    code: '069',
    keywords: ['เกียรตินาคิน', 'kiatnakin', 'kkp'],
  ),
  cimb(
    'cimb',
    InstitutionKind.bank,
    'ซีไอเอ็มบี ไทย',
    'CIMB',
    0xFFE21B23,
    code: '022',
    keywords: ['ซีไอเอ็มบี', 'cimb'],
  ),
  uob('uob', InstitutionKind.bank, 'ยูโอบี', 'UOB', 0xFF0B3B8C, code: '024', keywords: ['ยูโอบี', 'uob']),
  tisco('tisco', InstitutionKind.bank, 'ทิสโก้', 'TISCO', 0xFF12549B, code: '067', keywords: ['ทิสโก้', 'tisco']),
  lhb(
    'lhb',
    InstitutionKind.bank,
    'แลนด์ แอนด์ เฮ้าส์',
    'LH',
    0xFF7A9E3B,
    code: '073',
    keywords: ['แลนด์ แอนด์ เฮ้าส์', 'lh bank', 'lhbank'],
  ),
  thaiCredit(
    'thai_credit',
    InstitutionKind.bank,
    'ไทยเครดิต',
    'TCR',
    0xFF1C4FD8,
    code: '071',
    keywords: ['ไทยเครดิต', 'thai credit'],
  ),
  promptPay(
    'promptpay',
    InstitutionKind.promptPay,
    'พร้อมเพย์',
    'PromptPay',
    0xFF1B3D6F,
    // "prompipay"/"promptpav" are common OCR misreads of the logo text.
    keywords: ['พร้อมเพย์', 'promptpay', 'prompt pay', 'prompipay', 'promptpav'],
  ),
  paotang(
    'paotang',
    InstitutionKind.wallet,
    'เป๋าตัง',
    'G',
    0xFF1E3A8A,
    keywords: ['เป๋าตัง', 'g-wallet', 'gwallet', 'paotang'],
  ),
  trueMoney(
    'truemoney',
    InstitutionKind.wallet,
    'ทรูมันนี่',
    'TMN',
    0xFFFF8300,
    keywords: ['ทรูมันนี่', 'truemoney', 'true money'],
  ),
  shopeePay(
    'shopeepay',
    InstitutionKind.wallet,
    'ShopeePay',
    'SPay',
    0xFFEE4D2D,
    keywords: ['shopeepay', 'ช้อปปี้เพย์'],
  );

  const Institution(
    this.key,
    this.kind,
    this.thaiName,
    this.shortLabel,
    this.brandColor, {
    this.code,
    required this.keywords,
    this.darkLabel = false,
  });

  final String key;
  final InstitutionKind kind;
  final String thaiName;

  /// Text shown on the generated badge when no logo asset is bundled.
  final String shortLabel;

  /// ARGB brand colour for the badge background.
  final int brandColor;

  /// Use dark text on the badge (for light brand colours).
  final bool darkLabel;
  final String? code;

  /// Lower-case substrings that identify the institution in OCR text.
  final List<String> keywords;

  /// Optional official logo; drop a PNG at this path to replace the badge.
  String get logoAsset => 'assets/institutions/$key.png';

  static Institution? fromKey(String? key) {
    for (final institution in values) {
      if (institution.key == key) return institution;
    }
    return null;
  }

  static Institution? fromCode(String? code) {
    if (code == null) return null;
    for (final institution in values) {
      if (institution.code == code) return institution;
    }
    return null;
  }

  /// Returns the institution whose keyword appears earliest in [text].
  static Institution? detect(String text) {
    final haystack = text.toLowerCase();
    Institution? best;
    var bestIndex = -1;
    for (final institution in values) {
      for (final keyword in institution.keywords) {
        final index = haystack.indexOf(keyword);
        if (index >= 0 && (bestIndex < 0 || index < bestIndex)) {
          best = institution;
          bestIndex = index;
        }
      }
    }
    return best;
  }
}
