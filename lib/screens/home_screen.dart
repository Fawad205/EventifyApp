import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color primaryPurple = const Color(0xFF6342E8);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
            
            },
          ),
          title: const Text(
            'Eventify',
            style: TextStyle(
              color: Color(0xFF6342E8),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  // TODO: Navigate to Profile or Auth
                },
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFF3F0FF),
                  child: Icon(Icons.person, color: Color(0xFF6342E8)),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: primaryPurple,
            ),
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            labelPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            tabs: const [
              Text('All Events', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Nearby', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Tech Events', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Islamic Events', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Expo Events', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // All Events Tab
            Center(child: Text('All Events Content', style: TextStyle(fontSize: 18))),
            // Nearby Tab
            Center(child: Text('Nearby Events Content', style: TextStyle(fontSize: 18))),
            // Tech Events Tab
            Center(child: Text('Tech Events Content', style: TextStyle(fontSize: 18))),
            // Islamic Events Tab
            Center(child: Text('Islamic Events Content', style: TextStyle(fontSize: 18))),
            // Expo Events Tab
            Center(child: Text('Expo Events Content', style: TextStyle(fontSize: 18))),
          ],
        ),
      ),
    );
  }
}
