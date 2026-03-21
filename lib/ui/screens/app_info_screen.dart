import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appInfoTitleBar),
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  'if',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 72,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE08BB6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.appInfoVersion,
                  style: const TextStyle(
                    color: Color(0xFF7F708D),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appInfoUpdateDate,
                  style: const TextStyle(
                    color: Color(0xFFA194AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                _InfoTile(
                  label: l10n.privacyPolicy,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _InfoTile(
                  label: l10n.termsOfService,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _InfoTile(
                  label: l10n.contact,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7EFFA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
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
                  label,
                  style: const TextStyle(
                    color: Color(0xFF72607F),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB39DC0)),
            ],
          ),
        ),
      ),
    );
  }
}
