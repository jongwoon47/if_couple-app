import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/user_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.firebaseUser});

  final User firebaseUser;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  int _step = 0;
  DateTime? _birthday;
  String? _language;
  bool _saving = false;
  String? _error;

  static const List<String> _stepTitles = [
    '어떻게 불러드릴까요?',
    '생일이 언제인가요?',
    '주로 사용하는 언어는?',
  ];

  static const List<_LanguageOption> _languages = [
    _LanguageOption(value: 'Korean', label: '한국어'),
    _LanguageOption(value: 'Japanese', label: '일본어'),
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _isStepValid {
    switch (_step) {
      case 0:
        final nickname = _nicknameController.text.trim();
        return nickname.length >= 2 && nickname.length <= 10;
      case 1:
        return _birthday != null && _isAgeAtLeast14(_birthday!);
      case 2:
        return _language != null && _language!.isNotEmpty;
      default:
        return false;
    }
  }

  bool _isAgeAtLeast14(DateTime birthday) {
    final now = DateTime.now();
    var age = now.year - birthday.year;
    final birthdayThisYear = DateTime(now.year, birthday.month, birthday.day);
    if (now.isBefore(birthdayThisYear)) {
      age -= 1;
    }
    return age >= 14;
  }

  String _stepHintText() {
    switch (_step) {
      case 0:
        return '2~10자 이내로 입력해 주세요.';
      case 1:
        return '본인의 생일을 선택해 주세요.';
      case 2:
        return '주 언어를 선택하면 번역 기능 정확도가 올라가요.';
      default:
        return '';
    }
  }

  String _stepErrorText() {
    switch (_step) {
      case 0:
        return '닉네임을 2~10자로 입력해 주세요.';
      case 1:
        if (_birthday == null) {
          return '생일을 선택해 주세요.';
        }
        return '14세 이상만 가입할 수 있어요.';
      case 2:
        return '언어를 선택해 주세요.';
      default:
        return '입력값을 확인해 주세요.';
    }
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _onNext() async {
    if (_saving) return;

    if (!_isStepValid) {
      setState(() {
        _error = _stepErrorText();
      });
      return;
    }

    if (_step < 2) {
      setState(() {
        _error = null;
        _step += 1;
      });
      return;
    }

    await _submit();
  }

  void _onPrev() {
    if (_saving || _step == 0) return;
    setState(() {
      _step -= 1;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_birthday == null || _language == null) {
      setState(() {
        _error = '입력값을 다시 확인해 주세요.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await UserService.updateProfile(
        userId: widget.firebaseUser.uid,
        nickname: _nicknameController.text.trim(),
        birthday: _birthday!,
        language: _language!,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _NicknameStep(
          controller: _nicknameController,
          onChanged: (_) {
            setState(() {
              _error = null;
            });
          },
        );
      case 1:
        return _DateStep(
          value: _birthday,
          placeholder: '생일 선택',
          onTap: () => _pickDate(
            initialDate: _birthday,
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
            onSelected: (date) {
              setState(() {
                _birthday = date;
                _error = null;
              });
            },
          ),
        );
      case 2:
        return _LanguageStep(
          selected: _language,
          options: _languages,
          onChanged: (value) {
            setState(() {
              _language = value;
              _error = null;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _step == 2;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8EEF9), Color(0xFFF2E5F3)],
          ),
        ),
        child: CustomPaint(
          painter: _DotPatternPainter(),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      const _IfWordmark(),
                      const SizedBox(height: 48),
                      Text(
                        _stepTitles[_step],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6A6071),
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildStepContent(),
                      const SizedBox(height: 12),
                      Text(
                        _stepHintText(),
                        style: const TextStyle(
                          color: Color(0xFF9A8EA8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _ErrorBox(text: _error!),
                      ],
                      const Spacer(),
                      _PrimaryButton(
                        label: _saving
                            ? '저장 중...'
                            : (isLastStep ? '완료' : '다음'),
                        enabled: _isStepValid && !_saving,
                        onTap: _onNext,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: _step == 0
                            ? null
                            : TextButton(
                                onPressed: _onPrev,
                                child: const Text(
                                  '이전',
                                  style: TextStyle(
                                    color: Color(0xFF9B8FB0),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      _StepOrderIndicator(currentStep: _step),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IfWordmark extends StatelessWidget {
  const _IfWordmark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'i',
              style: TextStyle(
                color: Color(0xFFE8B9D4),
                fontSize: 70,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia',
              ),
            ),
            TextSpan(
              text: 'f',
              style: TextStyle(
                color: Color(0xFFCCB7EC),
                fontSize: 70,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NicknameStep extends StatelessWidget {
  const _NicknameStep({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: 10,
      decoration: InputDecoration(
        counterText: '',
        hintText: '닉네임 입력',
        hintStyle: const TextStyle(color: Color(0xFFB3A4C0)),
        filled: true,
        fillColor: const Color(0xFFF8F1FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5CFE2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5CFE2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE48EB8), width: 1.2),
        ),
      ),
    );
  }
}

class _DateStep extends StatelessWidget {
  const _DateStep({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final DateTime? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? placeholder : DateFormat('yyyy-MM-dd').format(value!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F1FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF6A6071),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF9C8CA8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: value == null ? const Color(0xFFB3A4C0) : const Color(0xFF5C516A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFA796B3)),
          ],
        ),
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String? selected;
  final List<_LanguageOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options) ...[
          InkWell(
            onTap: () => onChanged(option.value),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: selected == option.value
                    ? const Color(0xFFF2C4DF)
                    : const Color(0xFFF8F1FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected == option.value
                      ? const Color(0xFF6A6071)
                      : const Color(0xFFB7A7C5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: selected == option.value
                        ? const Color(0xFF4B3A5A)
                        : const Color(0xFF6D6179),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFFF4B8D9), Color(0xFFE882BE)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFE0DBE5), Color(0xFFCFC8D8)],
                ),
          border: Border.all(
            color: enabled ? const Color(0xFFE07FB8) : const Color(0xFFC3BACD),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              // 형식에 맞을 때(활성)에는 흰색이 아닌 색,
              // 형식에 맞지 않을 때(비활성)에는 흰색으로 표시
              color: enabled ? const Color(0xFF8E829C) : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEFF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7D3DF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC25A7B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFA14B65),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepOrderIndicator extends StatelessWidget {
  const _StepOrderIndicator({required this.currentStep});

  final int currentStep;

  static const labels = ['닉네임', '생일', '언어'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(labels.length, (index) {
            final active = index == currentStep;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFE38DB8) : const Color(0xFFD9C8E8),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          labels.join('  ·  '),
          style: const TextStyle(
            color: Color(0xFFA799B4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    const radius = 1.2;
    final paint = Paint()..color = const Color(0x14A584B6);

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LanguageOption {
  const _LanguageOption({required this.value, required this.label});

  final String value;
  final String label;
}
