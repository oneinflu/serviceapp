import 'package:app/screens/company_info_screen.dart';
import 'package:app/screens/edit_profile_screen.dart';
import 'package:app/screens/company_list_screen.dart';
import 'package:app/screens/jobs/edit_job_post_screen.dart';
import 'package:app/screens/services/edit_service_post_screen.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:app/theme/app_theme.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/screens/jobs/my_job_posts_screen.dart';
import 'package:app/screens/refer_earn_screen.dart';
import 'package:app/screens/settings/about_app_screen.dart';
import 'package:app/screens/settings/terms_conditions_screen.dart';

import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/home_screen_preview.dart';
import 'screens/jobs/job_post_screen.dart';
import 'screens/jobs/job_profile_screen.dart';
import 'screens/jobs/job_search_screen.dart';
import 'screens/services/my_service_posts_screen.dart'; // Add this import
import 'screens/services/service_post_screen.dart';
import 'screens/services/service_search_screen.dart';
import 'screens/settings/language_screen.dart'; // Add this import
import 'screens/splash_screen.dart';
import 'screens/subscription/my_subscriptions_screen.dart';
import 'screens/subscription/payment_history_screen.dart';

/// Reads the Google Play Install Referrer once per install and, if it
/// carries a `referral_code`, stashes it so the register screen can
/// pre-fill the referral field.
Future<void> _capturePendingReferralCode(SharedPreferences prefs) async {
  if (!Platform.isAndroid) return;
  if (prefs.getBool('referral_checked') == true) return;

  try {
    final details = await PlayInstallReferrer.installReferrer;
    final referrer = details.installReferrer;
    if (referrer != null && referrer.isNotEmpty) {
      final code = Uri.splitQueryString(referrer)['referral_code'];
      if (code != null && code.isNotEmpty) {
        await prefs.setString('pending_referral_code', code);
      }
    }
  } catch (_) {
    // Play services unavailable or no referrer recorded; nothing to do.
  }

  await prefs.setBool('referral_checked', true);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('language_code') ?? 'en';

  await _capturePendingReferralCode(prefs);

  // Initialize auth provider and wait for auto login
  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider), // Use the same instance
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..setLocale(Locale(savedLocale)),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('gu'),
            Locale('mr'),
            Locale('kn'),
            Locale('ta'),
            Locale('te'),
            Locale('ml'),
            Locale('or'),
          ],
          title: 'Serviceinfotek',
          theme: AppTheme.lightTheme,
          initialRoute: '/',
          // Inside the routes map in MaterialApp:
          routes: {
            '/': (context) => const SplashScreen(),
            '/home-preview': (context) => const HomeScreenPreview(), // Design preview only, remove once finalized
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/company-info':
                (context) => const CompanyInfoScreen(), // Add this line
            '/service-search': (context) => const ServiceSearchScreen(),
            '/service-post': (context) => const ServicePostScreen(),
            '/edit-service-post':
                (context) => EditServicePostScreen(
                  service:
                      ModalRoute.of(context)!.settings.arguments
                          as Map<String, dynamic>,
                ),
            '/edit-job-post':
                (context) => EditJobPostScreen(
                  job:
                      ModalRoute.of(context)!.settings.arguments
                          as Map<String, dynamic>,
                ),
            '/job-search': (context) => const JobSearchScreen(),
            '/company-list': (context) => const CompanyListScreen(),
            '/refer': (context) => const ReferEarnScreen(),
            '/job-post': (context) => const JobPostScreen(),
            '/language': (context) => const LanguageScreen(),
            '/my-job-posts': (context) => const MyJobPostsScreen(),
            '/my-service-posts':
                (context) => const MyServicePostsScreen(), // Add this route
            '/terms': (context) => const TermsConditionsScreen(),
            '/about': (context) => const AboutAppScreen(),
            '/my-subscriptions': (context) => const MySubscriptionsScreen(),
            '/payment-history': (context) => const PaymentHistoryScreen(),
            '/profile': (context) => const JobProfileScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
          },
        );
      },
    );
  }
}
