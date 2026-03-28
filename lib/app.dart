import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'l10n/app_locale_scope.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'services/firebase_initializer.dart';
import 'services/push_notification_service.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';
import 'ui/screens/connect_screen.dart';
import 'ui/screens/couple_connected_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/profile_setup_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/start_date_input_screen.dart';

class IfApp extends StatefulWidget {
  const IfApp({super.key});

  @override
  State<IfApp> createState() => _IfAppState();
}

class _IfAppState extends State<IfApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = AppLocaleController.locale;
  }

  Future<void> _setLocale(Locale locale) async {
    await AppLocaleController.persistAndApply(locale);
    if (mounted) setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      locale: _locale,
      setLocale: _setLocale,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: _locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppGate(),
      ),
    );
  }
}

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: FirebaseInitializer.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          final l10n = AppLocalizations.of(context)!;
          return SplashScreen(
            message: l10n.splashPreparingIf,
          );
        }

        if (snapshot.hasError) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF7E9F8), Color(0xFFEEDCF3)],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 42,
                        color: Color(0xFFD167A0),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appLoadErrorTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF755379),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.appLoadErrorBody,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8F7398),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: AuthService.authStateChanges,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              final l10n = AppLocalizations.of(context)!;
              return SplashScreen(
                message: l10n.splashCheckingLogin,
              );
            }

            final user = authSnapshot.data;
            if (user == null) {
              return const LoginScreen();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              PushNotificationService.ensureInitializedForUser(user.uid);
            });

            return StreamBuilder<AppUser?>(
              stream: UserService.userStream(user.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState != ConnectionState.active &&
                    userSnapshot.connectionState != ConnectionState.done) {
                  final l10n = AppLocalizations.of(context)!;
                  return SplashScreen(
                    message: l10n.splashLoadingProfile,
                  );
                }

                final appUser = userSnapshot.data;
                if (appUser == null || !appUser.isProfileCompleted) {
                  return ProfileSetupScreen(firebaseUser: user);
                }

                // 기존 Firestore 문서 레거시 필드·플래그 불일치 1회 보정
                if (UserService.shouldScheduleUserDocumentRepair(appUser)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    UserService.repairUserDocumentIfNeeded(appUser);
                  });
                }

                if (appUser.coupleId == null || appUser.coupleId!.isEmpty) {
                  return ConnectScreen(appUser: appUser);
                }

                if (!appUser.hasSeenConnectionComplete) {
                  return CoupleConnectedScreen(appUser: appUser);
                }

                // 커플 연결 완료 후, 처음만난날이 아직 없다면 전용 입력 화면으로 이동
                if (appUser.startDate == null) {
                  return StartDateInputScreen(appUser: appUser);
                }

                return HomeScreen(appUser: appUser);
              },
            );
          },
        );
      },
    );
  }
}
