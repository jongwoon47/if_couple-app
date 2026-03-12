import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_user.dart';
import '../../services/couple_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, required this.appUser});

  final AppUser appUser;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  static final RegExp _inviteCodeRegex = RegExp(r'^[A-Z0-9]{6}$');

  final TextEditingController _codeController = TextEditingController();

  InviteCodeInfo? _inviteInfo;
  bool _creating = false;
  bool _connecting = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadExistingInvite();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  String get _normalizedInput => _codeController.text.trim().toUpperCase();

  bool get _isCodeFormatValid => _inviteCodeRegex.hasMatch(_normalizedInput);

  bool get _canConnect => _isCodeFormatValid && !_connecting && !_creating;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _inviteInfo == null) return;
      setState(() {
        if (_inviteInfo!.isExpired) {
          _inviteInfo = null;
        }
      });
    });
  }

  Future<void> _loadExistingInvite() async {
    try {
      final invite =
          await CoupleService.getLatestActiveInviteCode(widget.appUser.userId);
      if (!mounted) return;
      setState(() {
        _inviteInfo = invite;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanErrorMessage(e);
      });
    }
  }

  Future<void> _onGenerate() async {
    if (_creating) return;
    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final invite = await CoupleService.createInviteCode(widget.appUser.userId);
      if (!mounted) return;
      setState(() {
        _inviteInfo = invite;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  Future<void> _onConnect() async {
    if (!_canConnect) return;
    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      await CoupleService.connectWithInviteCode(
        currentUserUid: widget.appUser.userId,
        inviteCode: _normalizedInput,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ConnectScreen] 연결 오류: $e');
        debugPrint('[ConnectScreen] 스택: $st');
        _debugPrintErrorChain(e);
      }
      if (!mounted) return;
      // 웹에서 'converted Future'로 감싸진 경우 안쪽 boxed error를 꺼내서 사용
      final displayError = _unwrapBoxedError(e);
      setState(() {
        _error = _cleanErrorMessage(displayError);
      });
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
        });
      }
    }
  }

  Future<void> _copyCode() async {
    final invite = _inviteInfo;
    if (invite == null) return;

    await Clipboard.setData(ClipboardData(text: invite.code));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('초대 코드를 복사했어요.')),
    );
  }

  String _countdownText() {
    final info = _inviteInfo;
    if (info == null) return '00:00';
    final remain = info.remaining;
    if (remain.inSeconds <= 0) return '00:00';

    final minutes = remain.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remain.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 웹에서 'converted Future'로 감싸진 예외의 안쪽 boxed error를 꺼냄
  Object _unwrapBoxedError(Object error) {
    Object? current = error;
    for (var i = 0; i < 10; i++) {
      if (current == null) return error;
      Object? next;
      if (current is AsyncError) {
        next = current.error;
      } else {
        try {
          final d = current as dynamic;
          if (d.error != null) next = d.error;
          if (next == null && d.cause != null) next = d.cause;
          if (next == null && d.source != null) next = d.source;
        } catch (_) {
          break;
        }
      }
      if (next == null || next == current) break;
      current = next;
    }
    return current ?? error;
  }

  /// 디버그: 예외 체인을 콘솔에 출력 (웹에서 실제 Firebase 오류 확인용)
  void _debugPrintErrorChain(Object error) {
    Object? current = error;
    var level = 0;
    while (current != null && level < 8) {
      if (current is FirebaseException) {
        debugPrint(
          '[ConnectScreen] 예외 체인[$level] FirebaseException: '
          'code=${current.code}, message=${current.message}',
        );
      } else {
        debugPrint('[ConnectScreen] 예외 체인[$level]: $current');
      }
      level++;
      Object? next;
      if (current is AsyncError) {
        next = current.error;
      } else {
        try {
          final d = current as dynamic;
          if (d.error != null) next = d.error;
          if (next == null && d.cause != null) next = d.cause;
          if (next == null && d.source != null) next = d.source;
        } catch (_) {}
      }
      if (next == current) break;
      current = next;
    }
  }

  String _cleanErrorMessage(Object error) {
    // 래핑된 예외 풀기 (웹 boxed error, AsyncError 등)
    Object target = error;
    FirebaseException? firebaseEx;
    for (var i = 0; i < 5; i++) {
      if (target is AsyncError) {
        target = target.error;
        continue;
      }
      if (target is FirebaseException) {
        firebaseEx = target;
        if (target.code == 'permission-denied') {
          return '연결 권한이 없습니다. Firestore 규칙을 확인해 주세요.';
        }
        final msg = (target.message ?? target.code).trim();
        if (msg.isNotEmpty) return msg;
      }
      try {
        final d = target as dynamic;
        if (d.error != null && d.error != target) {
          target = d.error;
          continue;
        }
      } catch (_) {}
      break;
    }

    // 래핑 안에 FirebaseException이 있었으면 그 메시지 사용
    if (firebaseEx != null) {
      final msg = (firebaseEx.message ?? firebaseEx.code).trim();
      if (msg.isNotEmpty) return msg;
    }

    var message = target.toString().trim();
    const prefixes = ['Exception: ', 'FirebaseException: ', 'Error: '];
    for (final prefix in prefixes) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length).trim();
      }
    }

    // 권한 거부가 메시지에 포함된 경우 (웹 등에서 래핑될 때)
    if (message.contains('permission-denied') ||
        message.contains('PERMISSION_DENIED')) {
      return '연결 권한이 없습니다. Firestore 규칙을 확인해 주세요.';
    }

    if (message.isEmpty ||
        message.contains('converted Future') ||
        message.contains('boxed error')) {
      return '처리 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.\n(로그인 상태와 Firestore 규칙을 확인해 보세요.)';
    }

    return message;
  }

  String _inputHintMessage() {
    if (_normalizedInput.isEmpty) {
      return '영문/숫자 6자리 초대 코드를 입력해 주세요.';
    }
    if (_isCodeFormatValid) {
      return '코드 형식이 올바릅니다.';
    }
    return '코드 형식이 올바르지 않습니다. 6자리를 맞춰 주세요.';
  }

  Color _inputHintColor() {
    if (_normalizedInput.isEmpty) {
      return const Color(0xFF9B8FA8);
    }
    return _isCodeFormatValid
        ? const Color(0xFF5D9A85)
        : const Color(0xFFA14B65);
  }

  @override
  Widget build(BuildContext context) {
    final invite = _inviteInfo;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8EEF9), Color(0xFFF2E5F3)],
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const _IfWordmark(),
                        const SizedBox(height: 20),
                        const Text(
                          '연인과 연결하세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6C5D78),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '초대 코드를 입력하거나 생성해서 연결할 수 있어요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9B8FA8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(6),
                            _UpperCaseTextFormatter(),
                          ],
                          onChanged: (_) {
                            setState(() {
                              _error = null;
                            });
                          },
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 10,
                            color: Color(0xFF6C5D78),
                          ),
                          decoration: InputDecoration(
                            hintText: '______',
                            hintStyle: const TextStyle(letterSpacing: 10),
                            filled: true,
                            fillColor: const Color(0xFFF8F1FB),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE5CFE2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _normalizedInput.isEmpty
                                    ? const Color(0xFFE5CFE2)
                                    : _isCodeFormatValid
                                        ? const Color(0xFF9ED2C2)
                                        : const Color(0xFFE7D3DF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _isCodeFormatValid
                                    ? const Color(0xFF86C2AE)
                                    : const Color(0xFFE48EB8),
                                width: 1.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: _inputHintColor(),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          child: Text(
                            _inputHintMessage(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ConnectButton(
                          text: _connecting ? '연결 중...' : '연결하기',
                          enabled: _canConnect,
                          onTap: _onConnect,
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            '또는',
                            style: TextStyle(
                              color: Color(0xFF9F93AC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: invite == null
                              ? _GenerateInviteButton(
                                  key: const ValueKey('generate-button'),
                                  loading: _creating,
                                  onTap: _onGenerate,
                                )
                              : _InviteCard(
                                  key: ValueKey('invite-${invite.code}'),
                                  inviteCode: invite.code,
                                  countdown: _countdownText(),
                                  refreshing: _creating,
                                  onCopy: _copyCode,
                                  onRefresh: _onGenerate,
                                ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          _ErrorBox(text: _error!),
                        ],
                      ],
                    ),
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

class _GenerateInviteButton extends StatelessWidget {
  const _GenerateInviteButton({
    super.key,
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: Color(0xFFE5CFE2)),
        backgroundColor: const Color(0xFFF8F1FB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        loading ? '코드 생성 중...' : '초대 코드 생성',
        style: const TextStyle(
          color: Color(0xFF8D7E9D),
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    super.key,
    required this.inviteCode,
    required this.countdown,
    required this.refreshing,
    required this.onCopy,
    required this.onRefresh,
  });

  final String inviteCode;
  final String countdown;
  final bool refreshing;
  final VoidCallback onCopy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5CFE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF8FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8D5E7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      inviteCode,
                      key: ValueKey(inviteCode),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF6C5D78),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '남은 시간: ',
                style: TextStyle(
                  color: Color(0xFF9A7F98),
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  countdown,
                  key: ValueKey(countdown),
                  style: const TextStyle(
                    color: Color(0xFF9A7F98),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: refreshing ? null : onRefresh,
            child: Text(refreshing ? '새 코드 생성 중...' : '새 코드 생성'),
          ),
        ],
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  final String text;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: enabled
              ? const LinearGradient(colors: [Color(0xFFF4B8D9), Color(0xFFE882BE)])
              : const LinearGradient(colors: [Color(0xFFE0DBE5), Color(0xFFCFC8D8)]),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              text,
              key: ValueKey(text),
              style: TextStyle(
                color: enabled ? Colors.white : const Color(0xFF92889A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.text});

  final String text;

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
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFA14B65),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IfWordmark extends StatelessWidget {
  const _IfWordmark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'i',
              style: TextStyle(
                color: Color(0xFFE8B9D4),
                fontSize: 68,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia',
              ),
            ),
            TextSpan(
              text: 'f',
              style: TextStyle(
                color: Color(0xFFCCB7EC),
                fontSize: 68,
                fontWeight: FontWeight.w600,
                fontFamily: 'Georgia',
              ),
            ),
          ],
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

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}
