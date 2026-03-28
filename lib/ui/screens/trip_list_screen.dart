import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/trip_models.dart';
import '../../services/trip_service.dart';
import 'trip_detail_screen.dart';
import 'settings_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({
    super.key,
    required this.appUser,
  });

  final AppUser appUser;

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  String get _coupleId => widget.appUser.coupleId!;

  void _openTripDetail(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(
          trip: trip,
          appUser: widget.appUser,
        ),
      ),
    );
  }

  Future<void> _createTrip(BuildContext context) async {
    final titleController = TextEditingController();
    DateTimeRange? range;

    final created = await showModalBottomSheet<Trip>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.tripCreateTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.tripNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final selected = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 3),
                        initialDateRange: range ??
                            DateTimeRange(
                              start: now,
                              end: now.add(const Duration(days: 3)),
                            ),
                      );
                      if (selected != null) {
                        setState(() {
                          range = selected;
                        });
                      }
                    },
                    child: Text(
                      range == null
                          ? l10n.tripDateHint
                          : '${range!.start.year}.${range!.start.month.toString().padLeft(2, '0')}.${range!.start.day.toString().padLeft(2, '0')}'
                            ' - '
                            '${range!.end.year}.${range!.end.month.toString().padLeft(2, '0')}.${range!.end.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE98ABF),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isEmpty || range == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.tripFillRequired),
                            ),
                          );
                          return;
                        }
                        final trip = Trip(
                          id: '',
                          coupleId: _coupleId,
                          title: titleController.text.trim(),
                          startDate: range!.start,
                          endDate: range!.end,
                        );
                        Navigator.of(context).pop(trip);
                      },
                      child: Text(l10n.tripCreateAction),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (created != null) {
      await TripService.createTrip(
        coupleId: _coupleId,
        title: created.title,
        startDate: created.startDate,
        endDate: created.endDate,
      );
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tripDeleteTitle),
        content: Text(l10n.tripDeleteConfirm(trip.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      await TripService.deleteTrip(
        coupleId: _coupleId,
        tripId: trip.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(appUser: widget.appUser),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Trip>>(
        stream: TripService.tripStream(_coupleId),
        builder: (context, snapshot) {
          final trips = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting &&
              trips.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (trips.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.airplane_ticket_rounded,
                      size: 52,
                      color: Color(0xFFD167A0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.tripEmptyTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF755379),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.tripEmptySubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8F7398),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trip = trips[index];
                final period =
                    '${trip.startDate.year}.${trip.startDate.month.toString().padLeft(2, '0')}.${trip.startDate.day.toString().padLeft(2, '0')}'
                    ' - '
                    '${trip.endDate.year}.${trip.endDate.month.toString().padLeft(2, '0')}.${trip.endDate.day.toString().padLeft(2, '0')}';

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openTripDetail(context, trip),
                  onLongPress: () => _deleteTrip(trip),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                period,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTrip(context),
        backgroundColor: const Color(0xFFE98ABF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.tripMakeNew),
      ),
    );
  }
}