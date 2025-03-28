import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/home/components/askme_button.dart';
import 'package:ACADEMe/home/pages/ask_me.dart';
import 'package:ACADEMe/localization/l10n.dart';

class Mycommunity extends StatelessWidget {
  const Mycommunity({super.key});

  @override
  Widget build(BuildContext context) {
    return ASKMeButton(
      showFAB: true, // Show floating action button
      onFABPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AskMe()),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.groups, color: Colors.white, size: 40),
                          SizedBox(height: 8),
                          Text(
                            L10n.getTranslatedText(context, 'My Communities'),
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
                        color: Colors.grey.withAlpha(20),
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
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: L10n.getTranslatedText(context, 'Search Communities or topics'),
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
                child: TabBar(
                  indicatorColor: Colors.black,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black,
                  tabs: [
                    Tab(text: L10n.getTranslatedText(context, 'Forums')),
                    Tab(text: L10n.getTranslatedText(context, 'Groups')),
                    Tab(text: L10n.getTranslatedText(context, 'Communities')),
                  ],
                ),
              ),

              // TabBarView scrolls while search bar & tab bar remain fixed
              Expanded(
                child: TabBarView(
                  children: [
                    Center(child: Text(L10n.getTranslatedText(context, 'Forums Section'))),
                    Center(child: Text(L10n.getTranslatedText(context, 'Groups Section'))),
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
              L10n.getTranslatedText(context, community["title"]),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(L10n.getTranslatedText(context, 'Begin your journey with us!')),
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