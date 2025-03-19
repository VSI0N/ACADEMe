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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Locale _selectedLocale;
  String selectedClass = 'Class 1';
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLocale = const Locale('en');
    _loadLanguage();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');

      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
      final response = await http.get(
        Uri.parse('$backendUrl/api/users/me'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            userDetails = data;
            selectedClass = 'Class ${data['student_class']}';
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user details: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch user details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateClass(String newClass) async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');

      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
      final response = await http.patch(
        Uri.parse('$backendUrl/api/users/update_class/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'new_class': newClass}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            selectedClass = 'Class ${data['new_class']}';
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update class: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating class: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update class: $e'),
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
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
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
              backgroundImage: userDetails?['photo_url'] != null && userDetails!['photo_url'].isNotEmpty
                  ? NetworkImage(userDetails!['photo_url']) // Use the provided photo URL
                  : const AssetImage('assets/design_course/userImage.png') as ImageProvider, // Fallback to a local asset
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
                        "Class",
                        style: TextStyle(fontSize: 20),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedClass,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            onChanged: (value) {
                              if (value != selectedClass) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
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
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(color: Colors.grey, fontSize: 16),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (value != null) {
                                              setState(() {
                                                selectedClass = value!;
                                              });
                                              _updateClass(value!.replaceAll('Class ', ''));
                                              Navigator.of(context).pop();
                                            }
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
                              child: Text('${index + 1}'),
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

                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LogInView()),
                                  (route) => false,
                            );

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
                                _changeLanguage(newLocale);
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