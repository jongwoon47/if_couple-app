import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/couple.dart';
import '../../models/couple_event.dart';
import '../../services/calendar_service.dart';
import '../../services/couple_service.dart';
import '../../services/user_service.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

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
    required DateTime startDate,
    required String coupleId,
    required int year,
    DateTime? myBirthday,
    DateTime? partnerBirthday,
    String partnerNickname = '연인',
  }) {
    final list = <CoupleEvent>[];
    list.add(CoupleEvent(
      eventId: 'annual:startDate',
      coupleId: coupleId,
      title: '처음만난날',
      description: '',
      date: DateTime(year, startDate.month, startDate.day),
    ));
    if (myBirthday != null) {
      list.add(CoupleEvent(
        eventId: 'annual:birthday:me',
        coupleId: coupleId,
        title: '내 생일',
        description: '',
        date: DateTime(year, myBirthday.month, myBirthday.day),
      ));
    }
    if (partnerBirthday != null) {
      list.add(CoupleEvent(
        eventId: 'annual:birthday:partner',
        coupleId: coupleId,
        title: '$partnerNickname 생일',
        description: '',
        date: DateTime(year, partnerBirthday.month, partnerBirthday.day),
      ));
    }
    return list;
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

  Future<void> _addEvent() async {
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
                    const Expanded(
                      child: Text('일정 추가', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Text(DateFormat('yyyy년 M월 d일').format(_selected), style: const TextStyle(color: Color(0xFF9B8AA5))),
                const SizedBox(height: 10),
                TextField(controller: title, decoration: const InputDecoration(hintText: '일정 제목 입력')),
                const SizedBox(height: 8),
                TextField(controller: memo, decoration: const InputDecoration(hintText: '메모(선택)')),
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
                        setD(() => err = '일정 이름을 입력해 주세요.');
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
                    child: const Text('저장'),
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
              Text(DateFormat('yyyy년 M월 d일').format(event.date), style: const TextStyle(color: Color(0xFF9B8AA5), fontSize: 15)),
              if (event.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(event.description, style: const TextStyle(color: Color(0xFF8A7A92), fontSize: 15, height: 1.4)),
              ],
              if (isAnnual) ...[
                const SizedBox(height: 12),
                Text('매년 자동으로 표시되는 일정이에요.', style: TextStyle(color: Color(0xFF9B8AA5), fontSize: 13)),
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
                    child: const Text('확인'),
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
                        child: const Text('일정 수정'),
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
                        child: const Text('일정 삭제'),
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
                    const Expanded(
                      child: Text('일정 수정', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Text(DateFormat('yyyy년 M월 d일').format(editDate), style: const TextStyle(color: Color(0xFF9B8AA5))),
                const SizedBox(height: 10),
                TextField(controller: title, decoration: const InputDecoration(hintText: '일정 제목 입력')),
                const SizedBox(height: 8),
                TextField(controller: memo, decoration: const InputDecoration(hintText: '메모(선택)')),
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
                  label: const Text('날짜 변경'),
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
                        setD(() => err = '일정 이름을 입력해 주세요.');
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
                    child: const Text('저장'),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('일정을 삭제할까요?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제'))),
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
        const SnackBar(content: Text('일정이 삭제되었어요.'), behavior: SnackBarBehavior.floating),
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
                      final annualEvents = _buildAnnualEvents(
                        startDate: effectiveStartDate,
                        coupleId: coupleId,
                        year: _month.year,
                        myBirthday: appUser.birthday,
                        partnerBirthday: partner?.birthday,
                        partnerNickname: (partner?.nickname ?? '').trim().isEmpty ? '연인' : (partner?.nickname ?? '연인'),
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
                                  _CalendarCard(month: _month, selected: _selected, hasEvent: hasEvent, onPrev: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)), onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)), onPick: (d) => setState(() => _selected = d)),
                                  const SizedBox(height: 10),
                                  _SummaryCard(
                                    date: _selected,
                                    dDay: _dDay(startDate, _selected),
                                    events: dayEvents,
                                    onTapEvent: _showEventDetail,
                                    onLongPressEvent: (e) {
                                      if (!e.isAnnual) _confirmDelete(e);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _AddButton(onTap: _addEvent),
                                ],
                              ),
                            ),
                          ),
                          _BottomBar(onHome: _goHome, onChat: _goChat, onSettings: _goSettings),
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
    required this.month,
    required this.selected,
    required this.hasEvent,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });
  final DateTime month;
  final DateTime selected;
  final Map<String, bool> hasEvent;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onPick;

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _k(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Widget build(BuildContext context) {
    const weeks = ['일', '월', '화', '수', '목', '금', '토'];
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F1FA),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8D8EB)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded), color: const Color(0xFFC0A9BF)),
              Text(DateFormat('yyyy년 M월').format(month), style: const TextStyle(color: Color(0xFF786776), fontSize: 26, fontWeight: FontWeight.w700)),
              IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded), color: const Color(0xFFC0A9BF)),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: Color(0xFFE8DDE9), height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      weeks[i],
                      style: TextStyle(color: i == 0 ? const Color(0xFFE789B9) : const Color(0xFF8E7E90), fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 2,
              childAspectRatio: 0.92,
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
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: selectedDay ? const Color(0xFFEA95C3) : Colors.transparent),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day', style: TextStyle(color: color, fontSize: 42, fontWeight: FontWeight.w500)),
                      if (marker)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: selectedDay ? Colors.white : const Color(0xFFEAA2C8), shape: BoxShape.circle),
                        ),
                    ],
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
    required this.date,
    required this.dDay,
    required this.events,
    required this.onTapEvent,
    required this.onLongPressEvent,
  });
  final DateTime date;
  final int dDay;
  final List<CoupleEvent> events;
  final ValueChanged<CoupleEvent> onTapEvent;
  final ValueChanged<CoupleEvent> onLongPressEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F1FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D8EB)),
      ),
      child: Column(
        children: [
          Text('오늘 · ${DateFormat('yyyy년 M월 d일').format(date)}', style: const TextStyle(color: Color(0xFF8D7A91), fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('D+$dDay', style: const TextStyle(color: Color(0xFFE287BB), fontSize: 60, fontWeight: FontWeight.w800)),
          const Text('우리가 함께한 시간', style: TextStyle(color: Color(0xFF88788E), fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE8DDE9), height: 1),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('이 날짜에는 일정이 없어요.', style: TextStyle(color: Color(0xFFA192AB), fontSize: 15, fontWeight: FontWeight.w500)),
            )
          else
            Column(
              children: [
                for (final e in events)
                  GestureDetector(
                    onTap: () => onTapEvent(e),
                    onLongPress: () => onLongPressEvent(e),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFE9A3C8), shape: BoxShape.circle)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.title,
                              style: const TextStyle(color: Color(0xFF715D72), fontSize: 18, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8A8B8), size: 22),
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
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: double.infinity,
        height: 66,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F1FA),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE7D9EA)),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircleAvatar(radius: 16, backgroundColor: Color(0xFFE88EBF), child: Icon(Icons.add, color: Colors.white)),
              SizedBox(width: 10),
              Text('일정 추가', style: TextStyle(color: Color(0xFF7D6B81), fontSize: 38, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onHome, required this.onChat, required this.onSettings});
  final VoidCallback onHome;
  final VoidCallback onChat;
  final VoidCallback onSettings;

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
          _tab(Icons.home_rounded, '홈', false, onHome),
          _div(),
          _tab(Icons.chat_bubble_outline_rounded, '대화', false, onChat),
          _div(),
          _tab(Icons.calendar_month_rounded, '캘린더', true, () {}),
          _div(),
          _tab(Icons.settings_rounded, '설정', false, onSettings),
        ],
      ),
    );
  }

  Widget _div() => Container(width: 1, height: 36, color: const Color(0xFFE5D7EA));

  Widget _tab(IconData icon, String label, bool active, VoidCallback onTap) {
    final i = active ? const Color(0xFFE783BF) : const Color(0xFFC8A9D2);
    final t = active ? const Color(0xFFB56998) : const Color(0xFFA18AAE);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: i, size: 32),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(color: t, fontSize: 12, fontWeight: FontWeight.w700)),
                  if (active)
                    Container(
                      margin: const EdgeInsets.only(left: 2, top: 1),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFFE78CBF), shape: BoxShape.circle),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
