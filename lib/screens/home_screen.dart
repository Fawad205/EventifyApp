import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../widgets/event_card.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color primaryPurple = const Color(0xFF6342E8);

  Widget _buildEventList(List<Event> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text('No events found in this category.', style: TextStyle(color: Colors.black54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return EventCard(event: events[index]);
      },
    );
  }

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
                  // Navigate to Profile or Auth
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
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong.'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primaryPurple));
            }

            final List<Event> events = snapshot.data!.docs
                .map((doc) => Event.fromFirestore(doc))
                .toList();

            return TabBarView(
              children: [
                // All Events Tab
                _buildEventList(events),
                // Nearby Tab (showing all for now)
                _buildEventList(events),
                // Tech Events Tab
                _buildEventList(events.where((e) => e.category == 'Tech Events').toList()),
                // Islamic Events Tab
                _buildEventList(events.where((e) => e.category == 'Islamic Events').toList()),
                // Expo Events Tab
                _buildEventList(events.where((e) => e.category == 'Expo Events').toList()),
              ],
            );
          },
        ),
      ),
    );
  }
}
