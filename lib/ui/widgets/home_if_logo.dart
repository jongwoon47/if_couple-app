import 'package:flutter/material.dart';

/// PNG 없이 그리는 'if' 로고 (배경 없음 → 홈 그라데이션과 동화)
class HomeIfLogo extends StatelessWidget {
  const HomeIfLogo({
    super.key,
    this.height = 64,
  });

  final double height;

  /// 참고 이미지와 유사한 핑크 / 라벤더
  static const Color _pink = Color(0xFFE898AC);
  static const Color _lavender = Color(0xFFA68CC6);

  @override
  Widget build(BuildContext context) {
    final fontSize = height * 0.92;
    final base = TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: const <String>[
        'Times New Roman',
        'Noto Serif',
        'serif',
      ],
      fontSize: fontSize,
      height: 1.05,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      letterSpacing: -1,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('i', style: base.copyWith(color: _pink)),
        Transform.translate(
          offset: const Offset(-3, 0),
          child: Text('f', style: base.copyWith(color: _lavender)),
        ),
      ],
    );
  }
}
