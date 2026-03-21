import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/couple_event.dart';
import '../../services/calendar_service.dart';
import '../../services/chat_service.dart';
import '../../services/couple_service.dart';
import '../../services/user_service.dart';
import '../widgets/main_bottom_tab_bar.dart';
import 'album_list_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'trip_list_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.appUser});
  final AppUser appUser;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selected = DateTime(now.year, now.month, now.day);
  }

  DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _k(DateTime x) => '${x.year}-${x.month}-${x.day}';

  int _dDay(DateTime start, DateTime t) => _d(t).difference(_d(start)).inDays + 1;

  /// 매년 반복되는 자동 일정: 처음만난날, 내 생일, 연인 생일 (해당 연도 기준)
  static List<CoupleEvent> _buildAnnualEvents({
    required AppLocalizations l10n,
    required DateTime startDate,
    required String coupleId,
    required int year,
    DateTime? myBirthday,
    DateTime? partnerBirthday,
    required String partnerNickname,
  }) {
    final list = <CoupleEvent>[];
    list.add(CoupleEvent(
      eventId: 'annual:startDate',
      coupleId: coupleId,
      title: l10n.firstMeetDay,
      description: '',
      date: DateTime(year, startDate.month, startDate.day),
    ));
    if (myBirthday != null) {
      list.add(CoupleEvent(
        eventId: 'annual:birthday:me',
        coupleId: coupleId,
        title: l10n.myBirthday,
        description: '',
        date: DateTime(year, myBirthday.month, myBirthday.day),
      ));
    }
    if (partnerBirthday != null) {
      list.add(CoupleEvent(
        eventId: 'annual:birthday:partner',
        coupleId: coupleId,
        title: l10n.partnerBirthday(partnerNickname),
        description: '',
        date: DateTime(year, partnerBirthday.month, partnerBirthday.day),
      ));
    }
    return list;
  }

  String _formatYmd(BuildContext context, DateTime d) {
    final lc = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMd(lc).format(d);
  }

  String _formatMonthYear(BuildContext context, DateTime m) {
    final lc = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMM(lc).format(m);
  }

  Future<void> _goHome() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _goChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(appUser: widget.appUser)),
    );
  }

  Future<void> _goSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SettingsScreen(appUser: widget.appUser)),
    );
  }

  Future<void> _goTrip() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripListScreen(appUser: widget.appUser),
      ),
    );
  }

  Future<void> _goAlbum() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumListScreen(appUser: widget.appUser),
      ),
    );
  }

  Future<void> _addEvent() async {
    final l10n = AppLocalizations.of(context)!;
    final title = TextEditingController();
    final memo = TextEditingController();
    String? err;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                    Expanded(
                      child: Text(
                        l10n.eventAdd,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Text(_formatYmd(ctx, _selected), style: const TextStyle(color: Color(0xFF9B8AA5))),
                const SizedBox(height: 10),
                TextField(
                  controller: title,
                  decoration: InputDecoration(hintText: l10n.eventNameHint),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: memo,
                  decoration: InputDecoration(hintText: l10n.eventMemoHint),
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: Color(0xFFB55C80), fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (title.text.trim().isEmpty) {
                        setD(() => err = l10n.eventNameRequired);
                        return;
                      }
                      await CalendarService.createEvent(
                        coupleId: widget.appUser.coupleId!,
                        title: title.text.trim(),
                        description: memo.text.trim(),
                        date: _selected,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEventDetail(CoupleEvent event) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final isAnnual = event.isAnnual;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: const Color(0xFFFDF8FE),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF6F5C75))),
              const SizedBox(height: 8),
              Text(_formatYmd(ctx, event.date), style: const TextStyle(color: Color(0xFF9B8AA5), fontSize: 15)),
              if (event.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(event.description, style: const TextStyle(color: Color(0xFF8A7A92), fontSize: 15, height: 1.4)),
              ],
              if (isAnnual) ...[
                const SizedBox(height: 12),
                Text(l10n.yearlyEventNote, style: const TextStyle(color: Color(0xFF9B8AA5), fontSize: 13)),
              ],
              const SizedBox(height: 20),
              if (isAnnual)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE88EBF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.confirm),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _editEvent(event);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE88EBF)),
                          foregroundColor: const Color(0xFFB56998),
                        ),
                        child: Text(l10n.eventEdit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDelete(event);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE88EBF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.eventDelete),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editEvent(CoupleEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    final title = TextEditingController(text: event.title);
    final memo = TextEditingController(text: event.description);
    DateTime editDate = event.date;
    String? err;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                    Expanded(
                      child: Text(
                        l10n.eventEdit,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Text(_formatYmd(ctx, editDate), style: const TextStyle(color: Color(0xFF9B8AA5))),
                const SizedBox(height: 10),
                TextField(
                  controller: title,
                  decoration: InputDecoration(hintText: l10n.eventNameHint),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: memo,
                  decoration: InputDecoration(hintText: l10n.eventMemoHint),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: editDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setD(() => editDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(l10n.changeDate),
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: Color(0xFFB55C80), fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (title.text.trim().isEmpty) {
                        setD(() => err = l10n.eventNameRequired);
                        return;
                      }
                      await CalendarService.updateEvent(
                        coupleId: widget.appUser.coupleId!,
                        eventId: event.eventId,
                        title: title.text.trim(),
                        description: memo.text.trim(),
                        date: editDate,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(CoupleEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.scheduleDeleteConfirm, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await CalendarService.deleteEvent(coupleId: widget.appUser.coupleId!, eventId: event.eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventDeleted), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '').trim()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB55C80),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appUser = widget.appUser;
    final coupleId = appUser.coupleId!;
    final startDate = appUser.startDate ?? DateTime.now();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7E9F8), Color(0xFFEEDCF3)]),
        ),
        child: SafeArea(
          child: StreamBuilder<Couple?>(
            stream: CoupleService.coupleStream(coupleId),
            builder: (context, coupleSnap) {
              final couple = coupleSnap.data;
              final effectiveStartDate = couple?.startDate ?? appUser.startDate ?? DateTime.now();
              final partnerId = couple != null
                  ? (couple.user1Id == appUser.userId ? couple.user2Id : couple.user1Id)
                  : null;

              return StreamBuilder<List<CoupleEvent>>(
                stream: CalendarService.eventStream(coupleId),
                builder: (context, eventsSnap) {
                  final events = eventsSnap.data ?? const <CoupleEvent>[];
                  return FutureBuilder<AppUser?>(
                    key: ValueKey(partnerId ?? ''),
                    future: partnerId != null ? UserService.getUser(partnerId) : Future<AppUser?>.value(null),
                    builder: (context, partnerSnap) {
                      final partner = partnerSnap.data;
                      final partnerNick = (partner?.nickname ?? '').trim();
                      final annualEvents = _buildAnnualEvents(
                        l10n: l10n,
                        startDate: effectiveStartDate,
                        coupleId: coupleId,
                        year: _month.year,
                        myBirthday: appUser.birthday,
                        partnerBirthday: partner?.birthday,
                        partnerNickname:
                            partnerNick.isEmpty ? l10n.partnerDefault : partnerNick,
                      );
                      final merged = <CoupleEvent>[...events, ...annualEvents]
                        ..sort((a, b) => a.date.compareTo(b.date));
                      final hasEvent = <String, bool>{for (final e in merged) _k(_d(e.date)): true};
                      final dayEvents = merged.where((e) => _same(_d(e.date), _selected)).toList();

                      return Column(
                        children: [
                          _TopBar(onChat: _goChat, onHome: _goHome, onSettings: _goSettings),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                              child: Column(
                                children: [
                                  _CalendarCard(
                                    l10n: l10n,
                                    month: _month,
                                    selected: _selected,
                                    hasEvent: hasEvent,
                                    onPrev: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)),
                                    onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)),
                                    onPick: (d) => setState(() => _selected = d),
                                    formatMonthYear: (m) => _formatMonthYear(context, m),
                                  ),
                                  const SizedBox(height: 10),
                                  _SummaryCard(
                                    l10n: l10n,
                                    date: _selected,
                                    dDay: _dDay(startDate, _selected),
                                    events: dayEvents,
                                    formatYmd: (d) => _formatYmd(context, d),
                                    onTapEvent: _showEventDetail,
                                    onLongPressEvent: (e) {
                                      if (!e.isAnnual) _confirmDelete(e);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _AddButton(onTap: _addEvent, l10n: l10n),
                                ],
                              ),
                            ),
                          ),
                          partnerId == null
                              ? MainBottomTabBar(
                                  activeTab: MainTab.calendar,
                                  onHomeTap: _goHome,
                                  onChatTap: _goChat,
                                  onTripTap: _goTrip,
                                  onCalendarTap: () {},
                                  onAlbumTap: _goAlbum,
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
                                      activeTab: MainTab.calendar,
                                      onHomeTap: _goHome,
                                      onChatTap: _goChat,
                                      onTripTap: _goTrip,
                                      onCalendarTap: () {},
                                      onAlbumTap: _goAlbum,
                                      chatBadge: badge,
                                    );
                                  },
                                ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onChat, required this.onHome, required this.onSettings});
  final VoidCallback onChat;
  final VoidCallback onHome;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EFFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7D8EA)),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onChat, icon: const Icon(Icons.chat_bubble_rounded), color: const Color(0xFFB8A8B8)),
          const Spacer(),
          IconButton(onPressed: onHome, icon: const Icon(Icons.favorite_rounded), color: const Color(0xFFE78CBF)),
          const Spacer(),
          IconButton(onPressed: onSettings, icon: const Icon(Icons.settings_rounded), color: const Color(0xFFB8A8B8)),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.l10n,
    required this.month,
    required this.selected,
    required this.hasEvent,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
    required this.formatMonthYear,
  });
  final AppLocalizations l10n;
  final DateTime month;
  final DateTime selected;
  final Map<String, bool> hasEvent;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onPick;
  final String Function(DateTime) formatMonthYear;

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _k(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Widget build(BuildContext context) {
    final weeks = <String>[
      l10n.weekDaySun,
      l10n.weekDayMon,
      l10n.weekDayTue,
      l10n.weekDayWed,
      l10n.weekDayThu,
      l10n.weekDayFri,
      l10n.weekDaySat,
    ];
    final first = DateTime(month.year, month.month, 1);
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = first.weekday % 7;
    final total = offset + count;
    final rows = ((total + 6) / 7).floor();
    final cells = rows * 7;
    final days = List<int?>.generate(cells, (i) {
      final d = i - offset + 1;
      if (d < 1 || d > count) return null;
      return d;
    });

    // 좁은 화면에서도 오버플로 없이 맞추기 (날짜 셀 너비 기준 스케일)
    final screenW = MediaQuery.sizeOf(context).width;
    final monthTitle = (screenW * 0.042).clamp(15.0, 18.0);
    final weekLabel = (screenW * 0.028).clamp(10.0, 12.0);
    final dayNum = (screenW * 0.038).clamp(12.0, 16.0);
    final dotSize = (dayNum * 0.35).clamp(4.0, 6.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F1FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8D8EB)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded, size: 26),
                color: const Color(0xFFC0A9BF),
              ),
              Expanded(
                child: Text(
                  formatMonthYear(month),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: const Color(0xFF786776), fontSize: monthTitle, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded, size: 26),
                color: const Color(0xFFC0A9BF),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFFE8DDE9), height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      weeks[i],
                      style: TextStyle(
                        color: i == 0 ? const Color(0xFFE789B9) : const Color(0xFF8E7E90),
                        fontSize: weekLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 2,
              // 셀을 조금 넓게(정사각형에 가깝게) — 글자+점이 들어갈 높이 확보
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              if (day == null) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, day);
              final selectedDay = _same(date, selected);
              final marker = hasEvent[_k(date)] == true;
              final dow = index % 7;
              final color = selectedDay ? Colors.white : (dow == 0 ? const Color(0xFFE789B9) : const Color(0xFF877889));

              return GestureDetector(
                onTap: () => onPick(date),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: selectedDay ? 8 : 4,
                        vertical: selectedDay ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedDay ? const Color(0xFFEA95C3) : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$day',
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: color,
                                fontSize: dayNum,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                          ),
                          if (marker)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                width: dotSize,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  color: selectedDay ? Colors.white : const Color(0xFFEAA2C8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.l10n,
    required this.date,
    required this.dDay,
    required this.events,
    required this.formatYmd,
    required this.onTapEvent,
    required this.onLongPressEvent,
  });
  final AppLocalizations l10n;
  final DateTime date;
  final int dDay;
  final List<CoupleEvent> events;
  final String Function(DateTime) formatYmd;
  final ValueChanged<CoupleEvent> onTapEvent;
  final ValueChanged<CoupleEvent> onLongPressEvent;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final dDaySize = (w * 0.09).clamp(26.0, 36.0);
    final subSize = (w * 0.034).clamp(12.0, 14.0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(date.year, date.month, date.day);
    final dateStr = formatYmd(date);
    final headerText = sel == today ? l10n.calendarTodayLine(dateStr) : dateStr;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F1FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8D8EB)),
      ),
      child: Column(
        children: [
          Text(
            headerText,
            style: TextStyle(color: const Color(0xFF8D7A91), fontSize: subSize, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'D+$dDay',
            style: TextStyle(color: const Color(0xFFE287BB), fontSize: dDaySize, fontWeight: FontWeight.w800, height: 1.05),
          ),
          Text(
            l10n.calendarTogetherLine,
            style: TextStyle(color: const Color(0xFF88788E), fontSize: subSize, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE8DDE9), height: 1),
          const SizedBox(height: 6),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                l10n.calendarEmptyLine,
                style: TextStyle(color: const Color(0xFFA192AB), fontSize: subSize, fontWeight: FontWeight.w500),
              ),
            )
          else
            Column(
              children: [
                for (final e in events)
                  GestureDetector(
                    onTap: () => onTapEvent(e),
                    onLongPress: () => onLongPressEvent(e),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFFE9A3C8), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.title,
                              style: TextStyle(color: const Color(0xFF715D72), fontSize: subSize + 1, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8A8B8), size: 20),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.l10n});
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F1FA),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE7D9EA)),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(radius: 14, backgroundColor: Color(0xFFE88EBF), child: Icon(Icons.add, color: Colors.white, size: 20)),
              const SizedBox(width: 8),
              Text(l10n.calendarAddEvent, style: const TextStyle(color: Color(0xFF7D6B81), fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

