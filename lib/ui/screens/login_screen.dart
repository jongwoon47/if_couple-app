import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  @override
  void initState() {
    super.initState();
    _handleOAuthCallback();
  }

  Future<void> _handleOAuthCallback() async {
    try {
      await AuthService.handleWebOAuthCallbackIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notices = _mapErrorToNotices(e.toString());
      });
    }
  }

  Future<void> _login(LoginProvider provider) async {
    if (_loadingProvider != null) return;

    setState(() {
      _loadingProvider = provider;
      _notices = const [];
    });

    try {
      switch (provider) {
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
        _notices = _mapErrorToNotices(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingProvider = null;
        });
      }
    }
  }

  List<_LoginNotice> _mapErrorToNotices(String raw) {
    final message = raw.toLowerCase();
    final notices = <_LoginNotice>[];

    if (message.contains('auth_api_base_url')) {
      notices.add(
        const _LoginNotice(
          icon: Icons.settings,
          text: '서버 주소가 설정되지 않았어요.\n--dart-define=AUTH_API_BASE_URL 값을 넣어 주세요.',
        ),
      );
      return notices;
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timed out')) {
      notices.add(
        const _LoginNotice(
          icon: Icons.wifi_off,
          text: '네트워크가 불안정해요.\n잠시 후 다시 시도해 주세요.',
        ),
      );
    }

    if (message.contains('oauth failed') || message.contains('oauth exchange')) {
      notices.add(
        const _LoginNotice(
          icon: Icons.gpp_bad,
          text: '소셜 로그인 인증에 실패했어요.\n다시 시도해 주세요.',
        ),
      );
    }

    if (message.contains('account-exists-with-different-credential')) {
      notices.add(
        const _LoginNotice(
          icon: Icons.person,
          text: '이미 가입된 계정이에요.\n기존 로그인 방식으로 시도해 주세요.',
        ),
      );
    }

    if (notices.isEmpty) {
      notices.add(
        const _LoginNotice(
          icon: Icons.error_outline,
          text: '로그인에 실패했어요.\n다시 한 번 시도해 주세요.',
        ),
      );
    }

    return notices;
  }

  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        '서로의 언어를 이어주는 공간',
                        style: TextStyle(
                          color: Color(0xFF6A6071),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
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

const String _kakaoAssetPath = 'assets/images/kakao_login_medium_wide.png';
const String _lineLogoPath = 'assests/images/line_logo.png';

class _KakaoLoginImageButton extends StatelessWidget {
  const _KakaoLoginImageButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              _kakaoAssetPath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 52,
              errorBuilder: (_, __, ___) => _KakaoFallback(loading: loading, onPressed: onPressed),
            ),
            if (loading)
              const Positioned(
                right: 16,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF191919)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KakaoFallback extends StatelessWidget {
  const _KakaoFallback({required this.loading, this.onPressed});
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
          alignment: Alignment.center,
          child: const Text('카카오 로그인', style: TextStyle(color: Color(0xFF191919), fontSize: 18, fontWeight: FontWeight.w700)),
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
              const Expanded(
                child: Text('LINE으로 로그인', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
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
      child: const Text('LINE', style: TextStyle(color: Color(0xFF06C755), fontSize: 9, fontWeight: FontWeight.w800)),
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
              const Expanded(
                child: Text(
                  '구글로 로그인',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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

