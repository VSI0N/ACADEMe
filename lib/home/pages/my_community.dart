import 'package:flutter/material.dart';
import '../../academe_theme.dart';

class Mycommunity extends StatelessWidget {
  const Mycommunity({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(190),
          child: AppBar(
            backgroundColor: AcademeTheme.appColor,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search Communities or topics",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Icon(Icons.filter_list, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50), // Adjust height
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10), // Moves the tabs lower
                child: const TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: "Forums"),
                    Tab(text: "Groups"),
                    Tab(text: "Communities"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text("Forums Section")),
            Center(child: Text("Groups Section")),
            CommunityList(),
          ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
