import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/trip_models.dart';
import '../../services/trip_service.dart';
import 'plan_edit_sheet.dart';

Future<void> _openPlanLocationInGoogleMaps(BuildContext context, Plan plan) async {
  final l10n = AppLocalizations.of(context)!;
  final lat = plan.lat;
  final lng = plan.lng;
  final Uri uri;
  if (lat != null && lng != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
  } else {
    final name = plan.placeName.trim();
    if (name.isEmpty) return;
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}',
    );
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.planOpenMapsFailed)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.planOpenMapsFailed)),
      );
    }
  }
}

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({
    super.key,
    required this.trip,
    required this.appUser,
  });

  final Trip trip;
  final AppUser appUser;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  List<DateTime> _daysInRange() {
    final trip = widget.trip;
    final days = <DateTime>[];
    var current = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    final end = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    final days = _daysInRange();
    final formatter = DateFormat.MMMEd(lc);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.title),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Plan>>(
        stream: TripService.planStream(
          coupleId: widget.trip.coupleId,
          tripId: widget.trip.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.tripLoadFailed(snapshot.error.toString()),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final allPlans = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting &&
              allPlans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final plansForDay =
                  allPlans.where((p) => _isSameDate(p.date, day)).toList();

              final isToday = _isSameDate(day, DateTime.now());

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          formatter.format(day),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.today,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.pink,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (plansForDay.isEmpty)
                      TextButton(
                        onPressed: () {
                          _openPlanSheet(day);
                        },
                        child: Text(l10n.planAdd),
                      )
                    else
                      Column(
                        children: [
                          for (final plan in plansForDay)
                            _PlanTile(
                              plan: plan,
                              onTap: () {
                                _openPlanSheet(day, existing: plan);
                              },
                            ),
                          TextButton(
                            onPressed: () {
                              _openPlanSheet(day);
                            },
                            child: Text(l10n.planAdd),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openPlanSheet(widget.trip.startDate);
        },
        backgroundColor: const Color(0xFFE98ABF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.planAddFab),
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _openPlanSheet(
    DateTime date, {
    Plan? existing,
  }) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PlanEditSheet(
        trip: widget.trip,
        initialDate: date,
        existing: existing,
      ),
    );

    if (result == null) return;

    // 삭제
    if (result is String && result == 'delete' && existing != null) {
      try {
        await TripService.deletePlan(
          coupleId: widget.trip.coupleId,
          tripId: widget.trip.id,
          planId: existing.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.planDeleted)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.planDeleteFailed(e.toString()),
            ),
          ),
        );
      }
      return;
    }

    // 추가/수정
    if (result is Plan) {
      try {
        await TripService.upsertPlan(
          coupleId: widget.trip.coupleId,
          plan: result,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? AppLocalizations.of(context)!.planAdded
                  : AppLocalizations.of(context)!.planSaved,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.planSaveFailed(e.toString()),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.onTap,
  });

  final Plan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeText =
        plan.time != null ? DateFormat('HH:mm').format(plan.time!) : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (timeText != null) ...[
              Text(
                timeText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.placeName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (plan.memo != null && plan.memo!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      plan.memo!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.map_outlined),
              color: const Color(0xFFE98ABF),
              tooltip: l10n.planOpenInMaps,
              onPressed: () => _openPlanLocationInGoogleMaps(context, plan),
            ),
          ],
        ),
      ),
    );
  }
}