import 'package:flutter/material.dart';

class HomepageDrawer extends StatelessWidget {
  final VoidCallback onClose;

  const HomepageDrawer({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Close Button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: onClose,
            ),
          ),

          // User Profile Section
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/design_course/userImage.png'),
          ),
          const SizedBox(height: 10),
          const Text(
            "Atomic Shadow",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const Divider(thickness: 1),

          // Drawer Items
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
