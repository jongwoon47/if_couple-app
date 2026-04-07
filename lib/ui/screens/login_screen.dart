import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_locale_scope.dart';
import '../../models/login_provider.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginProvider? _loadingProvider;
  List<_LoginNotice> _notices = const [];

  static const Color _bgTop = Color(0xFFF8EEF9);
  static const Color _bgBottom = Color(0xFFF2E5F3);

  Future<void> _login(LoginProvider provider) async {
    if (_loadingProvider != null) return;

    setState(() {
      _loadingProvider = provider;
      _notices = const [];
    });

    try {
      switch (provider) {
        case LoginProvider.apple:
          await AuthService.signInWithApple();
          break;
        case LoginProvider.google:
          await AuthService.signInWithGoogle();
          break;
        case LoginProvider.kakao:
          await AuthService.startKakaoSignIn();
          break;
        case LoginProvider.line:
          await AuthService.startLineSignIn();
          break;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notices = _mapErrorToNotices(e.toString(), AppLocaleController.l10n);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingProvider = null;
        });
      }
    }
  }

  List<_LoginNotice> _mapErrorToNotices(String raw, AppLocalizations l10n) {
    final message = raw.toLowerCase();
    final notices = <_LoginNotice>[];

    if (message.contains('auth_api_base_url')) {
      notices.add(
        _LoginNotice(
          icon: Icons.settings,
          text: l10n.loginServerNotConfigured,
        ),
      );
      return notices;
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timed out')) {
      notices.add(
        _LoginNotice(
          icon: Icons.wifi_off,
          text: l10n.loginNetworkUnstable,
        ),
      );
    }

    if (message.contains('oauth failed') ||
        message.contains('oauth exchange') ||
        message.contains('token exchange failed') ||
        message.contains('access token')) {
      notices.add(
        _LoginNotice(
          icon: Icons.gpp_bad,
          text: l10n.loginOAuthFailed,
        ),
      );
    }

    if (message.contains('account-exists-with-different-credential')) {
      notices.add(
        _LoginNotice(
          icon: Icons.person,
          text: l10n.loginAccountExists,
        ),
      );
    }

    if (notices.isEmpty) {
      notices.add(
        _LoginNotice(
          icon: Icons.error_outline,
          text: l10n.loginFailed,
        ),
      );
    }

    return notices;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: CustomPaint(
          painter: _DotPatternPainter(),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'i',
                              style: TextStyle(
                                color: Color(0xFFE978A9),
                                fontSize: 74,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            TextSpan(
                              text: 'f',
                              style: TextStyle(
                                color: Color(0xFF8A62E0),
                                fontSize: 74,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Georgia',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.loginTagline,
                        style: const TextStyle(
                          color: Color(0xFF6A6071),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (!kIsWeb) ...[
                        if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                          _AppleLoginButton(
                            label: l10n.loginApple,
                            loading: _loadingProvider == LoginProvider.apple,
                            onPressed: _loadingProvider == null
                                ? () => _login(LoginProvider.apple)
                                : null,
                          ),
                          const SizedBox(height: 10),
                        ],
                        _KakaoLoginImageButton(
                          loading: _loadingProvider == LoginProvider.kakao,
                          onPressed: _loadingProvider == null
                              ? () => _login(LoginProvider.kakao)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        _LineLoginButton(
                          loading: _loadingProvider == LoginProvider.line,
                          onPressed: _loadingProvider == null
                              ? () => _login(LoginProvider.line)
                              : null,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _GoogleLoginButton(
                        loading: _loadingProvider == LoginProvider.google,
                        onPressed: _loadingProvider == null
                            ? () => _login(LoginProvider.google)
                            : null,
                      ),
                      if (_notices.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        for (final notice in _notices) ...[
                          _NoticeCard(notice: notice),
                          const SizedBox(height: 8),
                        ],
                      ],
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const String _lineLogoPath = 'assets/images/line_logo.png';

class _KakaoLoginImageButton extends StatelessWidget {
  const _KakaoLoginImageButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEE500),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Image.asset('assets/images/image.png', width: 32, height: 32),
              Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 10), color: const Color(0x1A000000)),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.loginKakao,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF191919), fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (loading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF191919))))
              else
                const SizedBox(width: 18, height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineLoginButton extends StatelessWidget {
  const _LineLoginButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback? onPressed;

  static const Color _green = Color(0xFF06C755);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _green,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF06B14D)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Image.asset(
                  _lineLogoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const _LineIconFallback(),
                ),
              ),
              Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 12), color: const Color(0x14000000)),
              Expanded(
                child: Text(AppLocalizations.of(context)!.loginLine, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              if (loading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              else
                const SizedBox(width: 18, height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineIconFallback extends StatelessWidget {
  const _LineIconFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.center,
      child: Text(AppLocalizations.of(context)!.loginLineShort, style: const TextStyle(color: Color(0xFF06C755), fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFDADCE0);
    const textColor = Color(0xFF3C4043);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // 구글 공식 GSI Material 버튼 아이콘 (SVG)
              SizedBox(
                width: 32,
                height: 32,
                child: SvgPicture.asset(
                  'assets/images/google_logo.svg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.loginGoogle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else
                const SizedBox(width: 18, height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleLoginButton extends StatelessWidget {
  const _AppleLoginButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = loading || onPressed == null;
    return AbsorbPointer(
      absorbing: busy,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: busy ? 0.55 : 1,
            child: SignInWithAppleButton(
              text: label,
              height: 52,
              style: SignInWithAppleButtonStyle.black,
              borderRadius: BorderRadius.circular(4),
              onPressed: () {
                if (onPressed != null) onPressed!();
              },
            ),
          ),
          if (loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    const radius = 1.2;
    final paint = Paint()..color = const Color(0x14A584B6);

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final _LoginNotice notice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEFF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7D3DF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(notice.icon, color: const Color(0xFFC25A7B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notice.text,
              style: const TextStyle(
                color: Color(0xFFA14B65),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginNotice {
  const _LoginNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

