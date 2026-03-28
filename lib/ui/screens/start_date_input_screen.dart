import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../services/couple_service.dart';
import '../widgets/onboarding_primary_button.dart';

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
    final l10n = AppLocalizations.of(context)!;
    if (_startDate == null) {
      setState(() {
        _error = l10n.startDateErrorNone;
      });
      return;
    }

    final coupleId = widget.appUser.coupleId;
    if (coupleId == null || coupleId.isEmpty) {
      setState(() {
        _error = l10n.startDateErrorNoCouple;
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

      // AppGate의 userStream이 users/{uid}.startDate 반영 후
      // 둘 다 HomeScreen으로 전환됨. (이 화면은 루트라 Navigator.pop 금지)
      if (!mounted) return;
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
    final l10n = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    final text = _startDate == null
        ? l10n.startDateScreenTitle
        : DateFormat.yMMMd(lc).format(_startDate!);

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
                    Text(
                      l10n.startDateQuestion,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6A6071),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.startDateSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF9A8EA8),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 프로필 설정(생일)과 동일: 연한 회색 테두리
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickDate,
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
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFFA796B3),
                              ),
                            ],
                          ),
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
                    OnboardingPrimaryButton(
                      label: _saving ? l10n.saving : l10n.done,
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

