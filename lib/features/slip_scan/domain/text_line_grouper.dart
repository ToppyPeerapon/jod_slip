import 'dart:math' as math;

/// A piece of recognised text with a normalised (0..1, top-left origin)
/// bounding box.
class OcrBlock {
  const OcrBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  double get centerY => top + height / 2;
}

/// Joins OCR blocks that sit on the same visual row into one line.
///
/// Slips often print a label and its value in separate columns
/// ("จำนวน:" ... "1,500.00 บาท"); OCR returns them as separate blocks, but
/// the parser needs them on one line to pair them up.
List<String> groupIntoLines(List<OcrBlock> blocks) {
  final sorted = [...blocks]..sort((a, b) => a.centerY.compareTo(b.centerY));
  final rows = <List<OcrBlock>>[];

  for (final block in sorted) {
    if (rows.isNotEmpty && _isSameRow(rows.last.first, block)) {
      rows.last.add(block);
    } else {
      rows.add([block]);
    }
  }

  return [
    for (final row in rows)
      ([...row]..sort((a, b) => a.left.compareTo(b.left)))
          .map((b) => b.text.trim())
          .where((t) => t.isNotEmpty)
          .join('  '),
  ].where((line) => line.isNotEmpty).toList(growable: false);
}

bool _isSameRow(OcrBlock anchor, OcrBlock candidate) {
  final tolerance = math.min(anchor.height, candidate.height) * 0.5;
  return (candidate.centerY - anchor.centerY).abs() <= tolerance;
}
