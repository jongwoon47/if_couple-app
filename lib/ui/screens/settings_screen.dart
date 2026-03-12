import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/couple_service.dart';
import '../../services/user_service.dart';
import 'app_info_screen.dart';
import 'notification_settings_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.appUser,
  });

  final AppUser appUser;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _disconnecting = false;

  int _dDay(DateTime startDate) {
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return currentDate.difference(start).inDays + 1;
  }

  Future<void> _confirmDisconnect(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF6FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '정말 연결을 해제하시겠어요?',
            style: TextStyle(
              color: Color(0xFF7F5C7C),
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            '연결을 해제하면 D+ 일수, 채팅 대화, 추억 데이터가 '
            '더 이상 동기화되지 않습니다.',
            style: TextStyle(
              color: Color(0xFF8F7B97),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE77FB6),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('연결 해제'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true || _disconnecting) return;

    setState(() {
      _disconnecting = true;
    });

    try {
      await CoupleService.disconnectCouple(currentUserUid: user.userId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', '').trim(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _disconnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: UserService.userStream(widget.appUser.userId),
      builder: (context, snapshot) {
        final user = snapshot.data ?? widget.appUser;
        final dDay = _dDay(user.startDate ?? DateTime.now());

        return Scaffold(
          appBar: AppBar(
            title: const Text('설정'),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EFFA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE6D8EA)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 34,
                              backgroundColor: Color(0xFFEBCFE3),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFE184BA),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user.nickname}  ♥  ${user.partnerNickname.trim().isEmpty ? '연인' : user.partnerNickname}',
                                    style: const TextStyle(
                                      color: Color(0xFF6F5C7C),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.statusMessage.isEmpty
                                        ? '서로의 일상을 함께 채워요.'
                                        : user.statusMessage,
                                    style: const TextStyle(
                                      color: Color(0xFF9A86A8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF8FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE6D8EA)),
                          ),
                          child: Text(
                            'D+$dDay',
                            style: const TextStyle(
                              color: Color(0xFF9C6B98),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsItem(
                    icon: Icons.edit_rounded,
                    title: '프로필 편집',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileEditScreen(appUser: user),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsItem(
                    icon: Icons.notifications_active_rounded,
                    title: '알림 설정',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NotificationSettingsScreen(appUser: user),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsItem(
                    icon: Icons.heart_broken_rounded,
                    title: _disconnecting ? '연결 해제 중...' : '연결 해제',
                    danger: true,
                    onTap: _disconnecting || (user.coupleId?.isEmpty ?? true)
                        ? null
                        : () => _confirmDisconnect(user),
                  ),
                  const SizedBox(height: 10),
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    title: '앱 정보',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AppInfoScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.danger = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? const Color(0xFFB85A84) : const Color(0xFF72607F);

    return Material(
      color: const Color(0xFFF7EFFA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: onTap == null ? 0.55 : 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6D8EA)),
            ),
            child: Row(
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFB39DC0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
