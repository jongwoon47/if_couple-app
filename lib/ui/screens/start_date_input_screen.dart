import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../services/couple_service.dart';

class StartDateInputScreen extends StatefulWidget {
  const StartDateInputScreen({super.key, required this.appUser});

  final AppUser appUser;

  @override
  State<StartDateInputScreen> createState() => _StartDateInputScreenState();
}

class _StartDateInputScreenState extends State<StartDateInputScreen> {
  DateTime? _startDate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDate = widget.appUser.startDate;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_startDate == null) {
      setState(() {
        _error = '처음만난날을 선택해 주세요.';
      });
      return;
    }

    final coupleId = widget.appUser.coupleId;
    if (coupleId == null || coupleId.isEmpty) {
      setState(() {
        _error = '커플 정보가 없어요. 다시 로그인해 주세요.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await CoupleService.updateCoupleStartDate(
        coupleId: coupleId,
        startDate: _startDate!,
        currentUserId: widget.appUser.userId,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _startDate == null
        ? '처음만난날 선택'
        : DateFormat('yyyy.MM.dd').format(_startDate!);

    final canSave = _startDate != null && !_saving;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8EEF9), Color(0xFFF2E5F3)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    const _IfWordmark(),
                    const SizedBox(height: 32),
                    const Text(
                      '처음만난날은 언제인가요?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6A6071),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '둘이 처음 만난 특별한 날을\n기념일로 기록해 둘게요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9A8EA8),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    InkWell(
                      onTap: _pickDate,
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
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: Color(0xFF9C8CA8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: _startDate == null
                                      ? const Color(0xFFB3A4C0)
                                      : const Color(0xFF5C516A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB45E86),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    _PrimaryButton(
                      label: _saving ? '저장 중...' : '완료',
                      enabled: canSave,
                      onTap: _save,
                    ),
                    const SizedBox(height: 20),
                  ],
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
                fontSize: 64,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia',
              ),
            ),
            TextSpan(
              text: 'f',
              style: TextStyle(
                color: Color(0xFFCCB7EC),
                fontSize: 64,
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

