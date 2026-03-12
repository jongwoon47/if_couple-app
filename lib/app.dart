import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'services/firebase_initializer.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';
import 'ui/screens/connect_screen.dart';
import 'ui/screens/couple_connected_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/profile_setup_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/start_date_input_screen.dart';

class IfApp extends StatelessWidget {
  const IfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IF App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppGate(),
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
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Firebase initialization failed.\n'
                  'Please check lib/firebase_options.dart.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: AuthService.authStateChanges,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final user = authSnapshot.data;
            if (user == null) {
              return const LoginScreen();
            }

            return StreamBuilder<AppUser?>(
              stream: UserService.userStream(user.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState != ConnectionState.active &&
                    userSnapshot.connectionState != ConnectionState.done) {
                  return const SplashScreen();
                }

                final appUser = userSnapshot.data;
                if (appUser == null || !appUser.isProfileCompleted) {
                  return ProfileSetupScreen(firebaseUser: user);
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
