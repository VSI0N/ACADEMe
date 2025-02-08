import 'package:flutter/material.dart';

import '../../academe_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AcademeTheme.appColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 70,
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
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 400,
            child: Padding(
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
                  children: [
                    _ProfileOption(
                      icon: Icons.settings,
                      text: 'Settings',
                      onTap: () {
                        print('Settings tapped');
                        // Navigate to Settings page
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.credit_card,
                      text: 'Billing Details',
                      onTap: () {
                        print('Billing Details tapped');
                        // Navigate to Billing Details page
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.people,
                      text: 'User Management',
                      onTap: () {
                        print('User Management tapped');
                        // Navigate to User Management page
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.info,
                      text: 'Information',
                      onTap: () {
                        print('Information tapped');
                        // Navigate to Information page
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.logout,
                      text: 'Logout',
                      iconColor: Colors.red,
                      onTap: () {
                        print('Logout tapped');
                        // Handle logout logic
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.logout,
                      text: 'Logout',
                      iconColor: Colors.red,
                      onTap: () {
                        print('Logout tapped');
                        // Handle logout logic
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      onTap: onTap, // Makes the entire row clickable
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? AcademeTheme.appColor,
          size: 30,
        ),
        title: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
        trailing: GestureDetector(
          onTap: onTap, // Makes only the arrow icon clickable
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
