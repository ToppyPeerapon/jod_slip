import 'package:flutter/material.dart';

import 'institution.dart';

/// Round icon for a bank, PromptPay or wallet.
///
/// Shows `assets/institutions/<key>.png` when bundled, otherwise a badge in
/// the institution's brand colour with its short label.
class InstitutionAvatar extends StatelessWidget {
  const InstitutionAvatar({super.key, required this.institution, this.size = 40});

  final Institution institution;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: institution.thaiName,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: Image.asset(
            institution.logoAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _Badge(institution: institution, size: size),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.institution, required this.size});

  final Institution institution;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = institution.shortLabel;
    final foreground = institution.darkLabel ? Colors.black87 : Colors.white;
    return ColoredBox(
      color: Color(institution.brandColor),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: FittedBox(
            child: Text(
              label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
          ),
        ),
      ),
    );
  }
}
