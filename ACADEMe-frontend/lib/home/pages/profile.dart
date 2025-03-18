import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/introduction_page.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/localization/language_provider.dart';

import '../../started/pages/login_view.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Locale _selectedLocale;
  String selectedClass = 'Class 1';

  @override
  void initState() {
    super.initState();
    _selectedLocale = const Locale('en');
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';

    final newLocale = Locale(langCode);

    Future.microtask(() {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      if (languageProvider.locale != newLocale) {
        languageProvider.setLocale(newLocale);
      }
      setState(() {
        _selectedLocale = newLocale; // Ensure state is updated
      });
    });
  }

  void _changeLanguage(Locale locale) async {
    if (locale != _selectedLocale) {
      setState(() {
        _selectedLocale = locale;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', locale.languageCode);

      Provider.of<LanguageProvider>(context, listen: false).setLocale(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AcademeTheme.appColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            L10n.getTranslatedText(context, 'Profile'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/design_course/userImage.png'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Rahul Sharma',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'rahulSharma23@gmail.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                L10n.getTranslatedText(context, 'Edit Profile'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.class_outlined,
                        color: Colors.blue,
                        size: 30,
                      ),
                      title: const Text(
                        "Class", // Static label on the left
                        style: TextStyle(fontSize: 20),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedClass,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black), // Dropdown icon
                            onChanged: (value) {
                              if (value != selectedClass) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false, // Prevent dismissing by tapping outside
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text(
                                        'Are you sure you want to change your class?',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      content: const Text(
                                        'All your progress data will be erased for this class.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Dismiss dialog
                                          },
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(color: Colors.grey, fontSize: 16),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              selectedClass = value!;
                                            });
                                            Navigator.of(context).pop(); // Dismiss dialog
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            items: List.generate(12, (index) => DropdownMenuItem(
                              value: 'Class ${index + 1}',
                              child: Text('${index + 1}'), // Only index displayed
                            )),
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                    _ProfileOption(
                      icon: Icons.settings,
                      text: L10n.getTranslatedText(context, 'Settings'),
                      iconColor: Colors.blue,
                      onTap: () {
                        print('Settings tapped');
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.credit_card,
                      text: L10n.getTranslatedText(context, 'Billing Details'),
                      iconColor: Colors.blue,
                      onTap: () {
                        print('Billing Details tapped');
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.people,
                      text: L10n.getTranslatedText(context, 'User Management'),
                      iconColor: Colors.blue,
                      onTap: () {
                        print('User Management tapped');
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.info,
                      text: L10n.getTranslatedText(context, 'Information'),
                      iconColor: Colors.blue,
                      onTap: () {
                        print('Information tapped');
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.card_giftcard,
                      text: L10n.getTranslatedText(context, 'Redeem Points'),
                      iconColor: Colors.blue,
                      onTap: () {
                        print('Redeem points tapped');
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.logout,
                      text: L10n.getTranslatedText(context, 'Logout'),
                      iconColor: Colors.red,
                      onTap: () async {
                        try {
                          await AuthService().signOut();
                          print('✅ User signed out successfully');

                          // Ensure UI updates instantly
                          await Future.delayed(Duration.zero);

                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LogInView()),
                                  (route) => false,
                            );

                            // Show SnackBar AFTER navigation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  L10n.getTranslatedText(context, 'You have been logged out'),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('❌ Error during logout: $e');
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        L10n.getTranslatedText(context, 'Select Language'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Consumer<LanguageProvider>(
                        builder: (context, provider, child) {
                          return DropdownButton<Locale>(
                            value: provider.locale,
                            hint: const Text("Choose Language"),
                            isExpanded: true,
                            onChanged: (Locale? newLocale) {
                              if (newLocale != null) {
                                _changeLanguage(newLocale); // Call the function
                              }
                            },
                            items: L10n.supportedLocales.map((Locale locale) {
                              return DropdownMenuItem(
                                value: locale,
                                child: Text(L10n.getLanguageName(locale.languageCode)),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? AcademeTheme.appColor,
          size: 30,
        ),
        title: Text(
          text,
          style: const TextStyle(fontSize: 20),
        ),
        trailing: GestureDetector(
          onTap: onTap,
          child: const Icon(
            Icons.arrow_forward_ios,
            size: 20,
            color: Colors.grey,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}