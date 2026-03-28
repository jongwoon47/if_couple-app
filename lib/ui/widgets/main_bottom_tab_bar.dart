import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 홈 / 캘린더 등 주요 화면에서 동일한 하단 탭(5개)을 유지하기 위한 공통 위젯.
///
/// [activeTab]과 일치하는 탭만 **warm**(분홍)으로 강조되고, 나머지는 모두 회색(muted)입니다.
/// 예: 캘린더 화면이면 [MainTab.calendar]만 warm.
enum MainTab { home, chat, trip, calendar, album }

class MainBottomTabBar extends StatelessWidget {
  const MainBottomTabBar({
    super.key,
    required this.activeTab,
    required this.onHomeTap,
    required this.onChatTap,
    required this.onTripTap,
    required this.onCalendarTap,
    required this.onAlbumTap,
    this.chatBadge,
  });

  final MainTab activeTab;
  final VoidCallback onHomeTap;
  final VoidCallback onChatTap;
  final VoidCallback onTripTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onAlbumTap;
  final String? chatBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPad > 0 ? bottomPad : 14),
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
              label: l10n.tabHome,
              warm: activeTab == MainTab.home,
              onTap: onHomeTap,
            ),
          ),
          const _TabDivider(),
          Expanded(
            child: _TabItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: l10n.tabChat,
              badge: chatBadge,
              warm: activeTab == MainTab.chat,
              onTap: onChatTap,
            ),
          ),
          const _TabDivider(),
          Expanded(
            child: _TabItem(
              icon: Icons.airplane_ticket_rounded,
              label: l10n.tabTrip,
              warm: activeTab == MainTab.trip,
              onTap: onTripTap,
            ),
          ),
          const _TabDivider(),
          Expanded(
            child: _TabItem(
              icon: Icons.calendar_today_rounded,
              label: l10n.tabCalendar,
              warm: activeTab == MainTab.calendar,
              onTap: onCalendarTap,
            ),
          ),
          const _TabDivider(),
          Expanded(
            child: _TabItem(
              icon: Icons.photo_library_rounded,
              label: l10n.tabAlbum,
              warm: activeTab == MainTab.album,
              onTap: onAlbumTap,
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

/// muted: 비선택 탭(회색) / warm: 현재 화면에 해당하는 탭 하나만(분홍)
const _kTabMutedIcon = Color(0xFFC8A9D2);
const _kTabMutedLabel = Color(0xFFA18AAE);
const _kTabWarmIcon = Color(0xFFE783BF);
const _kTabWarmLabel = Color(0xFFB56998);

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.warm = false,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  /// true면 이 탭이 현재 화면(선택됨) → 분홍 강조
  final bool warm;
  final String? badge;

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
                  color: warm ? _kTabWarmIcon : _kTabMutedIcon,
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
                color: warm ? _kTabWarmLabel : _kTabMutedLabel,
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
