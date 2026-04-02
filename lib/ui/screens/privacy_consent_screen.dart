import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../widgets/onboarding_primary_button.dart';

/// [AppInfoScreen]과 동일한 정책 문서 URL
class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key, required this.firebaseUser});

  final User firebaseUser;

  static const _privacyUrl = 'https://if-app-b2854.web.app/privacy-policy.html';
  static const _termsUrl = 'https://if-app-b2854.web.app/terms-of-service.html';

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  static const _privacyPolicyVersion = '2026-03-30';
  static const _termsOfServiceVersion = '2026-03-30';

  bool _agreePrivacy = false;
  bool _agreeTerms = false;
  bool _agreeAge = false;
  bool _agreeMarketing = false;
  bool _submitting = false;
  String? _error;

  bool get _requiredConsentsChecked => _agreePrivacy && _agreeTerms && _agreeAge;
  bool get _allConsentsChecked =>
      _agreePrivacy && _agreeTerms && _agreeAge && _agreeMarketing;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open link')),
      );
    }
  }

  void _setAllConsents(bool value) {
    setState(() {
      _agreePrivacy = value;
      _agreeTerms = value;
      _agreeAge = value;
      _agreeMarketing = value;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_requiredConsentsChecked || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await UserService.createUserIfNotExists(widget.firebaseUser);
      await UserService.saveConsent(
        userId: widget.firebaseUser.uid,
        agreePrivacyPolicy: _agreePrivacy,
        agreeTermsOfService: _agreeTerms,
        agreeAgeConfirm: _agreeAge,
        agreeMarketing: _agreeMarketing,
        privacyPolicyVersion: _privacyPolicyVersion,
        termsOfServiceVersion: _termsOfServiceVersion,
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _submitting = false;
        _error = l10n.privacyConsentSaveError;
      });
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyConsentTitle),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _signOut,
            child: Text(l10n.logout),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.privacyConsentIntro,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Color(0xFF5C4A68),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _ConsentRow(
                  value: _allConsentsChecked,
                  onChanged: (v) => _setAllConsents(v ?? false),
                  label: l10n.privacyConsentAgreeAll,
                ),
                const SizedBox(height: 12),
                _ConsentRow(
                  value: _agreePrivacy,
                  onChanged: (v) => setState(() {
                    _agreePrivacy = v ?? false;
                    _error = null;
                  }),
                  label: l10n.privacyConsentAgreePrivacy,
                  onOpenDocument: () => _openUrl(PrivacyConsentScreen._privacyUrl),
                  viewLabel: l10n.privacyConsentViewDocument,
                ),
                const SizedBox(height: 12),
                _ConsentRow(
                  value: _agreeTerms,
                  onChanged: (v) => setState(() {
                    _agreeTerms = v ?? false;
                    _error = null;
                  }),
                  label: l10n.privacyConsentAgreeTerms,
                  onOpenDocument: () => _openUrl(PrivacyConsentScreen._termsUrl),
                  viewLabel: l10n.privacyConsentViewDocument,
                ),
                const SizedBox(height: 12),
                _ConsentRow(
                  value: _agreeAge,
                  onChanged: (v) => setState(() {
                    _agreeAge = v ?? false;
                    _error = null;
                  }),
                  label: l10n.privacyConsentAgreeAge,
                ),
                const SizedBox(height: 12),
                _ConsentRow(
                  value: _agreeMarketing,
                  onChanged: (v) => setState(() {
                    _agreeMarketing = v ?? false;
                    _error = null;
                  }),
                  label: l10n.privacyConsentAgreeMarketing,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFC45C7A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                OnboardingPrimaryButton(
                  label: l10n.privacyConsentContinue,
                  enabled: _requiredConsentsChecked && !_submitting,
                  onTap: _submit,
                ),
                if (_submitting) ...[
                  const SizedBox(height: 20),
                  const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF8A62E0),
                      ),
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

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.label,
    this.onOpenDocument,
    this.viewLabel,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final VoidCallback? onOpenDocument;
  final String? viewLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF8A62E0),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Color(0xFF3D3348),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onOpenDocument != null && viewLabel != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onOpenDocument,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(top: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          viewLabel!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B5FD4),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF7B5FD4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
