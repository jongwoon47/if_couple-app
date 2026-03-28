import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/user_service.dart';
import '../widgets/onboarding_primary_button.dart';

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

  @override
  void initState() {
    super.initState();
    // 웹·한글 IME 등에서 onChanged만으로는 rebuild가 빠질 수 있어
    // 다음 버튼 enabled(검정) 갱신이 안 되는 경우가 있음 → 컨트롤러로 확실히 반영
    _nicknameController.addListener(_onNicknameChanged);
  }

  void _onNicknameChanged() {
    if (!mounted) return;
    setState(() {
      _error = null;
    });
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_onNicknameChanged);
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

  String _stepHintText(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return l10n.psNicknameLength;
      case 1:
        return l10n.psBirthdayPick;
      case 2:
        return l10n.psLanguageAccuracy;
      default:
        return '';
    }
  }

  String _stepErrorText(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return l10n.psNicknameError;
      case 1:
        if (_birthday == null) {
          return l10n.psBirthdaySelect;
        }
        return l10n.psAgeError;
      case 2:
        return l10n.psLanguageSelect;
      default:
        return l10n.psInputError;
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
        _error = _stepErrorText(AppLocalizations.of(context)!);
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
    final l10n = AppLocalizations.of(context)!;
    if (_birthday == null || _language == null) {
      setState(() {
        _error = l10n.psConfirmError;
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

  Widget _buildStepContent(
    AppLocalizations l10n,
    List<_LanguageOption> langOptions,
  ) {
    switch (_step) {
      case 0:
        return _NicknameStep(
          controller: _nicknameController,
          hintText: l10n.psNicknameHint,
          onChanged: (_) {},
        );
      case 1:
        return _DateStep(
          value: _birthday,
          placeholder: l10n.psBirthdayPlaceholder,
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
          options: langOptions,
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
    final l10n = AppLocalizations.of(context)!;
    final isLastStep = _step == 2;
    final stepTitles = [
      l10n.psNicknameQuestion,
      l10n.psBirthdayQuestion,
      l10n.psLanguageQuestion,
    ];
    final langOptions = [
      _LanguageOption(value: 'Korean', label: l10n.psLangKorean),
      _LanguageOption(value: 'Japanese', label: l10n.psLangJapanese),
    ];
    final stepLabels = [
      l10n.psFieldNickname,
      l10n.psFieldBirthday,
      l10n.psFieldLanguage,
    ];

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
                        stepTitles[_step],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6A6071),
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildStepContent(l10n, langOptions),
                      const SizedBox(height: 12),
                      Text(
                        _stepHintText(l10n),
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
                      OnboardingPrimaryButton(
                        label: _saving
                            ? l10n.saving
                            : (isLastStep ? l10n.done : l10n.psNext),
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
                                child: Text(
                                  l10n.psPrevious,
                                  style: const TextStyle(
                                    color: Color(0xFF9B8FB0),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      _StepOrderIndicator(
                        currentStep: _step,
                        labels: stepLabels,
                      ),
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
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: 10,
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
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
    final lc = Localizations.localeOf(context).languageCode;
    final text = value == null
        ? placeholder
        : DateFormat.yMMMd(lc).format(value!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBFE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD8D4DE),
              width: 1.2,
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(option.value),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: selected == option.value
                      ? const Color(0xFFFFE8F2)
                      : const Color(0xFFFDFBFE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected == option.value
                        ? const Color(0xFFE98ABF)
                        : const Color(0xFFD8D4DE),
                    width: selected == option.value ? 2 : 1.2,
                  ),
                  boxShadow: selected == option.value
                      ? const [
                          BoxShadow(
                            color: Color(0x332A1A33),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: selected == option.value
                              ? const Color(0xFF5C2D4A)
                              : const Color(0xFF6D6179),
                          fontSize: 17,
                          fontWeight:
                              selected == option.value ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected == option.value)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFFE98ABF),
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
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
  const _StepOrderIndicator({
    required this.currentStep,
    required this.labels,
  });

  final int currentStep;
  final List<String> labels;

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
