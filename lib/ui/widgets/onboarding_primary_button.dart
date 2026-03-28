import 'package:flutter/material.dart';

/// 회원가입/온보딩 공통: 형식이 맞을 때(enabled) 진한 검정 계열, 아니면 연한 회색.
class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.height = 58,
    this.borderRadius = 18,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: enabled
          ? const LinearGradient(
              colors: [Color(0xFF3A3340), Color(0xFF1E1A24)],
            )
          : const LinearGradient(
              colors: [Color(0xFFE8E3ED), Color(0xFFDDD6E5)],
            ),
      border: Border.all(
        color: enabled ? const Color(0xFF1A1620) : const Color(0xFFCDC4D6),
      ),
      boxShadow: enabled
          ? const [
              BoxShadow(
                color: Color(0x33211B2A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ]
          : null,
    );

    // Ink는 웹에서 부모 Material 없으면 배경이 안 보이는 경우가 있어
    // Container + Material로 그라데이션이 항상 그려지게 함
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: decoration,
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : const Color(0xFFB0A6BA),
              fontSize: height >= 56 ? 20 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
