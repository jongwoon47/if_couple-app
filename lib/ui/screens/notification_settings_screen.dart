import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.appUser,
  });

  final AppUser appUser;

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late bool _allEnabled;
  late bool _messageEnabled;
  late bool _albumEnabled;
  late bool _anniversaryEnabled;
  late bool _scheduleEnabled;
  late TimeOfDay _notifyTime;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _allEnabled = widget.appUser.notificationAllEnabled;
    _messageEnabled = widget.appUser.notificationMessageEnabled;
    _albumEnabled = widget.appUser.notificationAlbumEnabled;
    _anniversaryEnabled = widget.appUser.notificationAnniversaryEnabled;
    _scheduleEnabled = widget.appUser.notificationScheduleEnabled;
    _notifyTime = _parseTime(widget.appUser.notificationTime);
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 9, minute: 0);
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(
      hour: hour.clamp(0, 23).toInt(),
      minute: minute.clamp(0, 59).toInt(),
    );
  }

  String _timeLabel(AppLocalizations l10n) {
    final hour = _notifyTime.hourOfPeriod == 0 ? 12 : _notifyTime.hourOfPeriod;
    final minute = _notifyTime.minute.toString().padLeft(2, '0');
    final period =
        _notifyTime.period == DayPeriod.am ? l10n.timeAm : l10n.timePm;
    return '$period $hour:$minute';
  }

  String _timeValue() {
    final hh = _notifyTime.hour.toString().padLeft(2, '0');
    final mm = _notifyTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _updateMasterByChildren() {
    _allEnabled =
        _messageEnabled || _albumEnabled || _anniversaryEnabled || _scheduleEnabled;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifyTime,
    );
    if (picked == null) return;

    setState(() {
      _notifyTime = picked;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await UserService.updateNotificationSettings(
        userId: widget.appUser.userId,
        allEnabled: _allEnabled,
        messageEnabled: _messageEnabled,
        albumEnabled: _albumEnabled,
        anniversaryEnabled: _anniversaryEnabled,
        scheduleEnabled: _scheduleEnabled,
        notificationTime: _timeValue(),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationTitleBar),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.saving : l10n.done),
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
          child: Padding(
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
                      _NotifyRow(
                        label: l10n.notificationAll,
                        subtitle: l10n.notificationAllSubtitle,
                        value: _allEnabled,
                        onChanged: (value) {
                          setState(() {
                            _allEnabled = value;
                            _messageEnabled = value;
                            _albumEnabled = value;
                            _anniversaryEnabled = value;
                            _scheduleEnabled = value;
                          });
                        },
                      ),
                      _NotifyRow(
                        label: l10n.notificationMessage,
                        subtitle: l10n.notificationMessageSubtitle,
                        value: _messageEnabled,
                        onChanged: (value) {
                          setState(() {
                            _messageEnabled = value;
                            _updateMasterByChildren();
                          });
                        },
                      ),
                      _NotifyRow(
                        label: l10n.notificationAlbum,
                        subtitle: l10n.notificationAlbumSubtitle,
                        value: _albumEnabled,
                        onChanged: (value) {
                          setState(() {
                            _albumEnabled = value;
                            _updateMasterByChildren();
                          });
                        },
                      ),
                      _NotifyRow(
                        label: l10n.notificationAnniversary,
                        subtitle: l10n.notificationAnniversarySubtitle,
                        value: _anniversaryEnabled,
                        onChanged: (value) {
                          setState(() {
                            _anniversaryEnabled = value;
                            _updateMasterByChildren();
                          });
                        },
                      ),
                      _NotifyRow(
                        label: l10n.notificationSchedule,
                        subtitle: l10n.notificationScheduleSubtitle,
                        value: _scheduleEnabled,
                        onChanged: (value) {
                          setState(() {
                            _scheduleEnabled = value;
                            _updateMasterByChildren();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  color: const Color(0xFFF7EFFA),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE6D8EA)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.notificationTimeTitle,
                              style: const TextStyle(
                                color: Color(0xFF72607F),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _timeLabel(l10n),
                            style: const TextStyle(
                              color: Color(0xFF9A86A8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB39DC0)),
                        ],
                      ),
                    ),
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

class _NotifyRow extends StatelessWidget {
  const _NotifyRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF72607F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFA696B3),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFFE984BE),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
