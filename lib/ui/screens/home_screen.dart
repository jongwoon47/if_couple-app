import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../services/chat_service.dart';
import '../../services/couple_service.dart';
import '../../services/user_service.dart';
import 'calendar_screen_v2.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'trip_list_screen.dart';
import 'album_list_screen.dart';
import '../widgets/home_if_logo.dart';
import '../widgets/main_bottom_tab_bar.dart';

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

  Future<void> _openTrip(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripListScreen(appUser: widget.appUser),
      ),
    );
  }

  Future<void> _openAlbum(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumListScreen(appUser: widget.appUser),
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
              final l10n = AppLocalizations.of(context)!;
              final couple = snapshot.data;
              final startDate = couple?.startDate ?? appUser.startDate ?? DateTime.now();
              final dDay = _dDay(startDate);
              final partnerId = couple != null
                  ? (couple.user1Id == appUser.userId ? couple.user2Id : couple.user1Id)
                  : null;

              return Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () => _openSettings(context),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: HomeIfLogo(height: 72),
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
                                  text: '  ${appUser.partnerNickname.trim().isEmpty ? l10n.partnerDefault : appUser.partnerNickname}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'D+$dDay',
                            style: const TextStyle(
                              color: Color(0xFFCC2E7B),
                              fontSize: 70,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.homeTogetherTime,
                            style: const TextStyle(
                              color: Color(0xFF694564),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
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
                              l10n.homeStartDate(DateFormat('yyyy.MM.dd').format(startDate)),
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
                                    Expanded(
                                      child: Text(
                                        l10n.homeGreetingQuestion,
                                        style: const TextStyle(
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
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 14),
                                          child: Text(
                                            l10n.homeStartChat,
                                            style: const TextStyle(
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
                      ? MainBottomTabBar(
                          activeTab: MainTab.home,
                          onHomeTap: () {},
                          onChatTap: () => _openChat(context),
                          onTripTap: () => _openTrip(context),
                          onCalendarTap: () => _openCalendar(context),
                          onAlbumTap: () => _openAlbum(context),
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
                            return MainBottomTabBar(
                              activeTab: MainTab.home,
                              onHomeTap: () {},
                              onChatTap: () => _openChat(context),
                              onTripTap: () => _openTrip(context),
                              onCalendarTap: () => _openCalendar(context),
                              onAlbumTap: () => _openAlbum(context),
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
