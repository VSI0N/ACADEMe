import 'package:ACADEMe/started/pages/animated_splash.dart';
import 'package:ACADEMe/home/pages/bottomNav.dart';
import 'package:ACADEMe/started/pages/course.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'home/auth/role.dart';
import 'home/auth/auth_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './home/auth/auth_service.dart';
import 'academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ACADEMe/providers/bottom_nav_provider.dart'; // Import BottomNavProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
    print("✅ .env Loaded Successfully");
  } catch (e) {
    print("❌ .env Load Error: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase Initialized Successfully");
  } catch (e) {
    print("❌ Firebase Initialization Error: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  String? userEmail = prefs.getString("user_email");

  if (userEmail != null) {
    await UserRoleManager().fetchUserRole(userEmail);
  }

  await UserRoleManager().loadRole();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => LanguageProvider()), // Language provider
          ChangeNotifierProvider(create: (context) => BottomNavProvider()), // BottomNav provider
        ],
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:
      !kIsWeb && Platform.isAndroid ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

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
          locale: languageProvider.locale, // Get locale from provider
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
          home: AnimatedSplashScreen(), // Start with splash screen
          routes: {
            '/home': (context) => BottomNav(isAdmin: UserRoleManager().isAdmin), // Now managed with provider
            '/courses': (context) => SelectCourseScreen(),
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
