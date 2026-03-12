import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../services/couple_service.dart';
import '../../services/user_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.appUser,
  });

  final AppUser appUser;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  late DateTime _startDate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.appUser.nickname;
    _startDate = widget.appUser.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _nicknameController.text.trim().isNotEmpty &&
        _nicknameController.text.trim().length <= 10 &&
        !_saving;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final coupleId = widget.appUser.coupleId;
      if (coupleId != null && coupleId.isNotEmpty) {
        await CoupleService.updateCoupleStartDate(
          coupleId: coupleId,
          startDate: _startDate,
          currentUserId: widget.appUser.userId,
          forceUpdate: true,
        );
      }
      await UserService.updateSettingsProfile(
        userId: widget.appUser.userId,
        nickname: _nicknameController.text.trim(),
        startDate: _startDate,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(_saving ? '저장 중...' : '완료'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8EEF9), Color(0xFFF2E5F3)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EFFA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE6D8EA)),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 46,
                        backgroundColor: Color(0xFFEBCFE3),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 42,
                          color: Color(0xFFE183BA),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: '닉네임',
                        controller: _nicknameController,
                        maxLength: 10,
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      if (widget.appUser.partnerNickname.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text(
                              '연인 닉네임',
                              style: TextStyle(
                                color: Color(0xFF8A7998),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.appUser.partnerNickname,
                                style: const TextStyle(
                                  color: Color(0xFF6E5F7A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text(
                            '처음만난날',
                            style: TextStyle(
                              color: Color(0xFF8A7998),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _pickStartDate,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF8FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE6D8EA)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    DateFormat('yyyy.MM.dd').format(_startDate),
                                    style: const TextStyle(
                                      color: Color(0xFF6E5F7A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: Color(0xFFA994B5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB6577E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.maxLength,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFFDF8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6D8EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6D8EA)),
        ),
      ),
    );
  }
}
