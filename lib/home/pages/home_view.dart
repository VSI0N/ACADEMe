import 'package:flutter/material.dart';
import 'package:ACADEMe/home/pages/ASKMe.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/home/components/ASKMe_button.dart';
import '../courses/linear_algebra/Linear_algebra.dar.dart';
import 'course.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onAskMeTap;

  const HomePage({
    Key? key,
    required this.onProfileTap,
    required this.onAskMeTap,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showSearchUI = false;

  @override
  Widget build(BuildContext context) {
    return ASKMeButton(
      showFAB: true,
      onFABPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ASKMe()),
        );
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: AppBar(
            backgroundColor: AcademeTheme.appColor,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: getAppBarUI(widget.onProfileTap),
          ),
        ),
        backgroundColor: Colors.white,
        body: _showSearchUI ? _buildSearchUI() : _buildMainUI(),
      ),
    );
  }

  Widget _buildSearchUI() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSearchUI = false;
        });
      },
      behavior: HitTestBehavior.opaque, // Ensures taps outside are detected
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView( // Ensures content scrolls
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Popular Searches",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        ActionChip(
                          label: Text("Machine Learning"),
                          onPressed: () {
                            print("Machine Learning clicked");
                    // Handle chip click action here
                          },
                        ),
                        ActionChip(
                          label: Text("Data Science"),
                          onPressed: () {
                            print("Data Science clicked");
                        // Handle chip click action here
                          },
                        ),
                        ActionChip(
                          label: Text("Flutter"),
                          onPressed: () {
                            print("Flutter clicked");
                        // Handle chip click action here
                          },
                        ),
                        ActionChip(
                          label: Text("Linear Algebra"),
                          onPressed: () {
                            print("Linear Algebra clicked");
                        // Handle chip click action here
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Recent Searches",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.history),
                      title: Text("Advanced Python"),
                      onTap: () {}, // Keep these as they are
                    ),
                    ListTile(
                      leading: Icon(Icons.history),
                      title: Text("Cyber Security"),
                      onTap: () {},
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



  Widget _buildMainUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            readOnly: true,
            onTap: () => setState(() => _showSearchUI = true),
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
          _buildProgressSection(),
          const SizedBox(height: 20),
          _buildASKMeCard(),
          const SizedBox(height: 20),
          _buildContinueLearningSection(),
        ],
      ),
    );
  }


  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AcademeTheme.appColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "This Week",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const Text(
                "Progress",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
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
                        fontSize: 16,
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
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    barGraph(30, 110),
                    barGraph(50, 90),
                    barGraph(60, 80),
                    barGraph(40, 100),
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
    );
  }

  Widget _buildASKMeCard() {
    return Card(
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: SizedBox(
        height: 100.0,
        width: double.infinity,
        child: ListTile(
          leading: Image.asset(
            "assets/icons/ASKMe_dark.png",
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: const Text(
            "ASKMe is ready to assist you!",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 21),
          ),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ASKMe()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContinueLearningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Continue Learning", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text("See All", style: TextStyle(color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
        learningCard(
            "Linear Algebra", 4, 9, 34, Colors.pink[100]!, (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LinearAlgebraScreen()),
          );
        }
        ),
        const SizedBox(height: 12),
        learningCard(
            "Atoms & Molecules", 7, 13, 65, Colors.blue[100]!, (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LinearAlgebraScreen()),
          );
        }
        ),
        const SizedBox(height: 12),
        learningCard(
            "Atoms & Molecules", 7, 13, 65, Colors.green[100]!, (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LinearAlgebraScreen()),
          );
        }
        ),
      ],
    );
  }

  Widget barGraph(double yellowHeight, double purpleHeight) {
    return Column(
      children: [
        Container(
          height: purpleHeight,
          width: 22,
          decoration: BoxDecoration(
            color: Colors.grey,
          ),
        ),
        Container(
          height: yellowHeight,
          width: 24,
          decoration: BoxDecoration(
            color: Colors.yellow,
          ),
        ),
      ],
    );
  }

  Widget learningCard(
      String title, int completed, int total, int percentage, Color color, VoidCallback onTap) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
                  onPressed: onTap
              ),
              const SizedBox(height: 16),
              Text("$percentage%"),
            ],
          )
        ],
      ),
    );
  }
}

Widget getAppBarUI(VoidCallback onProfileTap) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(top: 18.0, left: 18, right: 18, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                SizedBox(height: 10), // Reduce height to avoid overflow
                Text(
                  'Hello Alex',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Sun, Feb 25',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: SizedBox(
              width: 50,
              height: 50, // Reduce height to avoid overflow
              child: Image.asset('assets/design_course/userImage.png'),
            ),
          ),
        ],
      ),
    ),
  );
}
