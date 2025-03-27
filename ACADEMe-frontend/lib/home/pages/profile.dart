import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:ACADEMe/started/pages/login_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../widget/profile_class.dart';
import '../../widget/profile_dropdown.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Locale _selectedLocale;
  String? selectedClass; // Allow null initially
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLocale = const Locale('en');
    _loadLanguage();
    _loadUserDetailsFromStorage(); // Load user details when the page is initialized
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user details when the page is revisited
    _loadUserDetailsFromStorage();
  }

  Future<void> _loadUserDetailsFromStorage() async {
    try {
      final name = await _secureStorage.read(key: 'name');
      final email = await _secureStorage.read(key: 'email');
      final studentClass = await _secureStorage.read(key: 'student_class');
      final photoUrl = await _secureStorage.read(key: 'photo_url');

      if (mounted) {
        setState(() {
          userDetails = {
            'name': name,
            'email': email,
            'student_class': studentClass,
            'photo_url': photoUrl,
          };
          selectedClass = studentClass ?? 'SELECT'; // Use 'SELECT' as default
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user details from storage: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';

    final newLocale = Locale(langCode);

    Future.microtask(() {
      final languageProvider =
      Provider.of<LanguageProvider>(context, listen: false);
      if (languageProvider.locale != newLocale) {
        languageProvider.setLocale(newLocale);
      }
      setState(() {
        _selectedLocale = newLocale;
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

  Future<void> showLanguageSelectionSheet(BuildContext context,
      Locale currentLocale, Function(Locale) onSelected) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LanguageSelectionBottomSheet(
        selectedLocale: currentLocale,
        onLanguageSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            CircleAvatar(
              radius: 50,
              backgroundImage: userDetails?['photo_url'] != null &&
                  userDetails!['photo_url'].isNotEmpty
                  ? NetworkImage(
                  userDetails!['photo_url']) // Use the provided photo URL
                  : const AssetImage('assets/design_course/userImage.png')
              as ImageProvider, // Fallback to a local asset
            ),
            const SizedBox(height: 10),
            Text(
              userDetails?['name'] ?? 'Loading...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userDetails?['email'] ?? 'Loading...',
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
                padding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
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
            const SizedBox(height: 5),
            ListView(
              padding: const EdgeInsets.all(10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: ClassSelectionBottomSheet(
                            onClassSelected: () {
                              // Reload user details when the class is updated
                              _loadUserDetailsFromStorage();
                            },
                          ),
                        );
                      },
                    );
                  },
                  child: ReusableProfileOption(
                    icon: Icons.class_outlined,
                    title: L10n.getTranslatedText(context, 'Class'),
                    trailingWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedClass ?? 'SELECT',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showLanguageSelectionSheet(
                      context,
                      Provider.of<LanguageProvider>(context, listen: false)
                          .locale,
                          (Locale newLocale) {
                        _changeLanguage(newLocale);
                      },
                    );
                  },
                  child: ReusableProfileOption(
                    icon: Icons.translate,
                    title: L10n.getTranslatedText(context, 'language'),
                    trailingWidget: Icon(Icons.arrow_forward_ios,
                        size: 18, color: Colors.grey[500]),
                  ),
                ),
                ProfileOption(
                  icon: Icons.settings,
                  text: L10n.getTranslatedText(context, 'Settings'),
                  iconColor: AcademeTheme.appColor,
                  onTap: () {
                  },
                ),
                ProfileOption(
                  icon: Icons.credit_card,
                  text: L10n.getTranslatedText(context, 'Billing Details'),
                  iconColor: AcademeTheme.appColor,
                  onTap: () {
                  },
                ),
                ProfileOption(
                  icon: Icons.info,
                  text: L10n.getTranslatedText(context, 'Information'),
                  iconColor: AcademeTheme.appColor,
                  onTap: () {
                  },
                ),
                ProfileOption(
                  icon: Icons.card_giftcard,
                  text: L10n.getTranslatedText(context, 'Redeem Me Points'),
                  iconColor: AcademeTheme.appColor,
                  onTap: () {
                  },
                ),
                ProfileOption(
                  icon: Icons.logout,
                  text: L10n.getTranslatedText(context, 'Logout'),
                  iconColor: Colors.red,
                  onTap: () async {
                    try {
                      await AuthService().signOut();
                      print('✅ User signed out successfully');

                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LogInView()),
                              (route) => false,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              L10n.getTranslatedText(
                                  context, 'You have been logged out'),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      print('❌ Error during logout: $e');
                    }
                  },
                  showTrailing: false,
                ),
                const SizedBox(height: 20),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class LanguageSelectionBottomSheet extends StatefulWidget {
  final Locale selectedLocale;
  final Function(Locale) onLanguageSelected;

  const LanguageSelectionBottomSheet({
    Key? key,
    required this.selectedLocale,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  _LanguageSelectionBottomSheetState createState() =>
      _LanguageSelectionBottomSheetState();
}

class _LanguageSelectionBottomSheetState
    extends State<LanguageSelectionBottomSheet> {
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.selectedLocale;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Select Language",
            style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: height * 0.02),
          DropdownButtonFormField<Locale>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
              EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.01),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            value: _selectedLocale,
            items: L10n.supportedLocales.map((Locale locale) {
              return DropdownMenuItem(
                value: locale,
                child: Text(L10n.getLanguageName(locale.languageCode)),
              );
            }).toList(),
            onChanged: (Locale? locale) {
              setState(() {
                _selectedLocale = locale;
              });
            },
          ),
          SizedBox(height: height * 0.02),
          Padding(
            padding: EdgeInsets.symmetric( vertical: 12), // Outer padding
            child: SizedBox(
              width: double.infinity, // Full width
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  padding: const EdgeInsets.symmetric(vertical: 14), // Only vertical padding inside button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_selectedLocale != null) {
                    widget.onLanguageSelected(_selectedLocale!);
                    Navigator.pop(context); // Close sheet
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a language')),
                    );
                  }
                },
                child: Text(
                  "Confirm",
                  style: TextStyle(fontSize: width * 0.04, color: Colors.black),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}