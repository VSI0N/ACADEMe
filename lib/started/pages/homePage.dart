import 'package:ACADEMe/started/pages/signup_view.dart';
import 'package:flutter/material.dart';
import '../../academe_theme.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onAskMeTap;

  const HomePage({Key? key,
    required this.onProfileTap,
    required this.onAskMeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // Custom height for AppBar
        child: AppBar(
          backgroundColor: AcademeTheme.appColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: getAppBarUI(onProfileTap), // Custom AppBar UI
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 20),

              // Progress Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AcademeTheme.appColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side: Text + Score
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "This Week",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        // const SizedBox(height: 3),
                        const Text(
                          "Progress",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 37,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "420 🔥",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {},
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 26),

                    // Right Side: Bar Graphs
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              barGraph(30, 110), barGraph(50, 90),
                              barGraph(60, 80), barGraph(40, 100),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              Text("Mon", style: TextStyle(color: Colors.white)),
                              Text("Tue", style: TextStyle(color: Colors.white)),
                              Text("Wed", style: TextStyle(color: Colors.white)),
                              Text("Thu", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ASKMe Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: SizedBox(
                  height: 100.0,
                  width: double.infinity,
                  child: ListTile(
                    leading: Image.asset(
                      "assets/images/supportIcon.png",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover, // Adjust as needed
                    ),
                    title: const Text(
                      "ASKMe is ready to assist you!",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpView()),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Continue Learning",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  Text(
                    "See All",
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              learningCard(
                "Linear Algebra", 4, 9, 34, Colors.pink[100]!,
              ),
              const SizedBox(height: 12),
              learningCard(
                "Atoms & Molecules", 7, 13, 65, Colors.blue[100]!,
              ),

              const SizedBox(height: 12),
              learningCard(
                "Motion", 4, 11, 22, Colors.pink[100]!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget barGraph(double yellowHeight, double purpleHeight) {
    return Column(
      children: [
        Container(
          height: purpleHeight,
          width: 22,
          decoration: BoxDecoration(
            color: Colors.grey,
            // borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        Container(
          height: yellowHeight,
          width: 24,
          decoration: BoxDecoration(
            color: Colors.yellow,
            // borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
        ),
      ],
    );
  }

  // Learning Card Widget
  static Widget learningCard(
      String title, int completed, int total, int percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 15),
                Text("$completed/$total"),
                const SizedBox(height: 15),
                LinearProgressIndicator(
                  value: percentage / 100,
                  color: Colors.blue,
                  backgroundColor: Colors.grey[300],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text("$percentage%"),
        ],
      ),
    );
  }
}


Widget getAppBarUI(VoidCallback onProfileTap) {
  return Padding(
    padding: const EdgeInsets.only(top: 55.0, left: 18, right: 18),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              SizedBox(height: 18), // Adjust the space to lower the text
              Text(
                'Hello Alex',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              SizedBox(height:1),
              Text(
                'Sun, Feb 25',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onProfileTap, // Calls the callback function
          child: SizedBox(
            width: 60,
            height: 60,
            child: Image.asset('assets/design_course/userImage.png'),
          ),
        ),
      ],
    ),
  );
}