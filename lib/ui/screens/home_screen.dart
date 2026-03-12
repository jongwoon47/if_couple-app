import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/chat_service.dart';
import '../../services/couple_service.dart';
import '../../services/user_service.dart';
import 'calendar_screen_v2.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.appUser});

  final AppUser appUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _syncPartnerNicknameIfNeeded();
  }

  Future<void> _syncPartnerNicknameIfNeeded() async {
    final user = widget.appUser;
    if (user.partnerNickname.trim().isNotEmpty || user.coupleId == null) return;
    await UserService.syncPartnerNicknameIfNeeded(
      userId: user.userId,
      coupleId: user.coupleId!,
      currentPartnerNickname: user.partnerNickname,
    );
  }

  int _dDay(DateTime startDate) {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    return normalizedNow.difference(normalizedStart).inDays + 1;
  }

  Future<void> _openChat(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(appUser: widget.appUser),
      ),
    );
  }

  Future<void> _openCalendar(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalendarScreen(appUser: widget.appUser),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(appUser: widget.appUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUser = widget.appUser;
    final coupleId = appUser.coupleId!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7E9F8), Color(0xFFEEDCF3)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<Couple?>(
            stream: CoupleService.coupleStream(coupleId),
            builder: (context, snapshot) {
              final couple = snapshot.data;
              final startDate = couple?.startDate ?? appUser.startDate ?? DateTime.now();
              final dDay = _dDay(startDate);
              final partnerId = couple != null
                  ? (couple.user1Id == appUser.userId ? couple.user2Id : couple.user1Id)
                  : null;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                      child: Column(
                        children: [
                          // if 로고 (assets/images/if_logo.png, 누끼한 PNG 권장)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Image.asset(
                              'assets/images/if_logo.png',
                              height: 56,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFFF6B9DA), Color(0xFFE981BE)],
                                ).createShader(bounds),
                                child: const Text(
                                  'if',
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w300,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: Color(0xFF8F7398),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(text: '${appUser.nickname}  '),
                                const TextSpan(
                                  text: '♥',
                                  style: TextStyle(
                                    color: Color(0xFFB89BB5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: '  ${appUser.partnerNickname.trim().isEmpty ? '연인' : appUser.partnerNickname}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'D+$dDay',
                            style: const TextStyle(
                              color: Color(0xFFD167A0),
                              fontSize: 68,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '우리가 함께한 시간',
                            style: TextStyle(
                              color: Color(0xFF8F7398),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F1FB),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFE4D4E9)),
                            ),
                            child: Text(
                              '${DateFormat('yyyy.MM.dd').format(startDate)} 시작',
                              style: const TextStyle(
                                color: Color(0xFFA08AA9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // 대화하러 가기 카드: 왼쪽 문구 + 오른쪽 "톡 시작하기" 버튼
                          Material(
                            color: const Color(0xFFF7EFFA),
                            borderRadius: BorderRadius.circular(26),
                            child: InkWell(
                              onTap: () => _openChat(context),
                              borderRadius: BorderRadius.circular(26),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                      color: const Color(0xFFE9D8ED)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      color: Color(0xFFE98ABF),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        '오늘 서로 인사했나요?',
                                        style: TextStyle(
                                          color: Color(0xFF755379),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Material(
                                      color: const Color(0xFFE98ABF),
                                      borderRadius: BorderRadius.circular(999),
                                      child: InkWell(
                                        onTap: () => _openChat(context),
                                        borderRadius: BorderRadius.circular(999),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 14),
                                          child: Text(
                                            '톡 시작하기',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  partnerId == null
                      ? _BottomTabBar(
                          onHomeTap: () {},
                          onChatTap: () => _openChat(context),
                          onCalendarTap: () => _openCalendar(context),
                          onSettingsTap: () => _openSettings(context),
                          chatUnreadCount: 0,
                        )
                      : StreamBuilder<int>(
                          stream: ChatService.unreadCountStream(
                            coupleId,
                            appUser.userId,
                            partnerId,
                          ),
                          builder: (context, countSnap) {
                            final count = countSnap.data ?? 0;
                            final badge = count > 0
                                ? (count > 99 ? '99+' : count.toString())
                                : null;
                            return _BottomTabBar(
                              onHomeTap: () {},
                              onChatTap: () => _openChat(context),
                              onCalendarTap: () => _openCalendar(context),
                              onSettingsTap: () => _openSettings(context),
                              chatUnreadCount: count,
                              chatBadge: badge,
                            );
                          },
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({
    required this.onHomeTap,
    required this.onChatTap,
    required this.onCalendarTap,
    required this.onSettingsTap,
    this.chatUnreadCount = 0,
    this.chatBadge,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onChatTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onSettingsTap;
  final int chatUnreadCount;
  final String? chatBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EAF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5D2EA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              icon: Icons.home_rounded,
              label: '홈',
              active: true,
              onTap: onHomeTap,
            ),
          ),
          const _TabDivider(),
          Expanded(
            child: _TabItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: '대화',
              badge: chatBadge,
              warm: true,
              onTap: onChatTap,
            ),
          ),
          const _TabDivider(),
          Expanded(
            child: _TabItem(
              icon: Icons.calendar_today_rounded,
              label: '캘린더',
              onTap: onCalendarTap,
            ),
          ),
          const _TabDivider(),
          Expanded(
            child: _TabItem(
              icon: Icons.settings_rounded,
              label: '설정',
              onTap: onSettingsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabDivider extends StatelessWidget {
  const _TabDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFFE5D7EA),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.badge,
    this.warm = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final String? badge;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: active
                      ? const Color(0xFFE783BF)
                      : (warm
                          ? const Color(0xFFE098C0)
                          : const Color(0xFFC8A9D2)),
                  size: 32,
                ),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA89BF),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFFB56998)
                    : (warm
                        ? const Color(0xFFB97AA3)
                        : const Color(0xFFA18AAE)),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
