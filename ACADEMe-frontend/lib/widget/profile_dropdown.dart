import 'package:flutter/material.dart';

import '../academe_theme.dart';

import 'package:flutter/material.dart';

class ReusableProfileOption extends StatelessWidget {
  final IconData? icon;
  final String title;
  final Widget trailingWidget;
  final VoidCallback? onTap;

  const ReusableProfileOption({
    Key? key,
    this.icon,
    required this.title,
    required this.trailingWidget,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade400, // Border color
            width: 1, // Border width
          ),
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: ListTile(
          leading: icon != null ? Icon(icon, color: AcademeTheme.appColor,
              size: MediaQuery.of(context).size.width * 0.06) : null,
          title: Text(title, style: const TextStyle(fontSize: 18)),
          trailing: trailingWidget, // Custom widget passed here
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 19), // reduced vertical padding
          minVerticalPadding: 0, // reduces extra vertical padding
          visualDensity: const VisualDensity(vertical: -2),
        ),
      ),
    );
  }
}


class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool showTrailing;

  const ProfileOption({
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconColor,
    this.showTrailing = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade400, // Border color
            width: 1, // Border width
          ),
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: iconColor ?? AcademeTheme.appColor,
            size: MediaQuery.of(context).size.width * 0.06,
          ),
          title: Text(
            text,
            style:  TextStyle(fontSize: MediaQuery.of(context).size.width * 0.043),
          ),
          trailing: showTrailing
              ? GestureDetector(
            onTap: onTap,
            child: Icon(
              Icons.arrow_forward_ios,
              size: MediaQuery.of(context).size.width * 0.05,
              color: Colors.grey,
            ),
          )
              : null, // No trailing icon if false
          contentPadding: const EdgeInsets.symmetric(horizontal: 19), // reduced vertical padding
          minVerticalPadding: 0, // reduces extra vertical padding
          visualDensity: const VisualDensity(vertical: -2),        ),
      ),
    );
  }
}