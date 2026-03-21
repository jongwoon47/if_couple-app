import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/map_picker_result.dart';
import '../../models/trip_models.dart';
import 'map_picker_screen.dart';

class PlanEditSheet extends StatefulWidget {
  const PlanEditSheet({
    super.key,
    required this.trip,
    required this.initialDate,
    this.existing,
  });

  final Trip trip;
  final DateTime initialDate;
  final Plan? existing;

  @override
  State<PlanEditSheet> createState() => _PlanEditSheetState();
}

class _PlanEditSheetState extends State<PlanEditSheet> {
  late DateTime _date;
  TimeOfDay? _time;
  LatLng? _latLng;
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? widget.initialDate;
    if (widget.existing?.time != null) {
      final t = widget.existing!.time!;
      _time = TimeOfDay(hour: t.hour, minute: t.minute);
    }
    _placeController.text = widget.existing?.placeName ?? '';
    _memoController.text = widget.existing?.memo ?? '';
    if (widget.existing?.lat != null && widget.existing?.lng != null) {
      _latLng = LatLng(widget.existing!.lat!, widget.existing!.lng!);
    }
  }

  @override
  void dispose() {
    _placeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate,
    );
    if (selected != null) {
      setState(() {
        _date = selected;
      });
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (selected != null) {
      setState(() {
        _time = selected;
      });
    }
  }

  Future<void> _pickLocation() async {
    final selected = await Navigator.of(context).push<MapPickerResult?>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initial: _latLng),
      ),
    );
    if (selected != null) {
      setState(() {
        _latLng = selected.position;
        _placeController.text = selected.label;
      });
    }
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final place = _placeController.text.trim();
    if (place.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.planPlaceRequired),
        ),
      );
      return;
    }

    final baseDate = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time?.hour ?? 0,
      _time?.minute ?? 0,
    );

    final plan = Plan(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: widget.trip.id,
      date: DateTime(_date.year, _date.month, _date.day),
      time: _time == null ? null : baseDate,
      placeName: place,
      lat: _latLng?.latitude,
      lng: _latLng?.longitude,
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
    );

    // 상위로 Plan 객체 반환 → 추가/수정
    Navigator.of(context).pop<Plan>(plan);
  }

  void _delete() {
    // 상위로 'delete' 신호만 보냄
    Navigator.of(context).pop<String>('delete');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    final isEditing = widget.existing != null;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32),
              Text(
                isEditing ? l10n.planEditHeader : l10n.planAddHeader,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(
                    DateFormat.yMMMd(lc).format(_date),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickTime,
                  child: Text(
                    _time == null
                        ? l10n.timeSelectOptional
                        : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _placeController,
            decoration: InputDecoration(
              labelText: l10n.placeNameLabel,
              hintText: l10n.placeNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _memoController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.memoOptionalLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickLocation,
            icon: const Icon(Icons.map_outlined),
            label: Text(
              _latLng == null
                  ? l10n.mapPickFromMap
                  : l10n.mapPickedWithPlace(
                      _placeController.text.trim().isNotEmpty
                          ? _placeController.text.trim()
                          : l10n.mapPickedCoordsOnly,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? l10n.savePlan : l10n.addPlan),
            ),
          ),
          if (isEditing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(l10n.deletePlan),
            ),
          ],
        ],
        ),
      ),
    );
  }
}