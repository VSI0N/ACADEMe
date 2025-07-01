import 'package:ACADEMe/started/pages/animated_splash.dart';
import 'package:ACADEMe/home/pages/bottom_nav.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:ACADEMe/services/study_time_tracker.dart'; // Add this import
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'home/auth/role.dart';
import 'academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ACADEMe/providers/bottom_nav_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔹 Load environment variables
  try {
    await dotenv.load(fileName: "assets/.env");
    debugPrint("✅ .env Loaded Successfully");
  } catch (e) {
    debugPrint("❌ .env Load Error: $e");
  }

  /// 🔹 Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase Initialized Successfully");
  } catch (e) {
    debugPrint("❌ Firebase Initialization Error: $e");
  }

  /// 🔹 Fetch admin emails first (blocking)
  await AdminRoles.fetchAdminEmails();

  /// 🔹 Load user role asynchronously
  final prefs = await SharedPreferences.getInstance();
  String? userEmail = prefs.getString("user_email");

  if (userEmail != null) {
    await UserRoleManager().fetchUserRole(userEmail);
  }
  await UserRoleManager().loadRole();

  /// 🔹 Initialize Global Study Time Tracker
  await StudyTimeTracker().initialize();
  debugPrint("✅ Study Time Tracker Initialized");

  /// 🔹 Lock device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  /// 🔹 Set UI style (Moved from MyApp)
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness:
    !kIsWeb && Platform.isAndroid ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  /// 🔹 Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => LanguageProvider()), // Language provider
        ChangeNotifierProvider(
            create: (context) => BottomNavProvider()), // BottomNav provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, BottomNavProvider>(
      builder: (context, languageProvider, bottomNavProvider, child) {
        return MaterialApp(
          title: 'ACADEMe',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: AcademeTheme.textTheme,
            platform: TargetPlatform.iOS,
          ),
          locale: languageProvider.locale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, _) {
            return L10n.getSupportedLocale(locale);
          },
          home: AnimatedSplashScreen(),
          routes: {
            '/home': (context) =>
                BottomNav(isAdmin: UserRoleManager().isAdmin), // ✅ Role managed
          },
        );
      },
    );
  }
}

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }
}
