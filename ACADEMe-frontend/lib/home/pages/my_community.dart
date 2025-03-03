import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/home/components/ASKMe_button.dart';
import 'package:ACADEMe/home/pages/ASKMe.dart';

class Mycommunity extends StatelessWidget {
  const Mycommunity({super.key});

  @override
  Widget build(BuildContext context) {
    return ASKMeButton(
      showFAB: true, // Show floating action button
      onFABPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ASKMe()),
        );
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(100), // Reduced height
            child: AppBar(
              backgroundColor: AcademeTheme.appColor,
              automaticallyImplyLeading: false,
              elevation: 0,
              flexibleSpace: Padding(
                padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.groups, color: Colors.white, size: 40),
                          SizedBox(height: 8),
                          Text(
                            "My Communities",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Fixed Search Bar
              Container(
                color: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 5,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search Communities or topics",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Icon(Icons.filter_list, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              // Fixed TabBar
              Container(
                color: Colors.white,
                child: const TabBar(
                  indicatorColor: Colors.black,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black,
                  tabs: [
                    Tab(text: "Forums"),
                    Tab(text: "Groups"),
                    Tab(text: "Communities"),
                  ],
                ),
              ),

              // TabBarView scrolls while search bar & tab bar remain fixed
              Expanded(
                child: const TabBarView(
                  children: [
                    Center(child: Text("Forums Section")),
                    Center(child: Text("Groups Section")),
                    CommunityList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityList extends StatelessWidget {
  const CommunityList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> communities = [
      {
        "title": "Machine Learning",
        "icon": Icons.campaign,
        "color": Colors.red,
        "members": "1233"
      },
      {
        "title": "Computer Science",
        "icon": Icons.insert_drive_file,
        "color": Colors.blue,
        "members": "9890"
      },
      {
        "title": "Biotechnology",
        "icon": Icons.science,
        "color": Colors.green,
        "members": "665"
      },
      {
        "title": "Mathematics",
        "icon": Icons.functions,
        "color": Colors.indigo,
        "members": "99908"
      },
    ];

    return ListView.builder(
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: community["color"],
              child: Icon(community["icon"], color: Colors.white),
            ),
            title: Text(
              community["title"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("Begin your journey with us!"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups, color: Colors.grey),
                const SizedBox(width: 4),
                Text(community["members"]),
              ],
            ),
          ),
        );
      },
    );
  }
}