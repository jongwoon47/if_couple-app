import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  static const _privacyUrl = 'https://if-app-b2854.web.app/privacy-policy.html';
  static const _termsUrl = 'https://if-app-b2854.web.app/terms-of-service.html';
  static const _contactEmail = 'jongun0361@gmail.com';

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open link')),
      );
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _contactEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email: $_contactEmail')),
      );
    }
  }

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const SizedBox(height: 16),
              Center(
                child: RichText(
                  text: const TextSpan(children: [
                    TextSpan(
                      text: 'i',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 72,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE978A9),
                      ),
                    ),
                    TextSpan(
                      text: 'f',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 72,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A62E0),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  l10n.appInfoDescription,
                  style: const TextStyle(
                    color: Color(0xFF9A86A8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l10n.appInfoVersion,
                  style: const TextStyle(
                    color: Color(0xFF7F708D),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  l10n.appInfoUpdateDate,
                  style: const TextStyle(
                    color: Color(0xFFA194AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _InfoTile(
                icon: Icons.shield_outlined,
                label: l10n.privacyPolicy,
                onTap: () => _openUrl(context, _privacyUrl),
              ),
              const SizedBox(height: 10),
              _InfoTile(
                icon: Icons.description_outlined,
                label: l10n.termsOfService,
                onTap: () => _openUrl(context, _termsUrl),
              ),
              const SizedBox(height: 10),
              _InfoTile(
                icon: Icons.code_rounded,
                label: l10n.openSourceLicenses,
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'IF App',
                    applicationVersion: '0.1.0',
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(16),
                      child: RichText(
                        text: const TextSpan(children: [
                          TextSpan(
                            text: 'i',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 42,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE978A9),
                            ),
                          ),
                          TextSpan(
                            text: 'f',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 42,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8A62E0),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _InfoTile(
                icon: Icons.mail_outline_rounded,
                label: l10n.contact,
                subtitle: _contactEmail,
                onTap: () => _openEmail(context),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      l10n.appInfoDeveloper,
                      style: const TextStyle(
                        color: Color(0xFFA194AF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.appInfoDeveloperName,
                      style: const TextStyle(
                        color: Color(0xFF7F708D),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '© 2026 IF App. All rights reserved.',
                      style: TextStyle(
                        color: Color(0xFFB8A9C4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
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
              Icon(icon, color: const Color(0xFF9B7FAD), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF72607F),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFFA194AF),
                          fontSize: 13,
                        ),
                      ),
                  ],
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
